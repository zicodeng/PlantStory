import SwiftUI

struct HouseplantFamilyFinderView: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageCode = AppLanguage.english.rawValue
    @State private var query = ""

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)
    private let violet = Color(red: 0.52, green: 0.42, blue: 0.78)

    private var filteredPlants: [HouseplantTaxon] {
        let needle = query.searchNormalized
        guard !needle.isEmpty else { return [] }

        return HouseplantTaxonomyCatalog.plants
            .filter { plant in
                plant.searchTerms.contains { term in
                    term.searchNormalized.contains(needle)
                }
            }
            .sorted {
                AppLocalization.string($0.commonNameKey)
                    .localizedCaseInsensitiveCompare(AppLocalization.string($1.commonNameKey)) == .orderedAscending
            }
    }

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    intro

                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        familyBrowser
                        popularPlants
                    } else if filteredPlants.isEmpty {
                        noResults
                    } else {
                        searchResults
                    }
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Houseplant Family Finder")
                    .font(.headline)
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("FIND A PLANT’S FAMILY", systemImage: "magnifyingglass")
                .font(.caption.weight(.bold))
                .tracking(1.3)
                .foregroundStyle(violet)

            Text("Search the houseplant family tree")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(ink)

            Text("Try a common name, scientific name, old name, genus, or family. Results stay on this device and work offline.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search common or scientific names", text: $query)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)

                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(violet.opacity(0.14), lineWidth: 1)
            }
            .padding(.top, 4)
        }
    }

    private var familyBrowser: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Browse by family", icon: "point.3.connected.trianglepath.dotted")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(HouseplantFamily.allCases) { family in
                    NavigationLink {
                        HouseplantFamilyDetailView(family: family)
                    } label: {
                        familyCard(family)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens family details")
                }
            }
        }
    }

    private var popularPlants: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Popular houseplants", icon: "leaf.fill")

            VStack(spacing: 0) {
                ForEach(Array(HouseplantTaxonomyCatalog.popular.enumerated()), id: \.element.id) { index, plant in
                    NavigationLink {
                        HouseplantTaxonDetailView(plant: plant)
                    } label: {
                        plantRow(plant)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens the plant’s taxonomy path")

                    if index < HouseplantTaxonomyCatalog.popular.count - 1 {
                        Divider().padding(.leading, 66)
                    }
                }
            }
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 12) {
            dynamicSectionHeading(
                AppLocalization.string("%lld matches", Int64(filteredPlants.count)),
                icon: "list.bullet"
            )

            VStack(spacing: 0) {
                ForEach(Array(filteredPlants.enumerated()), id: \.element.id) { index, plant in
                    NavigationLink {
                        HouseplantTaxonDetailView(plant: plant)
                    } label: {
                        plantRow(plant)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens the plant’s taxonomy path")

                    if index < filteredPlants.count - 1 {
                        Divider().padding(.leading, 66)
                    }
                }
            }
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private var noResults: some View {
        VStack(spacing: 14) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 42))
                .foregroundStyle(violet)

            Text("No matching houseplant yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(ink)

            Text("Try a shorter name, an old scientific name, or a family such as Araceae.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 24)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func dynamicSectionHeading(_ title: String, icon: String) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: icon)
        }
        .font(.system(.title3, design: .serif, weight: .semibold))
        .foregroundStyle(ink)
    }

    private func sectionHeading(_ title: LocalizedStringKey, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(.title3, design: .serif, weight: .semibold))
            .foregroundStyle(ink)
    }

    private func familyCard(_ family: HouseplantFamily) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: family.icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(family.accent)
                .frame(width: 38, height: 38)
                .background(family.accent.opacity(0.13), in: Circle())

            Text(verbatim: family.latinName)
                .font(.headline)
                .foregroundStyle(ink)

            Text(LocalizedStringKey(family.commonNameKey))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func plantRow(_ plant: HouseplantTaxon) -> some View {
        HStack(spacing: 14) {
            Image(systemName: plant.family.icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(plant.family.accent)
                .frame(width: 44, height: 44)
                .background(plant.family.accent.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(plant.commonNameKey))
                    .font(.headline)
                    .foregroundStyle(ink)

                Text(verbatim: plant.scientificName)
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.secondary)

                Text(verbatim: plant.family.latinName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(plant.family.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .contentShape(Rectangle())
    }
}

private struct HouseplantTaxonDetailView: View {
    let plant: HouseplantTaxon
    @AppStorage(AppLanguage.storageKey) private var appLanguageCode = AppLanguage.english.rawValue

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)

    private var displayedAliases: [String] {
        let language = AppLanguage(rawValue: appLanguageCode) ?? .english
        return plant.aliasesForDisplay(in: language)
    }

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey(plant.commonNameKey))
                            .font(.system(.largeTitle, design: .serif, weight: .semibold))
                            .foregroundStyle(ink)

                        Text(verbatim: plant.scientificName)
                            .font(.title3)
                            .italic()
                            .foregroundStyle(plant.family.accent)
                    }

                    sectionHeading("Its taxonomy path", icon: "arrow.down")
                    FocusedTaxonomyBranch(plant: plant)

                    if !displayedAliases.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionHeading("You may also know it as", icon: "tag.fill")
                            Text(verbatim: displayedAliases.joined(separator: " · "))
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    familySnapshot

                    Label {
                        Text("A family relationship offers identification clues, but related plants can still need different care.")
                    } icon: {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(plant.family.accent)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .background(plant.family.accent.opacity(0.11), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(LocalizedStringKey(plant.commonNameKey))
                    .font(.headline)
            }
        }
    }

    private var familySnapshot: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading("Meet the family", icon: plant.family.icon)

            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: plant.family.latinName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(ink)
                Text(LocalizedStringKey(plant.family.commonNameKey))
                    .font(.subheadline)
                    .foregroundStyle(plant.family.accent)
            }

            Divider()
            detailLine(title: "What often stands out", textKey: plant.family.clueKey)
            detailLine(title: "Familiar relatives", textKey: plant.family.examplesKey)
            detailLine(title: "Remember", textKey: plant.family.noteKey)
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func sectionHeading(_ title: LocalizedStringKey, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(.title3, design: .serif, weight: .semibold))
            .foregroundStyle(ink)
    }

    private func detailLine(title: LocalizedStringKey, textKey: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(ink)
            Text(LocalizedStringKey(textKey))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct HouseplantFamilyDetailView: View {
    let family: HouseplantFamily

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)

    private var familyPlants: [HouseplantTaxon] {
        HouseplantTaxonomyCatalog.plants.filter { $0.family == family }
    }

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(LocalizedStringKey(family.commonNameKey), systemImage: family.icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(family.accent)
                        Text(verbatim: family.latinName)
                            .font(.system(.largeTitle, design: .serif, weight: .semibold))
                            .foregroundStyle(ink)
                    }

                    FamilyTaxonomyBranch(family: family)

                    VStack(alignment: .leading, spacing: 14) {
                        detailLine(title: "Meet the family", textKey: family.summaryKey)
                        Divider()
                        detailLine(title: "What often stands out", textKey: family.clueKey)
                        detailLine(title: "Remember", textKey: family.noteKey)
                    }
                    .padding(18)
                    .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Plants in this starter catalog", systemImage: "leaf.fill")
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .foregroundStyle(ink)

                        VStack(spacing: 0) {
                            ForEach(Array(familyPlants.enumerated()), id: \.element.id) { index, plant in
                                NavigationLink {
                                    HouseplantTaxonDetailView(plant: plant)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(LocalizedStringKey(plant.commonNameKey))
                                                .font(.headline)
                                                .foregroundStyle(ink)
                                            Text(verbatim: plant.scientificName)
                                                .font(.subheadline)
                                                .italic()
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(14)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if index < familyPlants.count - 1 {
                                    Divider().padding(.leading, 14)
                                }
                            }
                        }
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(verbatim: family.latinName)
                    .font(.headline)
            }
        }
    }

    private func detailLine(title: LocalizedStringKey, textKey: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.headline).foregroundStyle(ink)
            Text(LocalizedStringKey(textKey))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct FocusedTaxonomyBranch: View {
    let plant: HouseplantTaxon

    var body: some View {
        TaxonomyBranchView(
            accent: plant.family.accent,
            nodes: [
                ("Broad group", AppLocalization.string("Plants"), false),
                ("Major branch", AppLocalization.string("Flowering plants"), false),
                ("Order", plant.family.orderName, false),
                ("Family", plant.family.latinName, false),
                ("Genus", plant.genus, true),
                ("Species", plant.scientificName, true)
            ]
        )
    }
}

