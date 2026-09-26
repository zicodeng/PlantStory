import Foundation
import CryptoKit
import Security

struct GitHubBackupRepository: Equatable {
    let owner: String
    let name: String

    var displayName: String {
        "\(owner)/\(name)"
    }
}

struct GitHubBackupRepositoryInfo: Decodable {
    let isPrivate: Bool
    let defaultBranch: String

    private enum CodingKeys: String, CodingKey {
        case isPrivate = "private"
        case defaultBranch = "default_branch"
    }
}

struct GitHubBackupSnapshot {
    let createdAt: Date
    let plants: [Plant]
    let wildFinds: [WildFind]
}

struct GitHubBackupService {
    static let backupPath = "plantstory/backup.json"
    static let maximumBackupSize = 50 * 1_024 * 1_024

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func verify(
        repository: GitHubBackupRepository,
        token: String
    ) async throws -> GitHubBackupRepositoryInfo {
        let repository = try validated(repository)
        let token = try validated(token)
        let request = try request(
            url: repositoryURL(repository),
            token: token
        )
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data, notFound: .repositoryNotFound)
        let info = try JSONDecoder().decode(GitHubBackupRepositoryInfo.self, from: data)
        guard info.isPrivate else {
            throw GitHubBackupError.repositoryMustBePrivate
        }
        return info
    }

    func upload(
        plants: [Plant],
        wildFinds: [WildFind],
        to repository: GitHubBackupRepository,
        token: String
    ) async throws {
        let package = try GitHubBackupPackage(plants: plants, wildFinds: wildFinds)
        guard package.totalSize <= Self.maximumBackupSize else {
            throw GitHubBackupError.backupTooLarge
        }

        let repository = try validated(repository)
        let token = try validated(token)
        let info = try await verify(repository: repository, token: token)
        let reference = try await branchReference(
            repository: repository,
            branch: info.defaultBranch,
            token: token
        )
        let parentCommit = try await commit(
            repository: repository,
            sha: reference.object.sha,
            token: token
        )
        let existingTree = try await tree(
            repository: repository,
            sha: parentCommit.tree.sha,
            token: token
        )
        guard !existingTree.truncated else {
            throw GitHubBackupError.invalidResponse
        }
        let existingFiles: [String: String] = Dictionary(
            uniqueKeysWithValues: existingTree.tree.compactMap { entry in
                guard entry.type == "blob", let sha = entry.sha else { return nil }
                return (entry.path, sha)
            }
        )

        let manifestBlob = try await createBlob(
            package.manifestData,
            repository: repository,
            token: token
        )
        var treeEntries = [
            GitHubTreeEntry(
                path: Self.backupPath,
                mode: "100644",
                type: "blob",
                sha: manifestBlob.sha
            )
        ]

        for photo in package.photos.sorted(by: { $0.path < $1.path }) {
            let sha: String
            if let existingSHA = existingFiles[photo.path],
               existingSHA == photo.gitBlobSHA {
                sha = existingSHA
            } else {
                sha = try await createBlob(
                    photo.data,
                    repository: repository,
                    token: token
                ).sha
            }
            treeEntries.append(
                GitHubTreeEntry(
                    path: photo.path,
                    mode: "100644",
                    type: "blob",
                    sha: sha
                )
            )
        }

        let currentPhotoPaths = Set(package.photos.map(\.path))
        let obsoletePhotoPaths = existingFiles.keys.filter {
            $0.hasPrefix(GitHubBackupPackage.photoDirectory + "/")
                && !currentPhotoPaths.contains($0)
        }
        treeEntries.append(
            contentsOf: obsoletePhotoPaths.sorted().map {
                GitHubTreeEntry(path: $0, mode: "100644", type: "blob", sha: nil)
            }
        )

        let newTree = try await createTree(
            repository: repository,
            baseTreeSHA: parentCommit.tree.sha,
            entries: treeEntries,
            token: token
        )
        let newCommit = try await createCommit(
            repository: repository,
            treeSHA: newTree.sha,
            parentSHA: parentCommit.sha,
            token: token
        )
        try await updateBranchReference(
            repository: repository,
            branch: info.defaultBranch,
            commitSHA: newCommit.sha,
            token: token
        )
    }

    func download(
        from repository: GitHubBackupRepository,
        token: String
    ) async throws -> GitHubBackupSnapshot {
        let info = try await verify(repository: repository, token: token)
        let repository = try validated(repository)
        let token = try validated(token)
        let manifestData = try await downloadFile(
            path: Self.backupPath,
            repository: repository,
            branch: info.defaultBranch,
            token: token,
            notFound: .backupNotFound
        )
        guard manifestData.count <= Self.maximumBackupSize else {
            throw GitHubBackupError.backupTooLarge
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let version = try decoder.decode(GitHubBackupVersion.self, from: manifestData)
        switch version.formatVersion {
        case 1:
            let legacy = try decoder.decode(LegacyGitHubBackupArchive.self, from: manifestData)
            return GitHubBackupSnapshot(
                createdAt: legacy.createdAt,
                plants: legacy.plants,
                wildFinds: legacy.wildFinds
            )
        case GitHubBackupManifest.currentFormatVersion:
            let manifest = try decoder.decode(GitHubBackupManifest.self, from: manifestData)
            return try await restore(
                manifest,
                manifestSize: manifestData.count,
                repository: repository,
                branch: info.defaultBranch,
                token: token
            )
        default:
            throw GitHubBackupError.unsupportedBackupVersion(version.formatVersion)
        }
    }

    private func branchReference(
        repository: GitHubBackupRepository,
        branch: String,
        token: String
    ) async throws -> GitHubReference {
        let url = try apiURL(
            components: ["repos", repository.owner, repository.name, "git", "ref", "heads", branch]
        )
        let request = try request(url: url, token: token)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data, notFound: .repositoryConflict)
        return try JSONDecoder().decode(GitHubReference.self, from: data)
    }

    private func commit(
        repository: GitHubBackupRepository,
        sha: String,
        token: String
    ) async throws -> GitHubCommit {
        let url = try apiURL(
            components: ["repos", repository.owner, repository.name, "git", "commits", sha]
        )
        let request = try request(url: url, token: token)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(GitHubCommit.self, from: data)
    }

    private func tree(
        repository: GitHubBackupRepository,
        sha: String,
        token: String
    ) async throws -> GitHubTreeResponse {
        let baseURL = try apiURL(
            components: ["repos", repository.owner, repository.name, "git", "trees", sha]
        )
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "recursive", value: "1")]
        guard let url = components?.url else {
            throw GitHubBackupError.invalidResponse
        }
        let request = try request(url: url, token: token)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(GitHubTreeResponse.self, from: data)
    }

    private func createBlob(
        _ backup: Data,
        repository: GitHubBackupRepository,
        token: String
    ) async throws -> GitHubSHAResponse {
        let body = GitHubBlobRequest(
            content: backup.base64EncodedString(),
            encoding: "base64"
        )
        let url = try apiURL(
            components: ["repos", repository.owner, repository.name, "git", "blobs"]
        )
        let request = try jsonRequest(url: url, token: token, method: "POST", body: body)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data, acceptedStatusCodes: [201])
        return try JSONDecoder().decode(GitHubSHAResponse.self, from: data)
    }

    private func createTree(
        repository: GitHubBackupRepository,
        baseTreeSHA: String,
        entries: [GitHubTreeEntry],
        token: String
    ) async throws -> GitHubSHAResponse {
        let body = GitHubTreeRequest(
            baseTree: baseTreeSHA,
            tree: entries
        )
        let url = try apiURL(
            components: ["repos", repository.owner, repository.name, "git", "trees"]
        )
        let request = try jsonRequest(url: url, token: token, method: "POST", body: body)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data, acceptedStatusCodes: [201])
        return try JSONDecoder().decode(GitHubSHAResponse.self, from: data)
    }

    private func createCommit(
        repository: GitHubBackupRepository,
        treeSHA: String,
        parentSHA: String,
        token: String
    ) async throws -> GitHubSHAResponse {
        let body = GitHubCommitRequest(
            message: "Update PlantStory backup",
            tree: treeSHA,
            parents: [parentSHA]
        )
        let url = try apiURL(
            components: ["repos", repository.owner, repository.name, "git", "commits"]
        )
        let request = try jsonRequest(url: url, token: token, method: "POST", body: body)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data, acceptedStatusCodes: [201])
        return try JSONDecoder().decode(GitHubSHAResponse.self, from: data)
    }

    private func updateBranchReference(
        repository: GitHubBackupRepository,
        branch: String,
        commitSHA: String,
        token: String
    ) async throws {
        let body = GitHubReferenceUpdateRequest(sha: commitSHA, force: false)
        let url = try apiURL(
            components: ["repos", repository.owner, repository.name, "git", "refs", "heads", branch]
        )
        let request = try jsonRequest(url: url, token: token, method: "PATCH", body: body)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
    }

    private func downloadFile(
        path: String,
        repository: GitHubBackupRepository,
        branch: String,
        token: String,
        notFound: GitHubBackupError
    ) async throws -> Data {
        guard !path.isEmpty,
              !path.split(separator: "/").contains("..") else {
            throw GitHubBackupError.invalidResponse
        }
        let fileURL = try contentsURL(repository, path: path)
        var components = URLComponents(url: fileURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "ref", value: branch)]
        guard let url = components?.url else {
            throw GitHubBackupError.invalidResponse
        }

        var downloadRequest = try request(url: url, token: token)
        downloadRequest.setValue(
            "application/vnd.github.raw+json",
            forHTTPHeaderField: "Accept"
        )
        let (data, response) = try await session.data(for: downloadRequest)
        try validate(response: response, data: data, notFound: notFound)
        return data
    }

    private func restore(
        _ manifest: GitHubBackupManifest,
        manifestSize: Int,
        repository: GitHubBackupRepository,
        branch: String,
        token: String
    ) async throws -> GitHubBackupSnapshot {
        var restoredPlants: [Plant] = []
        var restoredWildFinds: [WildFind] = []
        var totalSize = manifestSize

        for record in manifest.plants {
            var plant = record.plant
            plant.photos = []
            for path in record.photoPaths {
                let photo = try await downloadPhoto(
                    path: path,
                    repository: repository,
                    branch: branch,
                    token: token
                )
                totalSize += photo.count
                guard totalSize <= Self.maximumBackupSize else {
                    throw GitHubBackupError.backupTooLarge
                }
                plant.photos.append(photo)
            }
            restoredPlants.append(plant)
        }

        for record in manifest.wildFinds {
            var wildFind = record.wildFind
            wildFind.photos = []
            for path in record.photoPaths {
                let photo = try await downloadPhoto(
                    path: path,
                    repository: repository,
                    branch: branch,
                    token: token
                )
                totalSize += photo.count
                guard totalSize <= Self.maximumBackupSize else {
                    throw GitHubBackupError.backupTooLarge
                }
                wildFind.photos.append(photo)
            }
            restoredWildFinds.append(wildFind)
        }

        return GitHubBackupSnapshot(
            createdAt: manifest.createdAt,
            plants: restoredPlants,
            wildFinds: restoredWildFinds
        )
    }

    private func downloadPhoto(
        path: String,
        repository: GitHubBackupRepository,
        branch: String,
        token: String
    ) async throws -> Data {
        guard path.hasPrefix(GitHubBackupPackage.photoDirectory + "/") else {
            throw GitHubBackupError.invalidBackupPhoto
        }
        let data = try await downloadFile(
            path: path,
            repository: repository,
            branch: branch,
            token: token,
            notFound: .invalidBackupPhoto
        )
        guard GitHubBackupPackage.photoPath(for: data) == path else {
            throw GitHubBackupError.invalidBackupPhoto
        }
        return data
    }

    private func validated(_ repository: GitHubBackupRepository) throws -> GitHubBackupRepository {
        let owner = repository.owner.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = repository.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._"))
        guard !owner.isEmpty,
              !name.isEmpty,
              owner.unicodeScalars.allSatisfy(allowed.contains),
              name.unicodeScalars.allSatisfy(allowed.contains) else {
            throw GitHubBackupError.invalidRepository
        }
        return GitHubBackupRepository(owner: owner, name: name)
    }

    private func validated(_ token: String) throws -> String {
        let token = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard token.count >= 20 else {
            throw GitHubBackupError.invalidToken
        }
        return token
    }

    private func repositoryURL(_ repository: GitHubBackupRepository) throws -> URL {
        try apiURL(components: ["repos", repository.owner, repository.name])
    }

    private func contentsURL(
        _ repository: GitHubBackupRepository,
        path: String
    ) throws -> URL {
        try apiURL(
            components: ["repos", repository.owner, repository.name, "contents"]
                + path.split(separator: "/").map(String.init)
        )
    }

    private func apiURL(components: [String]) throws -> URL {
        guard var url = URL(string: "https://api.github.com") else {
            throw GitHubBackupError.invalidResponse
        }
        for component in components {
            url.appendPathComponent(component)
        }
        return url
    }

    private func request(
        url: URL,
        token: String,
        method: String = "GET"
    ) throws -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 120)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("PlantStory", forHTTPHeaderField: "User-Agent")
        return request
    }

    private func jsonRequest<Body: Encodable>(
        url: URL,
        token: String,
        method: String,
        body: Body
    ) throws -> URLRequest {
        var request = try request(url: url, token: token, method: method)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func validate(
        response: URLResponse,
        data: Data,
        acceptedStatusCodes: Set<Int> = [200],
        notFound: GitHubBackupError = .repositoryNotFound
    ) throws {
        guard let response = response as? HTTPURLResponse else {
            throw GitHubBackupError.invalidResponse
        }
        guard acceptedStatusCodes.contains(response.statusCode) else {
            switch response.statusCode {
            case 401:
                throw GitHubBackupError.invalidToken
            case 403:
                throw GitHubBackupError.accessDenied
            case 404:
                throw notFound
            case 409:
                throw GitHubBackupError.repositoryConflict
            default:
                let message = (try? JSONDecoder().decode(GitHubAPIError.self, from: data))?.message
                throw GitHubBackupError.api(message)
            }
        }
    }
}

