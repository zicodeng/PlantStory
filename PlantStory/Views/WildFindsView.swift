import SwiftUI

struct WildFindsView: View {
    @EnvironmentObject private var store: WildFindStore
    @State private var showingAddFind = false
    @State private var findToDelete: WildFind?
    @State private var searchText = ""

    private let warmPaper = Color(red: 0.98, green: 0.83, blue: 0.59)
    private let paleSun = Color(red: 1.0, green: 0.91, blue: 0.73)
    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)
    private let botanical = Color(red: 0.08, green: 0.45, blue: 0.24)
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 14, alignment: .top)
    ]

    private var visibleFinds: [WildFind] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return store.finds }
        return store.finds.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            ($0.otherName?.localizedCaseInsensitiveContains(query) ?? false) ||
            $0.species.localizedCaseInsensitiveContains(query) ||
            ($0.notes?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.finds.isEmpty {
                    emptyLanding
                } else {
                    collection
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                if let find = store.finds.first(where: { $0.id == id }) {
                    WildFindDetailView(find: find)
                        .toolbar(.visible, for: .navigationBar)
                }
            }
            .sheet(isPresented: $showingAddFind) {
                NavigationStack { WildFindFormView() }
            }
            .confirmationDialog(
                "Delete \(findToDelete?.name ?? "this wild find")?",
                isPresented: Binding(
                    get: { findToDelete != nil },
                    set: { if !$0 { findToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete wild find", role: .destructive) {
                    if let findToDelete { store.delete(findToDelete) }
                    findToDelete = nil
                }
                Button("Cancel", role: .cancel) { findToDelete = nil }
            } message: {
                Text("Its photos and timeline will also be removed.")
            }
        }
        .preferredColorScheme(.light)
    }

    private var emptyLanding: some View {
        ZStack {
            warmPaper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Label("WILD FINDS", systemImage: "leaf.fill")
                        .font(.caption.weight(.bold))
                        .tracking(2.2)
                        .foregroundStyle(botanical)

                    botanicalHero

                    Text("Remember the plants\nyou meet outside.")
                        .font(.system(size: 38, weight: .medium, design: .serif))
                        .foregroundStyle(ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Save the plants you discover in parks, on trails, and while traveling.")
                        .font(.body)
                        .foregroundStyle(ink.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)

                    addButton
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
                .padding(.top, 22)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var collection: some View {
        ZStack {
            warmPaper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    collectionHeader
                    searchField

                    HStack {
                        Text("Your discoveries")
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .foregroundStyle(ink)
                        Spacer()
                        Text("\(visibleFinds.count)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(botanical)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(botanical.opacity(0.10), in: Capsule())
                    }

                    if visibleFinds.isEmpty {
                        noSearchResults
                    } else {
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                            ForEach(visibleFinds) { find in
                                NavigationLink(value: find.id) {
                                    WildFindCard(find: find, ink: ink, botanical: botanical, paleSun: paleSun)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        findToDelete = find
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var collectionHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Wild Finds")
                    .font(.system(size: 36, weight: .semibold, design: .serif))
                    .foregroundStyle(ink)
                Text(collectionSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(ink.opacity(0.68))
            }
            Spacer()
            Button { showingAddFind = true } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(botanical, in: Circle())
                    .shadow(color: botanical.opacity(0.20), radius: 12, y: 6)
            }
            .accessibilityLabel("Add a wild find")
        }
    }

    private var collectionSubtitle: String {
        let count = store.finds.count
        return count == 1 ? "You’ve saved 1 discovery" : "You’ve saved \(count) discoveries"
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(botanical.opacity(0.72))

            TextField("Search wild finds", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(ink)
                .tint(botanical)

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(ink.opacity(0.38))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 15)
        .frame(height: 48)
        .background(paleSun.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.42), lineWidth: 1)
        }
    }

    private var noSearchResults: some View {
        VStack(spacing: 10) {
            Image(systemName: "leaf.circle")
                .font(.largeTitle)
                .foregroundStyle(botanical)
            Text("No matching wild finds")
                .font(.system(.headline, design: .serif, weight: .semibold))
                .foregroundStyle(ink)
            Text("Try another name or species.")
                .font(.subheadline)
                .foregroundStyle(ink.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 46)
    }

    private var addButton: some View {
        Button { showingAddFind = true } label: {
            Text("Add a plant")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 50)
                .background(botanical, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var botanicalHero: some View {
        AnimatedWildFindHero(
            warmPaper: warmPaper,
            paleSun: paleSun,
            botanical: botanical
        )
    }
}

private struct AnimatedWildFindHero: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    let warmPaper: Color
    let paleSun: Color
    let botanical: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [paleSun, warmPaper.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(.white.opacity(0.3))
                .frame(width: 190, height: 190)

            Image(systemName: "leaf.fill")
                .font(.system(size: 112, weight: .bold))
                .foregroundStyle(botanical.opacity(0.24))
                .rotationEffect(.degrees(isAnimating ? -22 : -30))
                .offset(x: isAnimating ? -49 : -56, y: isAnimating ? 10 : 20)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 3.8).repeatForever(autoreverses: true),
                    value: isAnimating
                )

            Image(systemName: "leaf.fill")
                .font(.system(size: 92, weight: .bold))
                .foregroundStyle(botanical.opacity(0.2))
                .rotationEffect(.degrees(isAnimating ? 28 : 36))
                .offset(x: isAnimating ? 55 : 62, y: isAnimating ? 23 : 34)
                .animation(
                    reduceMotion
                        ? nil
                        : .easeInOut(duration: 4.1)
                            .repeatForever(autoreverses: true)
                            .delay(0.45),
                    value: isAnimating
                )

            Image(systemName: "camera.macro")
                .font(.system(size: 72, weight: .medium))
                .foregroundStyle(botanical)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 110, height: 110)
        }
        .frame(height: 270)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.34), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Animated illustration of discovering a plant")
        .onAppear {
            isAnimating = !reduceMotion
        }
        .onChange(of: reduceMotion) { _, shouldReduceMotion in
            isAnimating = !shouldReduceMotion
        }
    }
}

private struct WildFindCard: View {
    let find: WildFind
    let ink: Color
    let botanical: Color
    let paleSun: Color
    @State private var cardPhoto: Data?

    init(find: WildFind, ink: Color, botanical: Color, paleSun: Color) {
        self.find = find
        self.ink = ink
        self.botanical = botanical
        self.paleSun = paleSun
        _cardPhoto = State(initialValue: find.photos.randomElement())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    PlantPhoto(data: cardPhoto, cornerRadius: 0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(find.name)
                    .font(.system(.headline, design: .serif, weight: .semibold))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                Text("Found \(find.discoveredDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(botanical)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.top, 11)
            .padding(.bottom, 13)
        }
        .onChange(of: find.photos) { _, photos in
            if let cardPhoto, photos.contains(cardPhoto) { return }
            cardPhoto = photos.randomElement()
        }
        .padding(7)
        .background(paleSun.opacity(0.76), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.42), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens wild find details")
    }
}