private struct FamilyTaxonomyBranch: View {
    let family: HouseplantFamily

    var body: some View {
        TaxonomyBranchView(
            accent: family.accent,
            nodes: [
                ("Broad group", AppLocalization.string("Plants"), false),
                ("Major branch", AppLocalization.string("Flowering plants"), false),
                ("Order", family.orderName, false),
                ("Family", family.latinName, false)
            ]
        )
    }
}

private struct TaxonomyBranchView: View {
    let accent: Color
    let nodes: [(rank: String, value: String, italic: Bool)]

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(nodes.enumerated()), id: \.offset) { index, node in
                HStack(spacing: 12) {
                    Text(verbatim: "\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(accent, in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey(node.rank))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(verbatim: node.value)
                            .font(.headline)
                            .italic(node.italic)
                            .foregroundStyle(ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)

                if index < nodes.count - 1 {
                    Rectangle()
                        .fill(accent.opacity(0.30))
                        .frame(width: 2, height: 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 27)
                }
            }
        }
        .padding(8)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct HouseplantTaxon: Identifiable, Hashable {
    let commonNameKey: String
    let scientificName: String
    let family: HouseplantFamily
    let aliases: [String]
    var legacyScientificNames: [String] = []

    var id: String { scientificName }
    var genus: String { scientificName.split(separator: " ").first.map(String.init) ?? scientificName }

    var searchTerms: [String] {
        [
            AppLocalization.string(commonNameKey),
            commonNameKey,
            scientificName,
            genus,
            family.latinName,
            family.orderName,
            AppLocalization.string(family.commonNameKey)
        ] + aliases + legacyScientificNames
    }

    func aliasesForDisplay(in language: AppLanguage) -> [String] {
        switch language {
        case .english:
            return aliases.filter { !$0.containsHanCharacter }
        case .simplifiedChinese:
            let localizedCommonName = AppLocalization.string(commonNameKey)
            let chineseAliases = aliases.filter {
                $0.containsHanCharacter && $0 != localizedCommonName
            }
            return legacyScientificNames + chineseAliases
        }
    }
}

private enum HouseplantFamily: String, CaseIterable, Identifiable {
    case araceae
    case asparagaceae
    case moraceae
    case marantaceae
    case piperaceae
    case urticaceae
    case begoniaceae
    case crassulaceae
    case cactaceae
    case arecaceae

    var id: Self { self }

    var latinName: String {
        switch self {
        case .araceae: "Araceae"
        case .asparagaceae: "Asparagaceae"
        case .moraceae: "Moraceae"
        case .marantaceae: "Marantaceae"
        case .piperaceae: "Piperaceae"
        case .urticaceae: "Urticaceae"
        case .begoniaceae: "Begoniaceae"
        case .crassulaceae: "Crassulaceae"
        case .cactaceae: "Cactaceae"
        case .arecaceae: "Arecaceae"
        }
    }

    var commonNameKey: String {
        switch self {
        case .araceae: "Aroid family"
        case .asparagaceae: "Asparagus family"
        case .moraceae: "Fig family"
        case .marantaceae: "Prayer plant family"
        case .piperaceae: "Pepper family"
        case .urticaceae: "Nettle family"
        case .begoniaceae: "Begonia family"
        case .crassulaceae: "Stonecrop family"
        case .cactaceae: "Cactus family"
        case .arecaceae: "Palm family"
        }
    }

    var orderName: String {
        switch self {
        case .araceae: "Alismatales"
        case .asparagaceae: "Asparagales"
        case .moraceae, .urticaceae: "Rosales"
        case .marantaceae: "Zingiberales"
        case .piperaceae: "Piperales"
        case .begoniaceae: "Cucurbitales"
        case .crassulaceae: "Saxifragales"
        case .cactaceae: "Caryophyllales"
        case .arecaceae: "Arecales"
        }
    }

    var summaryKey: String {
        switch self {
        case .araceae: "Aroids are a large tropical family that includes many familiar foliage plants."
        case .asparagaceae: "This broad family includes many tough, architectural houseplants once placed in separate families."
        case .moraceae: "The fig family includes woody tropical plants, many with milky sap and distinctive fruits."
        case .marantaceae: "Prayer plants are tropical herbs known for patterned leaves and daily leaf movement."
        case .piperaceae: "The pepper family includes compact tropical plants with fleshy leaves and slender flower spikes."
        case .urticaceae: "The nettle family ranges from stinging herbs to gentle tropical foliage plants such as Pilea."
        case .begoniaceae: "The begonia family is best known for asymmetrical leaves, colorful foliage, and showy flowers."
        case .crassulaceae: "Stonecrop relatives are succulents that store water in thick leaves and stems."
        case .cactaceae: "Cacti are American succulents with areoles—the small structures that produce spines, branches, or flowers."
        case .arecaceae: "True palms are flowering plants with a single growing point and leaves commonly divided into leaflets."
        }
    }

    var clueKey: String {
        switch self {
        case .araceae: "Look for a flower structure made of a central spike called a spadix, often wrapped by a leaflike spathe."
        case .asparagaceae: "Leaf shapes vary widely, but many members grow from rhizomes or thickened roots and tolerate seasonal dryness."
        case .moraceae: "Milky latex is common. Ficus plants often have woody stems and prominent leaf scars."
        case .marantaceae: "Leaves often unfold from sheathing stalks and may lift or fold as light changes."
        case .piperaceae: "Leaves are often fleshy, while tiny flowers gather on narrow upright spikes."
        case .urticaceae: "Leaves frequently show clear veins; Pilea species often have small, inconspicuous flowers."
        case .begoniaceae: "An uneven leaf base—one side larger than the other—is a classic begonia clue."
        case .crassulaceae: "Thick leaves, compact growth, and star-shaped flowers are common family traits."
        case .cactaceae: "Areoles distinguish true cacti from other spiny succulents."
        case .arecaceae: "New leaves emerge as folded spears from the crown; damage to the single growing point can be serious."
        }
    }

    var examplesKey: String {
        switch self {
        case .araceae: "Monstera, pothos, philodendron, peace lily, anthurium, ZZ plant, and Chinese evergreen."
        case .asparagaceae: "Snake plant, spider plant, corn plant, ponytail palm, asparagus fern, and yucca."
        case .moraceae: "Rubber plant, fiddle-leaf fig, weeping fig, edible fig, and mulberry."
        case .marantaceae: "Prayer plant, Goeppertia species often sold as calatheas, Ctenanthe, and Stromanthe."
        case .piperaceae: "Baby rubber plant, watermelon peperomia, ripple peperomia, and black pepper."
        case .urticaceae: "Chinese money plant, aluminum plant, artillery plant, and true nettles."
        case .begoniaceae: "Polka dot begonia, rex begonias, wax begonias, and cane begonias."
        case .crassulaceae: "Jade plant, flaming Katy, Echeveria, Sedum, and Aeonium."
        case .cactaceae: "Holiday cacti, ladyfinger cactus, golden barrel cactus, and prickly pears."
        case .arecaceae: "Parlor palm, kentia palm, areca palm, lady palm, and majesty palm."
        }
    }

    var noteKey: String {
        switch self {
        case .araceae: "The family relationship does not make every aroid safe to eat; many contain irritating calcium oxalate crystals."
        case .asparagaceae: "An old label may use Sansevieria for snake plants, but accepted classifications now place them in Dracaena."
        case .moraceae: "Milky sap can irritate skin, and plants within the family do not all share the same indoor care."
        case .marantaceae: "Many plants still carry Calathea on shop labels even when their accepted genus is Goeppertia."
        case .piperaceae: "Baby rubber plant is a Peperomia, not a close relative of the rubber plant in the fig family."
        case .urticaceae: "Not every member stings. Chinese money plant is a gentle member commonly grown indoors."
        case .begoniaceae: "Begonias differ greatly in leaf texture and growth habit, so identify the type before choosing care."
        case .crassulaceae: "Succulent leaves reduce water loss, but they do not mean the plant can live indefinitely without water."
        case .cactaceae: "Not every succulent is a cactus. Look for areoles rather than relying on spines alone."
        case .arecaceae: "Ponytail palm and sago palm are not true palms; they belong to entirely different plant groups."
        }
    }

    var icon: String {
        switch self {
        case .araceae: "leaf.fill"
        case .asparagaceae: "ruler.fill"
        case .moraceae: "tree.fill"
        case .marantaceae: "arrow.triangle.2.circlepath"
        case .piperaceae: "circle.grid.3x3.fill"
        case .urticaceae: "sparkles"
        case .begoniaceae: "heart.fill"
        case .crassulaceae: "drop.fill"
        case .cactaceae: "sun.max.fill"
        case .arecaceae: "tree.fill"
        }
    }

    var accent: Color {
        switch self {
        case .araceae: Color(red: 0.20, green: 0.60, blue: 0.37)
        case .asparagaceae: Color(red: 0.41, green: 0.56, blue: 0.22)
        case .moraceae: Color(red: 0.35, green: 0.48, blue: 0.24)
        case .marantaceae: Color(red: 0.55, green: 0.39, blue: 0.68)
        case .piperaceae: Color(red: 0.25, green: 0.60, blue: 0.58)
        case .urticaceae: Color(red: 0.32, green: 0.54, blue: 0.68)
        case .begoniaceae: Color(red: 0.86, green: 0.42, blue: 0.51)
        case .crassulaceae: Color(red: 0.30, green: 0.66, blue: 0.55)
        case .cactaceae: Color(red: 0.72, green: 0.49, blue: 0.22)
        case .arecaceae: Color(red: 0.21, green: 0.55, blue: 0.31)
        }
    }
}

private enum HouseplantTaxonomyCatalog {
    static let plants: [HouseplantTaxon] = [
        .init(commonNameKey: "Swiss cheese plant", scientificName: "Monstera deliciosa", family: .araceae, aliases: ["Monstera", "split-leaf philodendron", "龟背竹"]),
        .init(commonNameKey: "Golden pothos", scientificName: "Epipremnum aureum", family: .araceae, aliases: ["pothos", "devil’s ivy", "money plant", "绿萝", "黄金葛"]),
        .init(commonNameKey: "Heartleaf philodendron", scientificName: "Philodendron hederaceum", family: .araceae, aliases: ["sweetheart plant", "心叶蔓绿绒"]),
        .init(commonNameKey: "Peace lily", scientificName: "Spathiphyllum wallisii", family: .araceae, aliases: ["white sails", "白掌", "一帆风顺"]),
        .init(commonNameKey: "Flamingo flower", scientificName: "Anthurium andraeanum", family: .araceae, aliases: ["anthurium", "laceleaf", "红掌"]),
        .init(commonNameKey: "ZZ plant", scientificName: "Zamioculcas zamiifolia", family: .araceae, aliases: ["Zanzibar gem", "金钱树", "雪铁芋"]),
        .init(commonNameKey: "Chinese evergreen", scientificName: "Aglaonema commutatum", family: .araceae, aliases: ["Aglaonema", "广东万年青"]),

        .init(commonNameKey: "Snake plant", scientificName: "Dracaena trifasciata", family: .asparagaceae, aliases: ["Sansevieria trifasciata", "mother-in-law’s tongue", "虎尾兰"], legacyScientificNames: ["Sansevieria trifasciata"]),
        .init(commonNameKey: "Spider plant", scientificName: "Chlorophytum comosum", family: .asparagaceae, aliases: ["airplane plant", "吊兰"]),
        .init(commonNameKey: "Corn plant", scientificName: "Dracaena fragrans", family: .asparagaceae, aliases: ["mass cane", "巴西木", "香龙血树"]),
        .init(commonNameKey: "Ponytail palm", scientificName: "Beaucarnea recurvata", family: .asparagaceae, aliases: ["elephant-foot tree", "酒瓶兰"]),

        .init(commonNameKey: "Rubber plant", scientificName: "Ficus elastica", family: .moraceae, aliases: ["rubber fig", "橡皮树"]),
        .init(commonNameKey: "Fiddle-leaf fig", scientificName: "Ficus lyrata", family: .moraceae, aliases: ["banjo fig", "琴叶榕"]),
        .init(commonNameKey: "Weeping fig", scientificName: "Ficus benjamina", family: .moraceae, aliases: ["Benjamin fig", "垂叶榕"]),

        .init(commonNameKey: "Prayer plant", scientificName: "Maranta leuconeura", family: .marantaceae, aliases: ["praying hands", "竹芋"]),
        .init(commonNameKey: "Calathea orbifolia", scientificName: "Goeppertia orbifolia", family: .marantaceae, aliases: ["Calathea orbifolia", "圆叶竹芋", "青苹果竹芋"], legacyScientificNames: ["Calathea orbifolia"]),
        .init(commonNameKey: "Peacock plant", scientificName: "Goeppertia makoyana", family: .marantaceae, aliases: ["Calathea makoyana", "孔雀竹芋"], legacyScientificNames: ["Calathea makoyana"]),

        .init(commonNameKey: "Baby rubber plant", scientificName: "Peperomia obtusifolia", family: .piperaceae, aliases: ["pepper face", "豆瓣绿"]),
        .init(commonNameKey: "Watermelon peperomia", scientificName: "Peperomia argyreia", family: .piperaceae, aliases: ["watermelon begonia", "西瓜皮椒草"]),

        .init(commonNameKey: "Chinese money plant", scientificName: "Pilea peperomioides", family: .urticaceae, aliases: ["pancake plant", "UFO plant", "镜面草"]),
        .init(commonNameKey: "Polka dot begonia", scientificName: "Begonia maculata", family: .begoniaceae, aliases: ["trout begonia", "spotted begonia", "斑叶竹节秋海棠"]),

        .init(commonNameKey: "Jade plant", scientificName: "Crassula ovata", family: .crassulaceae, aliases: ["money tree", "friendship tree", "玉树"]),
        .init(commonNameKey: "Flaming Katy", scientificName: "Kalanchoe blossfeldiana", family: .crassulaceae, aliases: ["Christmas kalanchoe", "长寿花"]),

        .init(commonNameKey: "Thanksgiving cactus", scientificName: "Schlumbergera truncata", family: .cactaceae, aliases: ["crab cactus", "holiday cactus", "蟹爪兰"]),
        .init(commonNameKey: "Ladyfinger cactus", scientificName: "Mammillaria elongata", family: .cactaceae, aliases: ["gold lace cactus", "金手指"]),

        .init(commonNameKey: "Parlor palm", scientificName: "Chamaedorea elegans", family: .arecaceae, aliases: ["neanthe bella palm", "袖珍椰子"]),
        .init(commonNameKey: "Kentia palm", scientificName: "Howea forsteriana", family: .arecaceae, aliases: ["thatch palm", "肯氏椰子"])
    ]

    static let popular: [HouseplantTaxon] = [
        plants[0], plants[1], plants[7], plants[11], plants[15], plants[19]
    ]
}

private extension String {
    var searchNormalized: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var containsHanCharacter: Bool {
        unicodeScalars.contains { scalar in
            (0x3400...0x4DBF).contains(scalar.value) ||
                (0x4E00...0x9FFF).contains(scalar.value)
        }
    }
}
