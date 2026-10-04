import ImageIO
import SwiftUI
import UIKit

struct PlantPhotoAsset: Codable, Equatable {
    let filename: String?
    let embeddedData: Data?

    init(filename: String) {
        self.filename = filename
        embeddedData = nil
    }

    init(data: Data) {
        filename = nil
        embeddedData = data
    }

    var identifier: String {
        if let filename { return filename }
        return "embedded-\(embeddedData?.hashValue ?? 0)"
    }

    func loadData() -> Data? {
        embeddedData ?? filename.flatMap(PhotoFileStore.data)
    }

    private enum CodingKeys: String, CodingKey {
        case filename
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let filename = try container.decodeIfPresent(String.self, forKey: .filename) {
            self.init(filename: filename)
            return
        }

        let container = try decoder.singleValueContainer()
        self.init(data: try container.decode(Data.self))
    }

    func encode(to encoder: Encoder) throws {
        if let filename {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(filename, forKey: .filename)
        } else {
            var container = encoder.singleValueContainer()
            try container.encode(embeddedData ?? Data())
        }
    }
}

enum PhotoFileStore {
    private static let directoryName = "Photos"

    static func materialize(_ photos: [PlantPhotoAsset]) -> [PlantPhotoAsset] {
        var result: [PlantPhotoAsset] = []
        result.reserveCapacity(photos.count)

        for photo in photos {
            if let filename = photo.filename, fileExists(filename) {
                result.append(photo)
                continue
            }

            guard let data = photo.embeddedData else {
                result.append(photo)
                continue
            }

            do {
                let filename = "\(UUID().uuidString).jpg"
                result.append(try store(data, as: filename))
            } catch {
                result.append(photo)
            }
        }

        return result
    }

    static func data(_ filename: String) -> Data? {
        guard let url = try? url(for: filename) else { return nil }
        return try? Data(contentsOf: url, options: [.mappedIfSafe])
    }

    static func dataAsync(_ filename: String) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            data(filename)
        }.value
    }

    static func resizedJPEG(
        from data: Data,
        maxPixelSize: Int,
        compressionQuality: CGFloat
    ) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            resizedJPEGSync(
                from: data,
                maxPixelSize: maxPixelSize,
                compressionQuality: compressionQuality
            )
        }.value
    }

    static func displayData(for photo: PlantPhotoAsset) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            guard let data = photo.loadData() else { return nil }
            return resizedJPEGSync(
                from: data,
                maxPixelSize: 1_000,
                compressionQuality: 0.8
            )
        }.value
    }

    static func delete(_ filenames: some Sequence<String>) {
        for filename in filenames {
            guard let url = try? url(for: filename) else { continue }
            try? FileManager.default.removeItem(at: url)
        }
    }

    static func store(_ data: Data, as filename: String) throws -> PlantPhotoAsset {
        let destination = try url(for: filename)
        try data.write(to: destination, options: .atomic)
        let values = try destination.resourceValues(forKeys: [.fileSizeKey])
        guard values.fileSize == data.count else {
            try? FileManager.default.removeItem(at: destination)
            throw CocoaError(.fileWriteUnknown)
        }
        return PlantPhotoAsset(filename: filename)
    }

    static func storedFileMatches(
        filename: String,
        expectedByteCount: Int
    ) -> Bool {
        guard let url = try? url(for: filename),
              let values = try? url.resourceValues(forKeys: [.fileSizeKey]) else {
            return false
        }
        return values.fileSize == expectedByteCount
    }

    static func availableCapacity() -> Int64? {
        guard let directory = try? directoryURL(),
              let values = try? directory.resourceValues(
            forKeys: [.volumeAvailableCapacityForImportantUsageKey]
        ) else { return nil }
        return values.volumeAvailableCapacityForImportantUsage
    }

    static func migrationJournalData() -> Data? {
        try? Data(contentsOf: migrationJournalURL(), options: [.mappedIfSafe])
    }

    static func writeMigrationJournal(_ data: Data) throws {
        try data.write(to: migrationJournalURL(), options: .atomic)
    }

    static func removeMigrationJournal() {
        guard let url = try? migrationJournalURL() else { return }
        try? FileManager.default.removeItem(at: url)
    }

    static func deleteUnreferencedFiles(keeping filenames: Set<String>) {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directoryURL(),
            includingPropertiesForKeys: nil
        ) else { return }
        for url in urls where !filenames.contains(url.lastPathComponent) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func fileExists(_ filename: String) -> Bool {
        guard let url = try? url(for: filename) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    private static func resizedJPEGSync(
        from data: Data,
        maxPixelSize: Int,
        compressionQuality: CGFloat
    ) -> Data? {
        guard let source = CGImageSourceCreateWithData(
            data as CFData,
            [kCGImageSourceShouldCache: false] as CFDictionary
        ) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else { return nil }
        return UIImage(cgImage: image).jpegData(compressionQuality: compressionQuality)
    }

    private static func migrationJournalURL() throws -> URL {
        try directoryURL()
            .deletingLastPathComponent()
            .appendingPathComponent("photo-migration.json", isDirectory: false)
    }

    private static func directoryURL() throws -> URL {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let directory = applicationSupport
            .appendingPathComponent("PlantStory", isDirectory: true)
            .appendingPathComponent(directoryName, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    private static func url(for filename: String) throws -> URL {
        guard !filename.isEmpty,
              filename == URL(fileURLWithPath: filename).lastPathComponent else {
            throw CocoaError(.fileReadInvalidFileName)
        }
        return try directoryURL().appendingPathComponent(filename, isDirectory: false)
    }
}

enum PhotoMetadata {
    static func creationDate(from data: Data) -> Date? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }

        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            let value = exif[kCGImagePropertyExifDateTimeOriginal]
                ?? exif[kCGImagePropertyExifDateTimeDigitized]
            let offset = exif[kCGImagePropertyExifOffsetTimeOriginal] as? String
                ?? exif[kCGImagePropertyExifOffsetTimeDigitized] as? String
            if let date = parse(value, offset: offset) {
                return date
            }
        }

        if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
           let date = parse(tiff[kCGImagePropertyTIFFDateTime]) {
            return date
        }

        if let png = properties[kCGImagePropertyPNGDictionary] as? [CFString: Any],
           let date = parse(png[kCGImagePropertyPNGCreationTime]) {
            return date
        }

        return nil
    }

    private static func parse(_ value: Any?, offset: String? = nil) -> Date? {
        if let date = value as? Date {
            return date
        }
        guard let value = value as? String else { return nil }

        if let offset {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ssXXXXX"
            if let date = formatter.date(from: value + offset) {
                return date
            }
        }

        let exifFormatter = DateFormatter()
        exifFormatter.calendar = Calendar(identifier: .gregorian)
        exifFormatter.locale = Locale(identifier: "en_US_POSIX")
        exifFormatter.timeZone = .current
        exifFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        if let date = exifFormatter.date(from: value) {
            return date
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: value) {
            return date
        }
        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: value)
    }
}