@MainActor
final class GitHubBackupTokenStore: ObservableObject {
    @Published private(set) var hasToken = false
    @Published private(set) var tokenPreview: String?

    private let keychain = GitHubBackupKeychain()

    init() {
        refreshStatus()
    }

    func token() throws -> String? {
        try keychain.read()
    }

    func save(_ rawValue: String) throws {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count >= 20 else {
            throw GitHubBackupError.invalidToken
        }
        try keychain.save(value)
        refreshStatus()
    }

    func delete() throws {
        try keychain.delete()
        refreshStatus()
    }

    private func refreshStatus() {
        let value = try? keychain.read()
        hasToken = !(value?.isEmpty ?? true)
        tokenPreview = value.map { "••••\($0.suffix(4))" }
    }
}

enum GitHubBackupError: LocalizedError {
    case invalidRepository
    case invalidToken
    case repositoryNotFound
    case repositoryMustBePrivate
    case accessDenied
    case backupNotFound
    case backupTooLarge
    case invalidBackupPhoto
    case unsupportedBackupVersion(Int)
    case repositoryConflict
    case invalidResponse
    case keychain(OSStatus)
    case api(String?)

    var errorDescription: String? {
        switch self {
        case .invalidRepository:
            AppLocalization.string("Enter a valid GitHub owner and repository name.")
        case .invalidToken:
            AppLocalization.string("Enter a valid fine-grained GitHub token.")
        case .repositoryNotFound:
            AppLocalization.string("PlantStory couldn’t find that repository. Check its owner, name, and token access.")
        case .repositoryMustBePrivate:
            AppLocalization.string("Choose a private GitHub repository for PlantStory backups.")
        case .accessDenied:
            AppLocalization.string("GitHub denied access. Give the token read and write access to repository contents.")
        case .backupNotFound:
            AppLocalization.string("No PlantStory backup was found in this repository.")
        case .backupTooLarge:
            AppLocalization.string("This backup is larger than PlantStory’s 50 MB GitHub limit. Use Export Backup instead.")
        case .invalidBackupPhoto:
            AppLocalization.string("A photo in the GitHub backup is missing or damaged.")
        case let .unsupportedBackupVersion(version):
            AppLocalization.string(
                "This backup uses unsupported format version %lld. Update PlantStory and try again.",
                Int64(version)
            )
        case .repositoryConflict:
            AppLocalization.string("GitHub couldn’t update the backup because the repository changed. Try again.")
        case .invalidResponse:
            AppLocalization.string("GitHub returned an unreadable response.")
        case .keychain:
            AppLocalization.string("PlantStory couldn’t securely update the GitHub token.")
        case let .api(message):
            message ?? AppLocalization.string("GitHub couldn’t complete the backup request.")
        }
    }
}

