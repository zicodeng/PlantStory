import UIKit
import WidgetKit

enum WidgetWateringSnapshotWriter {
    private static let maximumStoredItems = 24
    private static let thumbnailSize = CGSize(width: 96, height: 96)

    @MainActor
    static func update(plants: [Plant]) {
        let season = WateringSeason.active
        let items = plants.compactMap { plant -> (Plant, Date)? in
            guard let dueDate = plant.nextWateringReminderDate(season: season) else { return nil }
            return (plant, dueDate)
        }
        .sorted { left, right in
            if left.1 != right.1 { return left.1 < right.1 }
            return left.0.name.localizedStandardCompare(right.0.name) == .orderedAscending
        }
        .prefix(maximumStoredItems)
        .map { plant, dueDate in
            WidgetWateringItem(
                id: plant.id,
                name: plant.name,
                dueDate: dueDate,
                thumbnailData: thumbnail(from: plant.photos.last)
            )
        }

        let snapshot = WidgetWateringSnapshot(
            updatedAt: .now,
            languageCode: AppLocalization.currentLanguage.rawValue,
            items: Array(items)
        )
        WidgetWateringSnapshotStore.save(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetWateringSnapshotStore.widgetKind)
    }

    private static func thumbnail(from photo: PlantPhotoAsset?) -> Data? {
        autoreleasepool {
            guard let data = photo?.loadData(), let image = UIImage(data: data) else { return nil }

            let scale = max(
                thumbnailSize.width / image.size.width,
                thumbnailSize.height / image.size.height
            )
            let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(
                x: (thumbnailSize.width - scaledSize.width) / 2,
                y: (thumbnailSize.height - scaledSize.height) / 2
            )

            return UIGraphicsImageRenderer(size: thumbnailSize).image { _ in
                image.draw(in: CGRect(origin: origin, size: scaledSize))
            }
            .jpegData(compressionQuality: 0.72)
        }
    }
}
