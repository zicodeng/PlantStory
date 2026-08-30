import ImageIO
import SwiftUI
import UIKit

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

struct PlantPhoto: View {
    let data: Data?
    var cornerRadius: CGFloat = 24

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