private struct GitHubBackupPackage {
    static let photoDirectory = "plantstory/photos"

    let manifestData: Data
    let photos: [GitHubBackupPhoto]

    var totalSize: Int {
        manifestData.count + photos.reduce(0) { $0 + $1.data.count }
    }

    init(plants: [Plant], wildFinds: [WildFind]) throws {
        var photoDataByPath: [String: Data] = [:]
        let plantRecords = plants.map { plant in
            let paths = plant.photos.map { photo in
                let path = Self.photoPath(for: photo)
                photoDataByPath[path] = photo
                return path
            }
            var plantWithoutPhotos = plant
            plantWithoutPhotos.photos = []
            return GitHubPlantRecord(plant: plantWithoutPhotos, photoPaths: paths)
        }
        let wildFindRecords = wildFinds.map { wildFind in
            let paths = wildFind.photos.map { photo in
                let path = Self.photoPath(for: photo)
                photoDataByPath[path] = photo
                return path
            }
            var wildFindWithoutPhotos = wildFind
            wildFindWithoutPhotos.photos = []
            return GitHubWildFindRecord(wildFind: wildFindWithoutPhotos, photoPaths: paths)
        }

        let manifest = GitHubBackupManifest(
            plants: plantRecords,
            wildFinds: wildFindRecords
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        manifestData = try encoder.encode(manifest)
        photos = photoDataByPath.map {
            GitHubBackupPhoto(path: $0.key, data: $0.value)
        }
    }

    static func photoPath(for data: Data) -> String {
        let digest = SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
        return "\(photoDirectory)/\(digest).\(fileExtension(for: data))"
    }

    private static func fileExtension(for data: Data) -> String {
        if data.starts(with: [0xFF, 0xD8, 0xFF]) { return "jpg" }
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "png" }
        if data.starts(with: [0x47, 0x49, 0x46, 0x38]) { return "gif" }
        if data.count >= 12,
           String(data: data[4..<12], encoding: .ascii)?.hasPrefix("ftyp") == true {
            return "heic"
        }
        if data.count >= 12,
           String(data: data[0..<4], encoding: .ascii) == "RIFF",
           String(data: data[8..<12], encoding: .ascii) == "WEBP" {
            return "webp"
        }
        return "bin"
    }
}