struct CameraPhotoPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onCapture: (Data) -> Void

    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraPhotoPicker

        init(parent: CameraPhotoPicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            defer { parent.isPresented = false }
            guard let image = info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 1) else { return }
            parent.onCapture(data)
        }
    }
}

struct PlantPhoto: View {
    let photo: PlantPhotoAsset?
    var cornerRadius: CGFloat = 24
    @State private var storedData: Data?

    private var data: Data? {
        photo?.embeddedData ?? storedData
    }

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color("MintPop"), Color("Sunshine").opacity(0.8), Color("Blossom").opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color("LeafGreen"))
                    Image(systemName: "sparkles")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .offset(x: 34, y: -30)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task(id: photo?.identifier) {
            guard let photo else {
                storedData = nil
                return
            }
            storedData = await PhotoFileStore.displayData(for: photo)
        }
    }
}

struct PhotoViewerItem: Identifiable {
    let id = UUID()
    let photo: PlantPhotoAsset
}

struct FullScreenPhotoView: View {
    @Environment(\.dismiss) private var dismiss

    let photo: PhotoViewerItem
    @State private var data: Data?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Full-screen photo")
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.62), in: Circle())
            }
            .accessibilityLabel("Close photo")
            .padding(18)
        }
        .statusBarHidden()
        .task(id: photo.photo.identifier) {
            if let embeddedData = photo.photo.embeddedData {
                data = embeddedData
            } else if let filename = photo.photo.filename {
                data = await PhotoFileStore.dataAsync(filename)
            }
        }
    }
}

struct CuteBackground: View {
    var body: some View {
        ZStack {
            Color("Canvas")
            Circle()
                .fill(Color("Blossom").opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 12)
                .offset(x: 150, y: -290)
            Circle()
                .fill(Color("LavenderPop").opacity(0.14))
                .frame(width: 240, height: 240)
                .blur(radius: 16)
                .offset(x: -170, y: 310)
        }
        .ignoresSafeArea()
    }
}
