import SwiftUI

struct PlantWikiView: View {
    @State private var path: [AnatomyLesson] = []

    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let panel = Color(red: 0.105, green: 0.31, blue: 0.19)
    private let lime = Color(red: 0.36, green: 0.82, blue: 0.12)
    private let coral = Color(red: 0.96, green: 0.43, blue: 0.36)

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                forest.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        Text("Explore guides")
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .foregroundStyle(.white)

                        VStack(spacing: 14) {
                            NavigationLink {
                                PlantAnatomyLibraryView()
                            } label: {
                                guideRow(
                                    title: "Plant anatomy",
                                    subtitle: "Learn about roots, stems, leaves, and flowers.",
                                    icon: "leaf.fill",
                                    accent: lime
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the plant anatomy guides")

                            NavigationLink {
                                PlantProblemGuideView()
                            } label: {
                                guideRow(
                                    title: "Visual problem guide",
                                    subtitle: "Understand symptoms and what to check first.",
                                    icon: "magnifyingglass",
                                    accent: coral
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the visual plant problem guide")

                            NavigationLink {
                                LeafShapesPatternsView()
                            } label: {
                                guideRow(
                                    title: "Leaf shapes & patterns",
                                    subtitle: "Learn the clues that help describe and identify leaves.",
                                    icon: "camera.macro",
                                    accent: Color(red: 0.18, green: 0.76, blue: 0.78)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the leaf shapes and patterns guide")

                            NavigationLink {
                                CommonPestsGuideView()
                            } label: {
                                guideRow(
                                    title: "Common pests",
                                    subtitle: "Recognize common houseplant pests and learn what to check.",
                                    icon: "ladybug.fill",
                                    accent: Color(red: 0.96, green: 0.67, blue: 0.20)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the common pests guide")

                            NavigationLink {
                                RootsRepottingGuideView()
                            } label: {
                                guideRow(
                                    title: "Roots & repotting",
                                    subtitle: "Read root health, choose a pot, and repot with confidence.",
                                    icon: "arrow.triangle.2.circlepath",
                                    accent: Color(red: 0.78, green: 0.46, blue: 0.27)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the roots and repotting guide")

                            NavigationLink {
                                WateringBasicsGuideView()
                            } label: {
                                guideRow(
                                    title: "Watering basics",
                                    subtitle: "Learn when to water, how to check the pot, and what changes the schedule.",
                                    icon: "drop.fill",
                                    accent: Color(red: 0.32, green: 0.72, blue: 0.95)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the watering basics guide")

                            NavigationLink {
                                LightMadeSimpleGuideView()
                            } label: {
                                guideRow(
                                    title: "Light Made Simple",
                                    subtitle: "Understand indoor light, read plant signals, and find a better spot.",
                                    icon: "sun.max.fill",
                                    accent: Color(red: 1.00, green: 0.84, blue: 0.22)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the Light Made Simple guide")

                            NavigationLink {
                                NewGrowthLifeStagesGuideView()
                            } label: {
                                guideRow(
                                    title: "New Growth & Life Stages",
                                    subtitle: "Follow a leaf from growth point to maturity and learn which changes are normal.",
                                    icon: "sparkles",
                                    accent: Color(red: 0.93, green: 0.46, blue: 0.68)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the new growth and life stages guide")

                            NavigationLink {
                                PropagationBasicsGuideView()
                            } label: {
                                guideRow(
                                    title: "Propagation Basics",
                                    subtitle: "Choose the right method, start a healthy cutting, and care for new roots.",
                                    icon: "point.3.connected.trianglepath.dotted",
                                    accent: Color(red: 0.43, green: 0.55, blue: 0.94)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the propagation basics guide")

                            NavigationLink {
                                PlantTaxonomyGuideView()
                            } label: {
                                guideRow(
                                    title: "Plant Families & Taxonomy",
                                    subtitle: "Explore major plant groups and learn how scientific names fit together.",
                                    icon: "tree.fill",
                                    accent: Color(red: 0.69, green: 0.45, blue: 0.90)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the plant families and taxonomy guide")
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AnatomyLesson.self) { lesson in
                AnatomyLessonView(lesson: lesson)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("PLANT WIKI", systemImage: "book.pages.fill")
                .font(.caption.weight(.bold))
                .tracking(1.8)
                .foregroundStyle(lime)

            Text("Understand your plants.")
                .font(.system(.largeTitle, design: .serif, weight: .medium))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Learn how plants work, spot common problems, and care with confidence.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func guideRow(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        icon: String,
        accent: Color
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 50, height: 50)
                .background(accent.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(16)
        .background(panel, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct PlantAnatomyLibraryView: View {
    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Choose a view to learn how each part helps a plant grow.")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(ink)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 14) {
                        ForEach(AnatomyLesson.allCases) { lesson in
                            lessonRow(lesson)
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Plant anatomy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func lessonRow(_ lesson: AnatomyLesson) -> some View {
        NavigationLink(value: lesson) {
            HStack(spacing: 16) {
                Image(lesson.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .padding(8)
                    .background(lesson.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(LocalizedStringKey(lesson.titleKey))
                        .font(.headline)
                        .foregroundStyle(ink)

                    Text(LocalizedStringKey(lesson.subtitleKey))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private enum AnatomyLesson: String, CaseIterable, Identifiable, Hashable {
    case wholePlant
    case root
    case leaf
    case flower

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .wholePlant: "Whole plant"
        case .root: "Root close-up"
        case .leaf: "Leaf close-up"
        case .flower: "Flower close-up"
        }
    }

    var subtitleKey: String {
        switch self {
        case .wholePlant: "Start with the structures you can see from roots to flower."
        case .root: "Explore how roots anchor a plant, absorb water, and keep growing."
        case .leaf: "Look closely at how a leaf is built to collect light."
        case .flower: "Explore the parts a flower uses to make seeds."
        }
    }

    var instructionKey: String {
        switch self {
        case .wholePlant: "Tap a dot to discover each part of the plant."
        case .root: "Tap a dot to explore a healthy root system."
        case .leaf: "Tap a dot to explore the structures of a leaf."
        case .flower: "Tap a dot to look inside a flower."
        }
    }

    var imageName: String {
        switch self {
        case .wholePlant: "PlantAnatomyWhole"
        case .root: "PlantAnatomyRoot"
        case .leaf: "PlantAnatomyLeaf"
        case .flower: "PlantAnatomyFlower"
        }
    }

    var imageAspectRatio: CGFloat {
        switch self {
        case .wholePlant: 1122 / 1402
        case .root: 1240 / 1269
        case .leaf: 1448 / 1086
        case .flower: 1
        }
    }

    var accent: Color {
        switch self {
        case .wholePlant: Color(red: 0.36, green: 0.82, blue: 0.12)
        case .root: Color(red: 0.72, green: 0.45, blue: 0.24)
        case .leaf: Color(red: 0.18, green: 0.68, blue: 0.48)
        case .flower: Color(red: 0.96, green: 0.43, blue: 0.36)
        }
    }

    var parts: [AnatomyPart] {
        switch self {
        case .wholePlant: AnatomyPart.wholePlantParts
        case .root: AnatomyPart.rootParts
        case .leaf: AnatomyPart.leafParts
        case .flower: AnatomyPart.flowerParts
        }
    }
}

private struct AnatomyPart: Identifiable {
    let id: String
    let titleKey: String
    let pronunciationKey: String?
    let functionKey: String
    let spottingKey: String
    let importanceKey: String
    let position: CGPoint
}

private extension AnatomyPart {
    static let roots = AnatomyPart(
        id: "roots",
        titleKey: "Roots",
        pronunciationKey: nil,
        functionKey: "Roots anchor the plant and absorb water and dissolved minerals from the growing medium.",
        spottingKey: "They usually branch below the soil, with fine roots spreading from thicker ones.",
        importanceKey: "Healthy roots are usually firm. Dark, mushy roots can be a sign of rot.",
        position: CGPoint(x: 0.52, y: 0.84)
    )

    static let stem = AnatomyPart(
        id: "stem",
        titleKey: "Stem",
        pronunciationKey: nil,
        functionKey: "The stem supports the plant and carries water and sugars between roots and leaves.",
        spottingKey: "Find the main upright structure that leaves, buds, and branches grow from.",
        importanceKey: "A soft or discolored stem can point to damage, disease, or excess moisture.",
        position: CGPoint(x: 0.51, y: 0.63)
    )

    static let node = AnatomyPart(
        id: "node",
        titleKey: "Node",
        pronunciationKey: nil,
        functionKey: "A node is a growth point where a leaf, bud, branch, or root can emerge.",
        spottingKey: "Look for a joint or slight ring where a leaf meets the main stem.",
        importanceKey: "Many stem cuttings need at least one node before they can produce new growth.",
        position: CGPoint(x: 0.51, y: 0.50)
    )

    static let internode = AnatomyPart(
        id: "internode",
        titleKey: "Internode",
        pronunciationKey: "IN-ter-nohd",
        functionKey: "The internode is the stretch of stem between two neighboring nodes.",
        spottingKey: "Trace the bare section of stem between two leaf attachment points.",
        importanceKey: "Unusually long internodes can be a clue that a plant needs more light.",
        position: CGPoint(x: 0.52, y: 0.42)
    )

    static let leaf = AnatomyPart(
        id: "leaf",
        titleKey: "Leaf",
        pronunciationKey: nil,
        functionKey: "Leaves capture light to make sugars and exchange gases with the air.",
        spottingKey: "Leaves are usually flat green structures growing from stems or branches.",
        importanceKey: "Changes in leaf color, shape, or firmness are often early signs of stress.",
        position: CGPoint(x: 0.27, y: 0.30)
    )

    static let petiole = AnatomyPart(
        id: "petiole",
        titleKey: "Petiole",
        pronunciationKey: "PET-ee-ohl",
        functionKey: "The petiole is the small stalk that connects a leaf blade to the stem.",
        spottingKey: "Follow a leaf inward until its narrow stalk reaches the main stem.",
        importanceKey: "Knowing the petiole helps you prune a leaf without mistaking it for the main stem.",
        position: CGPoint(x: 0.42, y: 0.33)
    )

    static let bud = AnatomyPart(
        id: "bud",
        titleKey: "Bud",
        pronunciationKey: nil,
        functionKey: "A bud contains undeveloped tissue that may become a shoot, leaf, or flower.",
        spottingKey: "Look for a small, tightly closed point near a node or at a stem tip.",
        importanceKey: "Protect active buds when pruning because they contain the plant's next growth.",
        position: CGPoint(x: 0.36, y: 0.13)
    )

    static let flower = AnatomyPart(
        id: "flower",
        titleKey: "Flower",
        pronunciationKey: nil,
        functionKey: "A flower contains structures that help the plant reproduce and form seeds.",
        spottingKey: "Flowers usually open from buds and may have colorful petals around their center.",
        importanceKey: "Removing spent flowers can redirect energy, but some plants need them to make seeds or fruit.",
        position: CGPoint(x: 0.68, y: 0.14)
    )

    static let rootCrown = AnatomyPart(
        id: "root-crown",
        titleKey: "Root crown",
        pronunciationKey: nil,
        functionKey: "The root crown is the transition point where the stem meets and branches into the root system.",
        spottingKey: "Find the slightly thickened area directly below the base of the stem.",
        importanceKey: "Keep the crown near the plant's original planting depth. Burying it too deeply can trap moisture.",
        position: CGPoint(x: 0.50, y: 0.21)
    )

    static let structuralRoot = AnatomyPart(
        id: "structural-root",
        titleKey: "Structural root",
        pronunciationKey: nil,
        functionKey: "Thick structural roots anchor the plant and form the framework that supports smaller roots.",
        spottingKey: "Trace one of the thick roots spreading away from the crown before it divides.",
        importanceKey: "A firm structural root supports the whole system. Soft or hollow sections may indicate damage or rot.",
        position: CGPoint(x: 0.52, y: 0.48)
    )

    static let lateralRoot = AnatomyPart(
        id: "lateral-root",
        titleKey: "Lateral root",
        pronunciationKey: "LAT-er-uhl root",
        functionKey: "Lateral roots branch from larger roots, expanding the area where the plant can find water and minerals.",
        spottingKey: "Look for medium-sized roots growing sideways from a thicker structural root.",
        importanceKey: "Healthy branching gives the plant more access to moisture while helping hold it securely in the pot.",
        position: CGPoint(x: 0.76, y: 0.43)
    )

    static let fineRoot = AnatomyPart(
        id: "fine-root",
        titleKey: "Fine root",
        pronunciationKey: nil,
        functionKey: "Fine roots are the small, delicate branches that do much of the root system's water and mineral uptake.",
        spottingKey: "Follow a lateral root outward to the thinnest branching roots near its ends.",
        importanceKey: "Fine roots dry out and become damaged faster than thick roots, so handle them gently when repotting.",
        position: CGPoint(x: 0.18, y: 0.57)
    )

    static let rootHairZone = AnatomyPart(
        id: "root-hair-zone",
        titleKey: "Root-hair zone",
        pronunciationKey: nil,
        functionKey: "Thousands of microscopic root hairs increase the surface area available to absorb water and dissolved minerals.",
        spottingKey: "On a very young root, this zone sits just behind the smooth growing tip and may look softly fuzzy.",
        importanceKey: "Root hairs are fragile and short-lived. New ones continually form as a healthy root grows through the potting mix.",
        position: CGPoint(x: 0.31, y: 0.75)
    )

    static let growingRootTip = AnatomyPart(
        id: "growing-root-tip",
        titleKey: "Growing root tip",
        pronunciationKey: nil,
        functionKey: "The growing tip lengthens the root, while a tiny root cap protects its tender cells as it moves through the potting mix.",
        spottingKey: "Look for a smooth, pale or cream-colored point at the end of a healthy young root.",
        importanceKey: "Fresh tips signal active growth. Avoid tearing or crushing them when loosening roots during repotting.",
        position: CGPoint(x: 0.76, y: 0.83)
    )

    static let blade = AnatomyPart(
        id: "blade",
        titleKey: "Leaf blade",
        pronunciationKey: nil,
        functionKey: "The blade is the broad, flat part of a leaf that captures most of its light.",
        spottingKey: "It is the main green surface extending outward from the petiole and midrib.",
        importanceKey: "Dust and damage on the blade can reduce how effectively the leaf uses light.",
        position: CGPoint(x: 0.70, y: 0.61)
    )

    static let midrib = AnatomyPart(
        id: "midrib",
        titleKey: "Midrib",
        pronunciationKey: "MID-rib",
        functionKey: "The midrib is the main central vein that supports the blade and moves materials through it.",
        spottingKey: "Look for the thick line running from the petiole toward the leaf tip.",
        importanceKey: "A damaged midrib can interrupt support and transport to a large part of the leaf.",
        position: CGPoint(x: 0.52, y: 0.57)
    )

    static let veins = AnatomyPart(
        id: "veins",
        titleKey: "Veins",
        pronunciationKey: nil,
        functionKey: "Veins carry water and sugars while forming a supportive network inside the leaf.",
        spottingKey: "They are the thinner lines branching outward from the central midrib.",
        importanceKey: "Vein patterns can help identify plants and reveal some nutrient or watering problems.",
        position: CGPoint(x: 0.62, y: 0.43)
    )

    static let margin = AnatomyPart(
        id: "margin",
        titleKey: "Leaf margin",
        pronunciationKey: "MAR-jin",
        functionKey: "The margin is the outer edge that defines the shape of the leaf blade.",
        spottingKey: "Trace the complete outside border of the leaf from its base to its tip.",
        importanceKey: "Smooth, toothed, or wavy margins are useful clues when identifying a plant.",
        position: CGPoint(x: 0.34, y: 0.29)
    )

    static let leafTip = AnatomyPart(
        id: "leaf-tip",
        titleKey: "Leaf tip",
        pronunciationKey: nil,
        functionKey: "The tip is the farthest point of the leaf blade from the petiole.",
        spottingKey: "Find the end of the leaf where its two margins meet.",
        importanceKey: "Brown tips often appear before the rest of the leaf shows moisture or salt stress.",
        position: CGPoint(x: 0.93, y: 0.10)
    )

    static let petal = AnatomyPart(
        id: "petal",
        titleKey: "Petal",
        pronunciationKey: "PET-uhl",
        functionKey: "Petals surround a flower's center and often help attract pollinators.",
        spottingKey: "Look for the broad, often colorful structures that open as the flower blooms.",
        importanceKey: "Petals are different from sepals, which protect the flower before it opens.",
        position: CGPoint(x: 0.22, y: 0.43)
    )

    static let sepal = AnatomyPart(
        id: "sepal",
        titleKey: "Sepal",
        pronunciationKey: "SEE-puhl",
        functionKey: "Sepals protect the developing flower bud before the petals open.",
        spottingKey: "Find the small green, leaflike structures directly behind or beneath the petals.",
        importanceKey: "Sepals can look like leaves, but their position beneath the flower identifies them.",
        position: CGPoint(x: 0.27, y: 0.78)
    )

    static let stamen = AnatomyPart(
        id: "stamen",
        titleKey: "Stamen",
        pronunciationKey: "STAY-men",
        functionKey: "The stamen is the pollen-producing structure made of a filament and an anther.",
        spottingKey: "Look for several slender stalks arranged around the central pistil.",
        importanceKey: "Recognizing stamens helps explain where pollen comes from during flowering.",
        position: CGPoint(x: 0.37, y: 0.47)
    )

    static let anther = AnatomyPart(
        id: "anther",
        titleKey: "Anther",
        pronunciationKey: "AN-thur",
        functionKey: "The anther is the pollen-bearing tip of a stamen.",
        spottingKey: "Find the yellow or dusty-looking shape at the end of each slender filament.",
        importanceKey: "Loose pollen near anthers is usually a normal part of flowering, not a pest.",
        position: CGPoint(x: 0.37, y: 0.31)
    )

    static let stigma = AnatomyPart(
        id: "stigma",
        titleKey: "Stigma",
        pronunciationKey: "STIG-muh",
        functionKey: "The stigma is the receptive tip of the pistil where pollen can land.",
        spottingKey: "Look at the top of the central structure, often above the surrounding anthers.",
        importanceKey: "A receptive stigma allows pollination to begin when compatible pollen reaches it.",
        position: CGPoint(x: 0.50, y: 0.25)
    )

    static let style = AnatomyPart(
        id: "style",
        titleKey: "Style",
        pronunciationKey: nil,
        functionKey: "The style is the stalk connecting the stigma to the ovary below.",
        spottingKey: "Follow the central structure downward from the stigma toward the flower base.",
        importanceKey: "After pollination, pollen tubes can grow through the style toward the ovules.",
        position: CGPoint(x: 0.50, y: 0.43)
    )

    static let ovary = AnatomyPart(
        id: "ovary",
        titleKey: "Ovary",
        pronunciationKey: "OH-vuh-ree",
        functionKey: "The ovary is the swollen flower structure that holds one or more ovules.",
        spottingKey: "Find it at the base of the pistil, below the style and stigma.",
        importanceKey: "After successful pollination, the ovary of many plants develops into a fruit.",
        position: CGPoint(x: 0.45, y: 0.62)
    )

    static let ovule = AnatomyPart(
        id: "ovule",
        titleKey: "Ovule",
        pronunciationKey: "OV-yool",
        functionKey: "An ovule is a small structure inside the ovary that can develop into a seed.",
        spottingKey: "In a cutaway flower, ovules appear as small pale shapes inside the ovary.",
        importanceKey: "Each fertilized ovule may become a seed that can grow into a new plant.",
        position: CGPoint(x: 0.55, y: 0.70)
    )

    static let wholePlantParts: [AnatomyPart] = [
        roots, stem, node, internode, leaf, petiole, bud, flower
    ]

    static let rootParts: [AnatomyPart] = [
        rootCrown, structuralRoot, lateralRoot, fineRoot, rootHairZone, growingRootTip
    ]

    static let leafParts: [AnatomyPart] = [
        blade,
        midrib,
        veins,
        margin,
        leafTip,
        AnatomyPart(
            id: petiole.id,
            titleKey: petiole.titleKey,
            pronunciationKey: petiole.pronunciationKey,
            functionKey: petiole.functionKey,
            spottingKey: petiole.spottingKey,
            importanceKey: petiole.importanceKey,
            position: CGPoint(x: 0.13, y: 0.88)
        )
    ]

    static let flowerParts: [AnatomyPart] = [
        petal, sepal, stamen, anther, stigma, style, ovary, ovule
    ]
}

private struct AnatomyLessonView: View {
    let lesson: AnatomyLesson

    @State private var selectedPart: AnatomyPart? = nil

    private let warmPaper = Color(red: 0.98, green: 0.91, blue: 0.76)
    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedStringKey(lesson.titleKey))
                            .font(.system(.largeTitle, design: .serif, weight: .semibold))
                            .foregroundStyle(ink)
                        Text(LocalizedStringKey(lesson.instructionKey))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    anatomyDiagram

                    Text("Choose any dot. You can revisit a part whenever you like.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(Text(LocalizedStringKey(lesson.titleKey)))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedPart = nil
        }
        .sheet(item: $selectedPart) { part in
            AnatomyPartSheet(part: part, accent: lesson.accent)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var anatomyDiagram: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(warmPaper)

                Image(lesson.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(16)
                    .accessibilityHidden(true)

                ForEach(lesson.parts) { part in
                    Button {
                        selectedPart = part
                    } label: {
                        AnatomyHotspot(accent: lesson.accent)
                    }
                    .buttonStyle(.plain)
                    .position(
                        x: geometry.size.width * part.position.x,
                        y: geometry.size.height * part.position.y
                    )
                    .accessibilityLabel(Text(LocalizedStringKey(part.titleKey)))
                    .accessibilityHint("Shows what this plant part does")
                }
            }
        }
        .aspectRatio(lesson.imageAspectRatio, contentMode: .fit)
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }

}

private struct AnatomyHotspot: View {
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
            Circle()
                .stroke(accent, lineWidth: 2.5)

            Circle()
                .fill(accent)
                .frame(width: 7, height: 7)
        }
        .frame(width: 26, height: 26)
        .frame(width: 44, height: 44)
        .contentShape(Circle())
    }
}

private struct AnatomyPartSheet: View {
    let part: AnatomyPart
    let accent: Color

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var appLanguageCode = AppLanguage.english.rawValue

    private var showsPronunciation: Bool {
        AppLanguage(rawValue: appLanguageCode) == .english
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 5) {
                        Label("PLANT PART", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(accent)

                        Text(LocalizedStringKey(part.titleKey))
                            .font(.system(.largeTitle, design: .serif, weight: .semibold))

                        if showsPronunciation, let pronunciationKey = part.pronunciationKey {
                            Text(pronunciationKey)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    informationCard(
                        title: "What it does",
                        icon: "leaf.fill",
                        bodyKey: part.functionKey
                    )
                    informationCard(
                        title: "How to spot it",
                        icon: "eye.fill",
                        bodyKey: part.spottingKey
                    )
                    informationCard(
                        title: "Why it matters",
                        icon: "heart.fill",
                        bodyKey: part.importanceKey
                    )
                }
                .padding(20)
                .padding(.bottom, 20)
            }
            .background(Color("Canvas"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func informationCard(
        title: LocalizedStringKey,
        icon: String,
        bodyKey: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 34, height: 34)
                .background(accent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(LocalizedStringKey(bodyKey))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
