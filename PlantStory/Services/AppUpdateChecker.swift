import Combine
import Foundation

struct AppUpdate: Identifiable, Equatable {
    let version: String
    let appStoreURL: URL

    var id: String { version }
}

@MainActor
final class AppUpdateChecker: ObservableObject {
    @Published private(set) var availableUpdate: AppUpdate?
    @Published private(set) var latestAppStoreVersion: String?

    private let defaults: UserDefaults
    private let session: URLSession
    private var isChecking = false

    private static let appStoreLookupURL = URL(
        string: "https://itunes.apple.com/lookup?id=6807261183&country=us"
    )!
    private static let fallbackAppStoreURL = URL(
        string: "https://apps.apple.com/app/id6807261183"
    )!
    private static let successfulCheckInterval: TimeInterval = 24 * 60 * 60
    private static let failedCheckRetryInterval: TimeInterval = 60 * 60
    private static let remindLaterInterval: TimeInterval = 24 * 60 * 60

    private enum DefaultsKey {
        static let lastAttempt = "appUpdate.lastAttempt"
        static let lastSuccessfulCheck = "appUpdate.lastSuccessfulCheck"
        static let latestVersion = "appUpdate.latestVersion"
        static let deferredVersion = "appUpdate.deferredVersion"
        static let deferredUntil = "appUpdate.deferredUntil"
    }

    var availableAppStoreUpdateURL: URL? {
        guard let latestAppStoreVersion,
              let currentVersion = Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
              ) as? String,
              Self.isVersion(latestAppStoreVersion, newerThan: currentVersion) else {
            return nil
        }
        return availableUpdate?.appStoreURL ?? Self.fallbackAppStoreURL
    }

    init(
        defaults: UserDefaults = .standard,
        session: URLSession = .shared
    ) {
        self.defaults = defaults
        self.session = session
        let cachedVersion = defaults.string(forKey: DefaultsKey.latestVersion)
        latestAppStoreVersion = cachedVersion
        if let cachedVersion {
            availableUpdate = update(
                from: AppStoreLookupResult(
                    version: cachedVersion,
                    trackViewURL: nil
                ),
                now: .now
            )
        }
    }

    func checkIfNeeded(now: Date = .now) async {
        await check(now: now, respectingSchedule: true)
    }

    func refreshLatestVersion(now: Date = .now) async {
        await check(now: now, respectingSchedule: false)
    }

    private func check(now: Date, respectingSchedule: Bool) async {
        guard !isChecking,
              !respectingSchedule || shouldCheck(now: now) else { return }

        isChecking = true
        defaults.set(now, forKey: DefaultsKey.lastAttempt)
        defer { isChecking = false }

        do {
            let request = Self.appStoreLookupRequest(now: now)
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                return
            }

            let lookup = try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)
            defaults.set(now, forKey: DefaultsKey.lastSuccessfulCheck)
            let result = lookup.results.first
            if let version = result?.version {
                latestAppStoreVersion = version
                defaults.set(version, forKey: DefaultsKey.latestVersion)
            }
            availableUpdate = update(from: result, now: now)
        } catch {
            // Version checks should never interrupt or block the local-first app experience.
        }
    }

    private static func appStoreLookupRequest(now: Date) -> URLRequest {
        var components = URLComponents(
            url: appStoreLookupURL,
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = (components.queryItems ?? []) + [
            URLQueryItem(
                name: "_",
                value: String(Int(now.timeIntervalSince1970))
            )
        ]

        var request = URLRequest(
            url: components.url!,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 15
        )
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        return request
    }

    func remindLater(about update: AppUpdate, now: Date = .now) {
        defaults.set(update.version, forKey: DefaultsKey.deferredVersion)
        defaults.set(
            now.addingTimeInterval(Self.remindLaterInterval),
            forKey: DefaultsKey.deferredUntil
        )
        availableUpdate = nil
    }

    func openedAppStore(for update: AppUpdate) {
        guard availableUpdate == update else { return }
        availableUpdate = nil
    }

    private func shouldCheck(now: Date) -> Bool {
        if let lastSuccessfulCheck = defaults.object(
            forKey: DefaultsKey.lastSuccessfulCheck
        ) as? Date,
           now.timeIntervalSince(lastSuccessfulCheck) < Self.successfulCheckInterval {
            return false
        }

        if let lastAttempt = defaults.object(forKey: DefaultsKey.lastAttempt) as? Date,
           now.timeIntervalSince(lastAttempt) < Self.failedCheckRetryInterval {
            return false
        }

        return true
    }

    private func update(from result: AppStoreLookupResult?, now: Date) -> AppUpdate? {
        guard let result,
              let currentVersion = Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
              ) as? String,
              Self.isVersion(result.version, newerThan: currentVersion) else {
            clearDeferral()
            return nil
        }

        if defaults.string(forKey: DefaultsKey.deferredVersion) == result.version,
           let deferredUntil = defaults.object(forKey: DefaultsKey.deferredUntil) as? Date,
           now < deferredUntil {
            return nil
        }

        let appStoreURL = result.trackViewURL
            .flatMap(URL.init(string:))
            .flatMap { $0.scheme == "https" ? $0 : nil }
            ?? Self.fallbackAppStoreURL
        return AppUpdate(version: result.version, appStoreURL: appStoreURL)
    }

    private func clearDeferral() {
        defaults.removeObject(forKey: DefaultsKey.deferredVersion)
        defaults.removeObject(forKey: DefaultsKey.deferredUntil)
    }

    private static func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        let candidateParts = candidate.split(separator: ".").map { Int($0) ?? 0 }
        let currentParts = current.split(separator: ".").map { Int($0) ?? 0 }
        let componentCount = max(candidateParts.count, currentParts.count)

        for index in 0..<componentCount {
            let candidatePart = index < candidateParts.count ? candidateParts[index] : 0
            let currentPart = index < currentParts.count ? currentParts[index] : 0
            if candidatePart != currentPart {
                return candidatePart > currentPart
            }
        }

        return false
    }
}

private struct AppStoreLookupResponse: Decodable {
    let results: [AppStoreLookupResult]
}

private struct AppStoreLookupResult: Decodable {
    let version: String
    let trackViewURL: String?

    private enum CodingKeys: String, CodingKey {
        case version
        case trackViewURL = "trackViewUrl"
    }
}