private struct GitHubBackupPhoto {
    let path: String
    let data: Data

    var gitBlobSHA: String {
        var object = Data("blob \(data.count)\0".utf8)
        object.append(data)
        return Insecure.SHA1.hash(data: object)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

private struct GitHubBackupManifest: Codable {
    static let currentFormatVersion = 2

    let formatVersion: Int
    let createdAt: Date
    let plants: [GitHubPlantRecord]
    let wildFinds: [GitHubWildFindRecord]

    init(
        createdAt: Date = .now,
        plants: [GitHubPlantRecord],
        wildFinds: [GitHubWildFindRecord]
    ) {
        formatVersion = Self.currentFormatVersion
        self.createdAt = createdAt
        self.plants = plants
        self.wildFinds = wildFinds
    }
}

private struct GitHubPlantRecord: Codable {
    let plant: Plant
    let photoPaths: [String]
}

private struct GitHubWildFindRecord: Codable {
    let wildFind: WildFind
    let photoPaths: [String]
}

private struct GitHubBackupVersion: Decodable {
    let formatVersion: Int
}

private struct LegacyGitHubBackupArchive: Decodable {
    let formatVersion: Int
    let createdAt: Date
    let plants: [Plant]
    let wildFinds: [WildFind]
}

private struct GitHubReference: Decodable {
    let object: GitHubSHAResponse
}

private struct GitHubCommit: Decodable {
    let sha: String
    let tree: GitHubSHAResponse
}

private struct GitHubSHAResponse: Decodable {
    let sha: String
}

private struct GitHubTreeResponse: Decodable {
    let tree: [GitHubTreeEntry]
    let truncated: Bool
}

private struct GitHubBlobRequest: Encodable {
    let content: String
    let encoding: String
}

private struct GitHubTreeRequest: Encodable {
    let baseTree: String
    let tree: [GitHubTreeEntry]

    private enum CodingKeys: String, CodingKey {
        case baseTree = "base_tree"
        case tree
    }
}

private struct GitHubTreeEntry: Codable {
    let path: String
    let mode: String
    let type: String
    let sha: String?
}

private struct GitHubCommitRequest: Encodable {
    let message: String
    let tree: String
    let parents: [String]
}

private struct GitHubReferenceUpdateRequest: Encodable {
    let sha: String
    let force: Bool
}

private struct GitHubAPIError: Decodable {
    let message: String
}

private struct GitHubBackupKeychain {
    private let service = "com.zicodeng.PlantStory.github-backup"
    private let account = "fine-grained-token"

    func read() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw GitHubBackupError.keychain(status)
        }
        return value
    }

    func save(_ value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw GitHubBackupError.invalidToken
        }

        SecItemDelete(baseQuery as CFDictionary)
        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw GitHubBackupError.keychain(status)
        }
    }

    func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw GitHubBackupError.keychain(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
