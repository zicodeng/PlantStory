import SwiftUI

struct PlantTaxonomyGuideView: View {
    @State private var selectedGroup: MajorPlantGroup?
    @State private var selectedRank: PlantAddressRank = .family

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)
    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let violet = Color(red: 0.52, green: 0.42, blue: 0.78)

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    intro

                    NavigationLink {
                        HouseplantFamilyFinderView()
                    } label: {
                        familyFinderCard
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens the houseplant family finder")

                    guideSection(title: "Meet four major plant groups", icon: "point.3.filled.connected.trianglepath.dotted") {
                        PlantGroupMapView { group in
                            selectedGroup = group
                        }

                        Text("Tap a numbered group to see what sets it apart.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 12) {
                            ForEach(MajorPlantGroup.allCases) { group in
                                Button {
                                    selectedGroup = group
                                } label: {
                                    groupRow(group)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens plant group details")
                            }
                        }

                        Text("This is a beginner map of land plants—not every branch of the scientific tree.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    guideSection(title: "Follow one plant’s address", icon: "arrow.down") {
                        Text("Taxonomy works like an address: broad groups narrow toward one particular plant.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        PlantAddressLadder(selectedRank: $selectedRank)

                        rankExplanation
                    }

                    guideSection(title: "Decode a scientific name", icon: "text.magnifyingglass") {
                        VStack(alignment: .leading, spacing: 18) {
                            scientificName

                            Divider()

                            namePartRow(
                                color: Color(red: 0.22, green: 0.57, blue: 0.38),
                                title: "Genus",
                                example: "Monstera",
                                text: "Starts with a capital letter and is italicized."
                            )
                            namePartRow(
                                color: Color(red: 0.29, green: 0.58, blue: 0.72),
                                title: "Species",
                                example: "deliciosa",
                                text: "Uses lowercase and is italicized with the genus."
                            )
                            namePartRow(
                                color: violet,
                                title: "Cultivar",
                                example: "‘Thai Constellation’",
                                text: "A named cultivated selection. It uses quotes and is not italicized."
                            )
                            namePartRow(
                                color: Color(red: 0.91, green: 0.46, blue: 0.25),
                                title: "Hybrid sign",
                                example: "×",
                                text: "This multiplication sign shows that a plant has a hybrid origin."
                            )
                        }
                        .padding(18)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    guideSection(title: "Common-name surprises", icon: "questionmark.bubble.fill") {
                        VStack(spacing: 12) {
                            surpriseCard(
                                commonName: "Sago palm",
                                reveal: "A cycad, not a true palm",
                                icon: "tree.fill"
                            )
                            surpriseCard(
                                commonName: "Asparagus fern",
                                reveal: "A flowering plant, not a true fern",
                                icon: "leaf.fill"
                            )
                            surpriseCard(
                                commonName: "Peace lily",
                                reveal: "An aroid, not a true lily",
                                icon: "camera.macro"
                            )
                            surpriseCard(
                                commonName: "Swiss cheese plant",
                                reveal: "A shared name used for more than one Monstera",
                                icon: "square.on.square"
                            )
                        }

                        Text("Common names are useful, but they can vary by region or point to several different plants.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    guideSection(title: "Why taxonomy helps", icon: "sparkles") {
                        VStack(spacing: 0) {
                            factRow(
                                icon: "person.2.fill",
                                title: "It reveals relationships",
                                text: "A family or genus can show that two plants share an evolutionary branch even when they look different."
                            )
                            Divider().padding(.leading, 60)
                            factRow(
                                icon: "globe",
                                title: "It travels across languages",
                                text: "Scientific names help people identify the same plant when local common names differ."
                            )
                            Divider().padding(.leading, 60)
                            factRow(
                                icon: "magnifyingglass",
                                title: "It improves your search",
                                text: "A species name usually leads to more precise care and identification information than a broad common name."
                            )
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                        Text("Related plants may share traits, but they are not guaranteed to need identical care. Taxonomy is a clue, not a care schedule.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    guideSection(title: "Why plant names change", icon: "arrow.triangle.2.circlepath") {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("A better family tree", systemImage: "tree.fill")
                                .font(.headline)
                                .foregroundStyle(ink)

                            Text("Researchers compare plant structures, specimens, and DNA. New evidence can move a species to a different genus or change which name is accepted.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("Older names often remain searchable as synonyms, so a familiar label can still help you find the currently accepted name.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(18)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    Label {
                        Text("You do not need to memorize every rank. Start with family, genus, species, and cultivar—the names you are most likely to encounter as a plant owner.")
                    } icon: {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(violet)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .background(violet.opacity(0.11), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Plant Families & Taxonomy")
                    .font(.headline)
            }
        }
        .sheet(item: $selectedGroup) { group in
            PlantGroupDetailView(group: group)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("MEET THE PLANT FAMILY TREE", systemImage: "point.3.filled.connected.trianglepath.dotted")
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(Color(red: 0.74, green: 0.65, blue: 0.96))

            Text("See where a plant fits.")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Explore the big branches of land plants, then learn how family, genus, species, and cultivar narrow down one name.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(forest, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var familyFinderCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.title3.weight(.semibold))
                .foregroundStyle(violet)
                .frame(width: 48, height: 48)
                .background(violet.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("Find a houseplant family")
                    .font(.headline)
                    .foregroundStyle(ink)
                Text("Search common names, scientific names, genera, and families.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func guideSection<Content: View>(
        title: LocalizedStringKey,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(ink)
            content()
        }
    }

    private var rankExplanation: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(selectedRank.labelKey))
                .font(.headline)
                .foregroundStyle(selectedRank.accent)
            Text(LocalizedStringKey(selectedRank.explanationKey))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(selectedRank.accent.opacity(0.11), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var scientificName: some View {
        VStack(alignment: .leading, spacing: 5) {
            (Text(verbatim: "Monstera deliciosa").italic() + Text(verbatim: " ‘Thai Constellation’"))
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("One name, three useful pieces")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

private extension PlantTaxonomyGuideView {
    func groupRow(_ group: MajorPlantGroup) -> some View {
        HStack(spacing: 14) {
            Text(verbatim: "\(group.number)")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(group.accent, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(group.titleKey))
                    .font(.headline)
                    .foregroundStyle(ink)
                Text(LocalizedStringKey(group.summaryKey))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func namePartRow(color: Color, title: LocalizedStringKey, example: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title).font(.headline).foregroundStyle(ink)
                    Text(verbatim: example).font(.subheadline.weight(.semibold)).foregroundStyle(color)
                }
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    func surpriseCard(commonName: LocalizedStringKey, reveal: LocalizedStringKey, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(violet)
                .frame(width: 42, height: 42)
                .background(violet.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(commonName).font(.headline).foregroundStyle(ink)
                Text(reveal)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func factRow(icon: String, title: LocalizedStringKey, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(violet)
                .frame(width: 32, height: 32)
                .background(violet.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(ink)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 14)
    }
}

private struct PlantGroupMapView: View {
    var highlightedGroup: MajorPlantGroup?
    var onSelect: ((MajorPlantGroup) -> Void)?

    init(highlightedGroup: MajorPlantGroup? = nil, onSelect: ((MajorPlantGroup) -> Void)? = nil) {
        self.highlightedGroup = highlightedGroup
        self.onSelect = onSelect
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image("PlantTaxonomyGroups")
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .accessibilityHidden(true)

                ForEach(MajorPlantGroup.allCases) { group in
                    marker(for: group)
                        .position(
                            x: proxy.size.width * group.markerPosition.x,
                            y: proxy.size.height * group.markerPosition.y
                        )
                }
            }
        }
        .aspectRatio(1.5, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func marker(for group: MajorPlantGroup) -> some View {
        if let onSelect {
            Button {
                onSelect(group)
            } label: {
                markerBadge(for: group)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(LocalizedStringKey(group.titleKey)))
            .accessibilityHint("Opens plant group details")
        } else {
            markerBadge(for: group)
                .accessibilityLabel(Text(LocalizedStringKey(group.titleKey)))
        }
    }

    private func markerBadge(for group: MajorPlantGroup) -> some View {
        let isHighlighted = highlightedGroup == nil || highlightedGroup == group
        return Text(verbatim: "\(group.number)")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(group.accent, in: Circle())
            .overlay {
                Circle().stroke(.white, lineWidth: highlightedGroup == group ? 3 : 1.5)
            }
            .shadow(color: .black.opacity(isHighlighted ? 0.28 : 0.10), radius: 3, y: 1)
            .scaleEffect(highlightedGroup == group ? 1.16 : 1)
            .opacity(isHighlighted ? 1 : 0.45)
    }
}

private struct PlantAddressLadder: View {
    @Binding var selectedRank: PlantAddressRank

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(PlantAddressRank.allCases.enumerated()), id: \.element) { index, rank in
                Button {
                    selectedRank = rank
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: rank.icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedRank == rank ? .white : rank.accent)
                            .frame(width: 34, height: 34)
                            .background(selectedRank == rank ? rank.accent : rank.accent.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(rank.labelKey))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(LocalizedStringKey(rank.example))
                                .font(.headline)
                                .italic(rank.usesItalic)
                                .foregroundStyle(Color(red: 0.045, green: 0.16, blue: 0.19))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(selectedRank == rank ? rank.accent.opacity(0.10) : .clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Explains this taxonomy level")

                if index < PlantAddressRank.allCases.count - 1 {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.22))
                        .frame(width: 2, height: 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 28)
                }
            }
        }
        .padding(8)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct PlantGroupDetailView: View {
    let group: MajorPlantGroup
    @Environment(\.dismiss) private var dismiss

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Canvas").ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        PlantGroupMapView(highlightedGroup: group)

                        Label("MAJOR PLANT GROUP", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .tracking(1.3)
                            .foregroundStyle(group.accent)

                        Text(LocalizedStringKey(group.titleKey))
                            .font(.system(.largeTitle, design: .serif, weight: .semibold))
                            .foregroundStyle(ink)

                        Text(LocalizedStringKey(group.detailKey))
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        detailRow(title: "How to recognize it", textKey: group.recognitionKey, icon: "eye.fill")
                        detailRow(title: "Familiar examples", textKey: group.examplesKey, icon: "leaf.fill")
                        detailRow(title: "Beginner note", textKey: group.noteKey, icon: "lightbulb.fill")
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func detailRow(title: LocalizedStringKey, textKey: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(group.accent)
                .frame(width: 42, height: 42)
                .background(group.accent.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline).foregroundStyle(ink)
                Text(LocalizedStringKey(textKey))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private enum MajorPlantGroup: String, CaseIterable, Identifiable {
    case mosses
    case ferns
    case gymnosperms
    case floweringPlants

    var id: Self { self }

    var number: Int {
        switch self {
        case .mosses: 1
        case .ferns: 2
        case .gymnosperms: 3
        case .floweringPlants: 4
        }
    }

    var titleKey: String {
        switch self {
        case .mosses: "Mosses and liverworts"
        case .ferns: "Ferns and relatives"
        case .gymnosperms: "Gymnosperms"
        case .floweringPlants: "Flowering plants"
        }
    }

    var summaryKey: String {
        switch self {
        case .mosses: "Small land plants that reproduce with spores"
        case .ferns: "Vascular plants with spores instead of seeds"
        case .gymnosperms: "Seed plants whose seeds are not enclosed in fruit"
        case .floweringPlants: "Plants that make flowers and seeds within fruits"
        }
    }

    var detailKey: String {
        switch self {
        case .mosses: "Mosses and liverworts belong to early branches of the land-plant family tree. They stay small and reproduce with spores rather than flowers, fruits, or seeds."
        case .ferns: "Ferns and their relatives have vascular tissue that moves water through the plant, but they reproduce with spores rather than seeds."
        case .gymnosperms: "Gymnosperms are seed plants, but their seeds are not enclosed inside fruits. Many familiar gymnosperms produce cones."
        case .floweringPlants: "Flowering plants, also called angiosperms, form flowers and enclose their seeds within an ovary that develops into a fruit."
        }
    }

    var recognitionKey: String {
        switch self {
        case .mosses: "Look for low mats or small leafy forms in moist places. Fine stalks with capsules may rise above a moss when it is producing spores."
        case .ferns: "Many have divided fronds. Mature fronds may carry clusters of spore-producing structures, often visible as dots or lines on the underside."
        case .gymnosperms: "Cones are a strong clue. Needle-like leaves are common among conifers, while cycads and ginkgo show that the group has other leaf shapes too."
        case .floweringPlants: "A visible flower or fruit is the clearest clue, but either may be absent outside the plant’s reproductive season."
        }
    }

    var examplesKey: String {
        switch self {
        case .mosses: "Cushion mosses, sheet mosses, and liverworts."
        case .ferns: "Boston fern, bird’s-nest fern, maidenhair fern, and horsetails."
        case .gymnosperms: "Pines, cycads such as the sago palm, ginkgo, and firs."
        case .floweringPlants: "Monstera, pothos, orchids, palms, grasses, and cacti."
        }
    }

    var noteKey: String {
        switch self {
        case .mosses: "They do not have the same vascular plumbing or true roots found in ferns and seed plants."
        case .ferns: "The brown dots beneath a healthy fern frond may be sori that produce spores—not necessarily pests or disease."
        case .gymnosperms: "A plant can have palm-like leaves without being a flowering palm. Sago palm is a cycad."
        case .floweringPlants: "Flowers can be tiny, seasonal, or easy to overlook. A plant does not need to be blooming now to belong to this group."
        }
    }

    var markerPosition: CGPoint {
        switch self {
        case .mosses: CGPoint(x: 0.13, y: 0.76)
        case .ferns: CGPoint(x: 0.35, y: 0.76)
        case .gymnosperms: CGPoint(x: 0.63, y: 0.76)
        case .floweringPlants: CGPoint(x: 0.87, y: 0.76)
        }
    }

    var accent: Color {
        switch self {
        case .mosses: Color(red: 0.42, green: 0.58, blue: 0.24)
        case .ferns: Color(red: 0.19, green: 0.58, blue: 0.34)
        case .gymnosperms: Color(red: 0.57, green: 0.42, blue: 0.24)
        case .floweringPlants: Color(red: 0.86, green: 0.42, blue: 0.51)
        }
    }
}

private enum PlantAddressRank: String, CaseIterable, Identifiable {
    case plants
    case floweringPlants
    case family
    case genus
    case species
    case cultivar

    var id: Self { self }

    var labelKey: String {
        switch self {
        case .plants: "Broad group"
        case .floweringPlants: "Major branch"
        case .family: "Family"
        case .genus: "Genus"
        case .species: "Species"
        case .cultivar: "Cultivar"
        }
    }

    var example: String {
        switch self {
        case .plants: "Plants"
        case .floweringPlants: "Flowering plants"
        case .family: "Araceae"
        case .genus: "Monstera"
        case .species: "Monstera deliciosa"
        case .cultivar: "‘Thai Constellation’"
        }
    }

    var explanationKey: String {
        switch self {
        case .plants: "The broad starting point in this simplified address. Many additional scientific ranks exist below it."
        case .floweringPlants: "Monstera sits on the flowering-plant branch—the largest major group in this beginner map."
        case .family: "A family contains related genera. Araceae includes Monstera, Epipremnum, Philodendron, and many other aroids."
        case .genus: "A genus brings together closely related species. It is the first word in a scientific species name."
        case .species: "The genus and specific epithet together identify the species: Monstera deliciosa."
        case .cultivar: "A cultivar is a named selection maintained through cultivation. It sits below the species in this practical plant address."
        }
    }

    var icon: String {
        switch self {
        case .plants: "globe.americas.fill"
        case .floweringPlants: "camera.macro"
        case .family: "person.3.fill"
        case .genus: "person.2.fill"
        case .species: "leaf.fill"
        case .cultivar: "sparkles"
        }
    }

    var accent: Color {
        switch self {
        case .plants: Color(red: 0.38, green: 0.52, blue: 0.60)
        case .floweringPlants: Color(red: 0.86, green: 0.42, blue: 0.51)
        case .family: Color(red: 0.55, green: 0.45, blue: 0.76)
        case .genus: Color(red: 0.28, green: 0.58, blue: 0.70)
        case .species: Color(red: 0.19, green: 0.59, blue: 0.36)
        case .cultivar: Color(red: 0.72, green: 0.48, blue: 0.76)
        }
    }

    var usesItalic: Bool {
        self == .species
    }
}
