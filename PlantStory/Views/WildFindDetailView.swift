import SwiftUI

struct WildFindDetailView: View {
    @EnvironmentObject private var store: WildFindStore
    @Environment(\.dismiss) private var dismiss
    let find: WildFind

    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false
    @State private var heroPhoto: Data?

    private let warmPaper = Color(red: 0.98, green: 0.83, blue: 0.59)
    private let paleSun = Color(red: 1.0, green: 0.91, blue: 0.73)
    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)
    private let botanical = Color(red: 0.08, green: 0.45, blue: 0.24)

    init(find: WildFind) {
        self.find = find
        _heroPhoto = State(initialValue: find.photos.randomElement())
    }

    private var currentFind: WildFind {
        store.finds.first(where: { $0.id == find.id }) ?? find
    }

    private var timelineEvents: [WildFindTimelineEvent] {
        var result = [WildFindTimelineEvent(
            id: "discovered-\(currentFind.id)",
            date: currentFind.discoveredDate,
            kind: .discovered
        )]
        result += currentFind.photos.indices.map { index in
            WildFindTimelineEvent(
                id: "photo-\(index)",
                date: currentFind.dateForPhoto(at: index),
                kind: .photo(currentFind.photos[index], note: currentFind.noteForPhoto(at: index))
            )
        }
        return result.sorted { $0.date > $1.date }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                warmPaper.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 26) {
                        hero(width: max(0, geometry.size.width - 40))
                        if let notes = currentFind.notes,
                           !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            notesSection(notes)
                        }
                        timelineSection
                    }
                    .frame(width: max(0, geometry.size.width - 40))
                    .padding(.top, 16)
                    .padding(.bottom, 44)
                }
                .frame(width: geometry.size.width)
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(warmPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .tint(botanical)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit", systemImage: "pencil") { showingEdit = true }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                WildFindFormView(find: currentFind)
            }
        }
        .confirmationDialog(
            "Delete \(currentFind.name)?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete wild find", role: .destructive) {
                store.delete(currentFind)
                dismiss()
            }
        } message: {
            Text("Its notes, photos, and timeline will also be removed.")
        }
        .onChange(of: currentFind.photos) { _, photos in
            if let heroPhoto, photos.contains(heroPhoto) { return }
            heroPhoto = photos.randomElement()
        }
    }

    private func hero(width: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            PlantPhoto(data: heroPhoto, cornerRadius: 24)
                .frame(width: width, height: 330)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    LinearGradient(
                        colors: [.clear, ink.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }

            VStack(alignment: .leading, spacing: 8) {
                Label("WILD DISCOVERY", systemImage: "camera.macro")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(paleSun)

                Text(currentFind.name)
                    .font(.system(size: 38, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)

                if let otherName = currentFind.otherName, !otherName.isEmpty {
                    Text(otherName)
                        .font(.system(.headline, design: .serif, weight: .medium))
                        .foregroundStyle(.white.opacity(0.86))
                }

                if !currentFind.species.isEmpty {
                    Text(currentFind.species)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
            .padding(22)
        }
        .frame(width: width, height: 330)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.38), lineWidth: 1)
        }
        .shadow(color: ink.opacity(0.18), radius: 18, y: 10)
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Label("Life timeline", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                Spacer()
                Text("\(currentFind.photos.count) photos")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(botanical)
                    .fixedSize()
            }

            VStack(spacing: 0) {
                ForEach(Array(timelineEvents.enumerated()), id: \.element.id) { index, event in
                    timelineRow(event, isLast: index == timelineEvents.count - 1)
                }
            }
        }
        .padding(20)
        .background(paleSun.opacity(0.78), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.42), lineWidth: 1)
        }
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notes", systemImage: "text.book.closed.fill")
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(ink)

            Text(notes)
                .font(.body)
                .foregroundStyle(ink.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(paleSun.opacity(0.78), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.42), lineWidth: 1)
        }
    }

    private func timelineRow(_ event: WildFindTimelineEvent, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 13) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(event.color)
                        .frame(width: 32, height: 32)
                    Image(systemName: event.icon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }
                if !isLast {
                    Rectangle()
                        .fill(botanical.opacity(0.18))
                        .frame(width: 3)
                        .frame(minHeight: event.hasPhotoNote ? 232 : (event.isPhoto ? 186 : 52))
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ink)
                    Text(event.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(ink.opacity(0.56))
                }

                if case let .photo(data, note) = event.kind {
                    if !note.isEmpty {
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(ink.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    PlantPhoto(data: data, cornerRadius: 16)
                        .frame(maxWidth: .infinity)
                        .frame(height: 176)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.bottom, isLast ? 0 : 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct WildFindTimelineEvent: Identifiable {
    enum Kind {
        case photo(Data, note: String)
        case discovered
    }

    let id: String
    let date: Date
    let kind: Kind

    var isPhoto: Bool {
        if case .photo = kind { return true }
        return false
    }

    var hasPhotoNote: Bool {
        if case let .photo(_, note) = kind { return !note.isEmpty }
        return false
    }

    var title: String {
        switch kind {
        case .photo: return "A new sighting"
        case .discovered: return "Discovered outside"
        }
    }

    var icon: String {
        switch kind {
        case .photo: return "camera.fill"
        case .discovered: return "leaf.fill"
        }
    }

    var color: Color {
        switch kind {
        case .photo: return Color(red: 0.08, green: 0.45, blue: 0.24)
        case .discovered: return Color(red: 0.93, green: 0.52, blue: 0.20)
        }
    }
}
