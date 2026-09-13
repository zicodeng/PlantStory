import SwiftUI

struct LeafShapesPatternsView: View {
    @State private var selectedCategory: LeafGuideCategory = .shapes
    @State private var selectedItem: LeafGuideItem?

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)
    private let accent = Color(red: 0.18, green: 0.68, blue: 0.48)
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    intro
                    categoryControl

                    Text("Tap any leaf to learn what to notice.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(selectedCategory.items) { item in
                            Button {
                                selectedItem = item
                            } label: {
                                leafCard(item)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the leaf guide")
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Leaf shapes & patterns")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedItem) { item in
            LeafGuideDetailView(item: item)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("LEAF CLUES", systemImage: "leaf.fill")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(accent)

            Text("Learn to describe what you see.")
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Shape, color, openings, and edges are useful clues when identifying a plant.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var categoryControl: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - 6

            HStack(spacing: 6) {
                categoryButton(.shapes)
                    .frame(width: availableWidth * 0.43)

                categoryButton(.patterns)
                    .frame(width: availableWidth * 0.57)
            }
        }
        .frame(height: 44)
        .padding(5)
        .background(.white, in: Capsule())
    }

    private func categoryButton(_ category: LeafGuideCategory) -> some View {
        Button {
            selectedCategory = category
        } label: {
            HStack(spacing: 5) {
                Image(systemName: category.icon)

                Text(LocalizedStringKey(category.titleKey))
                    .lineLimit(1)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(selectedCategory == category ? .white : ink.opacity(0.62))
            .background(
                selectedCategory == category ? accent : Color.clear,
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
    }

    private func leafCard(_ item: LeafGuideItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(item.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 116)
                .padding(8)
                .background(item.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityHidden(true)

            Text(LocalizedStringKey(item.titleKey))
                .font(.headline)
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(LocalizedStringKey(item.cardDescriptionKey))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Image(systemName: "arrow.right.circle.fill")
                .font(.subheadline)
                .foregroundStyle(item.accent)
        }
        .frame(maxWidth: .infinity, minHeight: 228, alignment: .topLeading)
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct LeafGuideDetailView: View {
    let item: LeafGuideItem

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var appLanguageCode = AppLanguage.english.rawValue

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)

    private var showsPronunciation: Bool {
        AppLanguage(rawValue: appLanguageCode) == .english
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Canvas").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        detailRow(
                            title: "What it looks like",
                            textKey: item.appearanceKey,
                            icon: "eye.fill"
                        )

                        detailRow(
                            title: "How to recognize it",
                            textKey: item.recognitionKey,
                            icon: "magnifyingglass"
                        )

                        detailRow(
                            title: "Why it helps",
                            textKey: item.valueKey,
                            icon: "lightbulb.fill"
                        )

                        detailRow(
                            title: "Common example",
                            textKey: item.exampleKey,
                            icon: "leaf.fill"
                        )
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(item.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 210)
                .padding(14)
                .background(item.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .accessibilityHidden(true)

            Label(
                LocalizedStringKey(item.categoryLabelKey),
                systemImage: "checkmark.circle.fill"
            )
            .font(.caption.weight(.bold))
            .tracking(1.3)
            .foregroundStyle(item.accent)

            Text(LocalizedStringKey(item.titleKey))
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(ink)

            if showsPronunciation, let pronunciationKey = item.pronunciationKey {
                Text(LocalizedStringKey(pronunciationKey))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func detailRow(
        title: LocalizedStringKey,
        textKey: String,
        icon: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(item.accent)
                .frame(width: 42, height: 42)
                .background(item.accent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(ink)

                Text(LocalizedStringKey(textKey))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private enum LeafGuideCategory: String, CaseIterable, Identifiable {
    case shapes
    case patterns

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .shapes: "Shapes"
        case .patterns: "Patterns & features"
        }
    }

    var icon: String {
        switch self {
        case .shapes: "leaf.fill"
        case .patterns: "circle.hexagongrid.fill"
        }
    }

    var items: [LeafGuideItem] {
        switch self {
        case .shapes: [.elliptic, .cordate, .lanceolate, .lobed]
        case .patterns: [.variegated, .spotted, .fenestrated, .serrated]
        }
    }
}

private enum LeafGuideItem: String, Identifiable {
    case elliptic
    case cordate
    case lanceolate
    case lobed
    case variegated
    case spotted
    case fenestrated
    case serrated

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .elliptic: "Elliptic"
        case .cordate: "Cordate"
        case .lanceolate: "Lanceolate"
        case .lobed: "Lobed"
        case .variegated: "Variegated"
        case .spotted: "Spotted"
        case .fenestrated: "Fenestrated"
        case .serrated: "Serrated edge"
        }
    }

    var pronunciationKey: String? {
        switch self {
        case .elliptic: "ih-LIP-tik"
        case .cordate: "KOR-dayt"
        case .lanceolate: "LAN-see-uh-layt"
        case .lobed: "lohb'd"
        case .variegated: "VAIR-ee-uh-gay-tid"
        case .spotted: nil
        case .fenestrated: "FEN-uh-stray-tid"
        case .serrated: "SAIR-ay-tid"
        }
    }

    var categoryLabelKey: String {
        switch self {
        case .elliptic, .cordate, .lanceolate, .lobed: "LEAF SHAPE"
        case .variegated, .spotted, .fenestrated, .serrated: "LEAF FEATURE"
        }
    }

    var imageName: String {
        switch self {
        case .elliptic: "PlantLeafShapeElliptic"
        case .cordate: "PlantLeafShapeCordate"
        case .lanceolate: "PlantLeafShapeLanceolate"
        case .lobed: "PlantLeafShapeLobed"
        case .variegated: "PlantLeafPatternVariegated"
        case .spotted: "PlantLeafPatternSpotted"
        case .fenestrated: "PlantLeafFeatureFenestrated"
        case .serrated: "PlantLeafFeatureSerrated"
        }
    }

    var accent: Color {
        switch self {
        case .elliptic: Color(red: 0.18, green: 0.68, blue: 0.48)
        case .cordate: Color(red: 0.89, green: 0.35, blue: 0.42)
        case .lanceolate: Color(red: 0.20, green: 0.55, blue: 0.78)
        case .lobed: Color(red: 0.64, green: 0.48, blue: 0.78)
        case .variegated: Color(red: 0.35, green: 0.62, blue: 0.22)
        case .spotted: Color(red: 0.44, green: 0.53, blue: 0.72)
        case .fenestrated: Color(red: 0.06, green: 0.58, blue: 0.47)
        case .serrated: Color(red: 0.88, green: 0.55, blue: 0.16)
        }
    }

    var cardDescriptionKey: String {
        switch self {
        case .elliptic: "Widest near the middle"
        case .cordate: "A heart-like base notch"
        case .lanceolate: "Long, narrow, and pointed"
        case .lobed: "Deep curves divide the blade"
        case .variegated: "Stable areas of contrasting color"
        case .spotted: "Repeated dots or patches"
        case .fenestrated: "Natural holes or splits"
        case .serrated: "A saw-toothed margin"
        }
    }

    var appearanceKey: String {
        switch self {
        case .elliptic: "An oval blade that is widest around the middle and narrows toward both ends."
        case .cordate: "A broad, heart-shaped blade with a notch at the base where the petiole attaches."
        case .lanceolate: "A long, narrow blade that is widest below the middle and tapers to a pointed tip."
        case .lobed: "A single blade with deep rounded or pointed indentations that form distinct sections."
        case .variegated: "Stable areas of cream, yellow, pink, or lighter green appear beside the leaf’s base color."
        case .spotted: "Contrasting dots or patches repeat across the blade as part of the leaf’s normal coloring."
        case .fenestrated: "Openings form naturally inside the blade or as smooth splits along its edges."
        case .serrated: "Small, regular teeth run around the leaf margin like the edge of a saw."
        }
    }

    var recognitionKey: String {
        switch self {
        case .elliptic: "Imagine an ellipse: both sides curve smoothly, with no base notch or deep lobes."
        case .cordate: "Look first at the base. The two rounded sides meet around a clear inward notch."
        case .lanceolate: "Compare length with width. It should be much longer than it is wide and taper gradually."
        case .lobed: "Trace the outer edge. Deep curves reach inward, but the blade remains one connected leaf."
        case .variegated: "The color pattern usually repeats on healthy new leaves. Sudden irregular discoloration may instead signal stress or damage."
        case .spotted: "Natural spots tend to look deliberate and repeat across healthy leaves. Spreading brown spots or yellow halos can indicate damage."
        case .fenestrated: "The openings have smooth, finished edges and appear predictably as the plant matures, unlike ragged chewing damage."
        case .serrated: "Run your eyes along the edge and look for evenly repeated teeth rather than tears or missing chunks."
        }
    }

    var valueKey: String {
        switch self {
        case .elliptic: "It gives you a precise word for a very common leaf shape and helps narrow down similar plants."
        case .cordate: "The distinctive base notch is often more useful for identification than overall leaf size."
        case .lanceolate: "Its strong length-to-width ratio separates it from elliptic and oval leaves."
        case .lobed: "The number, depth, and shape of lobes can distinguish plants that otherwise look alike."
        case .variegated: "Recognizing normal variegation helps you avoid mistaking healthy color for a care problem."
        case .spotted: "Recognizing a consistent natural pattern makes it easier to notice genuinely new or unhealthy spots."
        case .fenestrated: "Knowing these openings are normal prevents confusion with pest damage or torn leaves."
        case .serrated: "Leaf margins are useful identification clues even when two plants share the same overall shape."
        }
    }

    var exampleKey: String {
        switch self {
        case .elliptic: "Rubber plant"
        case .cordate: "Heartleaf philodendron"
        case .lanceolate: "Peace lily"
        case .lobed: "Oak"
        case .variegated: "Golden pothos"
        case .spotted: "Polka dot begonia"
        case .fenestrated: "Monstera"
        case .serrated: "Rose"
        }
    }
}
