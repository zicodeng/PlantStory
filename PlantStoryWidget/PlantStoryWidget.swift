import SwiftUI
import WidgetKit

struct WateringWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetWateringSnapshot

    var dueItems: [WidgetWateringItem] {
        snapshot.items.filter { $0.dueDate <= date }
    }
}

struct WateringWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WateringWidgetEntry {
        WateringWidgetEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (WateringWidgetEntry) -> Void) {
        let snapshot = context.isPreview ? WidgetWateringSnapshot.preview : WidgetWateringSnapshotStore.load()
        completion(WateringWidgetEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WateringWidgetEntry>) -> Void) {
        let now = Date.now
        let snapshot = WidgetWateringSnapshotStore.load()
        let futureDates = snapshot.items
            .map(\.dueDate)
            .filter { $0 > now }
            .sorted()

        var dates = [now]
        for date in futureDates where dates.last != date {
            dates.append(date)
        }

        let entries = dates.map { WateringWidgetEntry(date: $0, snapshot: snapshot) }
        let fallbackRefresh = Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now.addingTimeInterval(21_600)
        completion(Timeline(entries: entries, policy: .after(futureDates.first ?? fallbackRefresh)))
    }
}

struct PlantStoryWateringWidgetView: View {
    let entry: WateringWidgetEntry

    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let lime = Color(red: 0.36, green: 0.82, blue: 0.12)
    private let waterBlue = Color(red: 0.22, green: 0.64, blue: 0.88)
    private let overdueOrange = Color(red: 0.95, green: 0.43, blue: 0.14)

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            header

            if entry.dueItems.isEmpty {
                emptyState
            } else {
                dueList
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .containerBackground(forest, for: .widget)
        .environment(\.locale, Locale(identifier: entry.snapshot.languageCode))
        .widgetURL(URL(string: "plantstory://watering-due"))
    }

    private var header: some View {
        HStack(spacing: 9) {
            Image("WidgetLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .accessibilityHidden(true)

            Text("Watering due")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .allowsTightening(true)

            Spacer(minLength: 8)

            if !entry.dueItems.isEmpty {
                Text("\(entry.dueItems.count)")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(forest)
                    .frame(minWidth: 26, minHeight: 26)
                    .background(lime, in: Circle())
                    .accessibilityLabel(dueCountAccessibilityLabel)
            }
        }
    }

    private var dueList: some View {
        VStack(spacing: 0) {
            ForEach(Array(entry.dueItems.prefix(3).enumerated()), id: \.element.id) { index, item in
                Link(destination: plantURL(for: item.id)) {
                    wateringRow(item)
                }
                .buttonStyle(.plain)

                if index < min(entry.dueItems.count, 3) - 1 {
                    Divider()
                        .overlay(.white.opacity(0.12))
                        .padding(.leading, 38)
                        .padding(.vertical, 1)
                }
            }
        }
    }

    private func wateringRow(_ item: WidgetWateringItem) -> some View {
        HStack(spacing: 10) {
            thumbnail(for: item)

            Text(item.name)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer(minLength: 6)

            Label {
                Text(statusText(for: item))
                    .lineLimit(1)
            } icon: {
                Image(systemName: "drop.fill")
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(isOverdue(item) ? overdueOrange : waterBlue)
        }
        .frame(maxWidth: .infinity, minHeight: 34)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Opens plant details"))
    }

    @ViewBuilder
    private func thumbnail(for item: WidgetWateringItem) -> some View {
        if let data = item.thumbnailData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 28, height: 28)
                .clipShape(Circle())
        } else {
            Image(systemName: "leaf.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(forest)
                .frame(width: 28, height: 28)
                .background(lime.opacity(0.9), in: Circle())
        }
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(lime)

            VStack(alignment: .leading, spacing: 2) {
                Text("All caught up")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                Text("No watering reminders are due.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.64))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func isOverdue(_ item: WidgetWateringItem) -> Bool {
        !Calendar.current.isDate(item.dueDate, inSameDayAs: entry.date)
    }

    private func statusText(for item: WidgetWateringItem) -> String {
        guard isOverdue(item) else {
            return WidgetLocalization.string("Today", languageCode: entry.snapshot.languageCode)
        }

        let calendar = Calendar.current
        let dueDay = calendar.startOfDay(for: item.dueDate)
        let today = calendar.startOfDay(for: entry.date)
        let days = max(calendar.dateComponents([.day], from: dueDay, to: today).day ?? 1, 1)
        return WidgetLocalization.string(
            "%lldd overdue",
            languageCode: entry.snapshot.languageCode,
            Int64(days)
        )
    }

    private var dueCountAccessibilityLabel: String {
        WidgetLocalization.string(
            "%lld watering reminders due",
            languageCode: entry.snapshot.languageCode,
            Int64(entry.dueItems.count)
        )
    }

    private func plantURL(for id: UUID) -> URL {
        URL(string: "plantstory://plant/\(id.uuidString)")!
    }
}

struct PlantStoryWateringWidget: Widget {
    let kind = WidgetWateringSnapshotStore.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WateringWidgetProvider()) { entry in
            PlantStoryWateringWidgetView(entry: entry)
        }
        .configurationDisplayName("Watering due")
        .description("See which plants have a watering reminder due.")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct PlantStoryWidgetBundle: WidgetBundle {
    var body: some Widget {
        PlantStoryWateringWidget()
    }
}

private enum WidgetLocalization {
    static func string(_ key: String, languageCode: String, _ arguments: CVarArg...) -> String {
        let format: String
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            format = bundle.localizedString(forKey: key, value: key, table: "Localizable")
        } else {
            format = key
        }

        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: Locale(identifier: languageCode), arguments: arguments)
    }
}

private extension WidgetWateringSnapshot {
    static let preview = WidgetWateringSnapshot(
        updatedAt: .now,
        languageCode: "en",
        items: [
            WidgetWateringItem(id: UUID(), name: "Monstera", dueDate: .now.addingTimeInterval(-172_800), thumbnailData: nil),
            WidgetWateringItem(id: UUID(), name: "Pothos", dueDate: .now.addingTimeInterval(-3_600), thumbnailData: nil),
            WidgetWateringItem(id: UUID(), name: "Fern", dueDate: .now.addingTimeInterval(-1_800), thumbnailData: nil),
        ]
    )
}
