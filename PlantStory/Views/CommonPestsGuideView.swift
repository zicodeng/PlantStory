import SwiftUI

struct CommonPestsGuideView: View {
    @State private var selectedPest: CommonPlantPest?

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)
    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let amber = Color(red: 0.91, green: 0.58, blue: 0.15)
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
                    firstStep

                    Text("Choose a pest")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(ink)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(CommonPlantPest.allCases) { pest in
                            Button {
                                selectedPest = pest
                            } label: {
                                pestCard(pest)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens signs and next steps")
                        }
                    }

                    Label {
                        Text("Identify the pest before treating. Different problems can leave similar marks on a plant.")
                    } icon: {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(amber)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Common pests")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPest) { pest in
            CommonPestDetailView(pest: pest)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("PEST FIELD GUIDE", systemImage: "ladybug.fill")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.34))

            Text("Know what you’re looking at.")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Learn the visual clues of common houseplant pests and what to check next.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(forest, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var firstStep: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.left.and.right.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(amber)
                .frame(width: 42, height: 42)
                .background(amber.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("First step")
                    .font(.headline)
                    .foregroundStyle(ink)

                Text("Move the plant away from others, then inspect it in bright light.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func pestCard(_ pest: CommonPlantPest) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(pest.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 116)
                .padding(8)
                .background(pest.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityHidden(true)

            Text(LocalizedStringKey(pest.titleKey))
                .font(.headline)
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(LocalizedStringKey(pest.cardClueKey))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Image(systemName: "arrow.right.circle.fill")
                .font(.subheadline)
                .foregroundStyle(pest.accent)
        }
        .frame(maxWidth: .infinity, minHeight: 228, alignment: .topLeading)
        .padding(14)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct CommonPestDetailView: View {
    let pest: CommonPlantPest

    @Environment(\.dismiss) private var dismiss

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Canvas").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        detailRow(
                            title: "What you might notice",
                            textKey: pest.signsKey,
                            icon: "eye.fill"
                        )

                        detailRow(
                            title: "Where to look",
                            textKey: pest.locationKey,
                            icon: "magnifyingglass"
                        )

                        detailRow(
                            title: "What to do now",
                            textKey: pest.actionKey,
                            icon: "checklist"
                        )

                        detailRow(
                            title: "Help prevent it",
                            textKey: pest.preventionKey,
                            icon: "shield.lefthalf.filled"
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Treat carefully", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundStyle(ink)

                            Text("Before using any pest-control product, confirm it is labeled for indoor use and for your plant. Follow the label and test a small area first.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .background(pest.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
            Image(pest.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .padding(14)
                .background(pest.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .accessibilityHidden(true)

            Label("COMMON PEST", systemImage: "ladybug.fill")
                .font(.caption.weight(.bold))
                .tracking(1.3)
                .foregroundStyle(pest.accent)

            Text(LocalizedStringKey(pest.titleKey))
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(ink)
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
                .foregroundStyle(pest.accent)
                .frame(width: 42, height: 42)
                .background(pest.accent.opacity(0.12), in: Circle())

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

private enum CommonPlantPest: String, CaseIterable, Identifiable {
    case spiderMites
    case mealybugs
    case scale
    case aphids
    case fungusGnats
    case thrips

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .spiderMites: "Spider mites"
        case .mealybugs: "Mealybugs"
        case .scale: "Scale insects"
        case .aphids: "Aphids"
        case .fungusGnats: "Fungus gnats"
        case .thrips: "Thrips"
        }
    }

    var imageName: String {
        switch self {
        case .spiderMites: "PlantPestSpiderMites"
        case .mealybugs: "PlantPestMealybugs"
        case .scale: "PlantPestScale"
        case .aphids: "PlantPestAphids"
        case .fungusGnats: "PlantPestFungusGnats"
        case .thrips: "PlantPestThrips"
        }
    }

    var accent: Color {
        switch self {
        case .spiderMites: Color(red: 0.87, green: 0.38, blue: 0.28)
        case .mealybugs: Color(red: 0.42, green: 0.57, blue: 0.72)
        case .scale: Color(red: 0.64, green: 0.43, blue: 0.25)
        case .aphids: Color(red: 0.39, green: 0.69, blue: 0.20)
        case .fungusGnats: Color(red: 0.45, green: 0.39, blue: 0.56)
        case .thrips: Color(red: 0.83, green: 0.57, blue: 0.17)
        }
    }

    var cardClueKey: String {
        switch self {
        case .spiderMites: "Fine webbing and pale speckles"
        case .mealybugs: "White, cottony clusters"
        case .scale: "Brown bumps fixed to stems"
        case .aphids: "Clusters on tender new growth"
        case .fungusGnats: "Tiny dark flies near soil"
        case .thrips: "Silver streaks and black specks"
        }
    }

    var signsKey: String {
        switch self {
        case .spiderMites: "Leaves develop many tiny pale dots, then may look bronze or dry. Fine webbing can appear when numbers grow."
        case .mealybugs: "White cottony insects collect in plant joints. Leaves may yellow, and the plant can feel sticky from honeydew."
        case .scale: "Small tan or brown shell-like bumps stay fixed in place. Sticky honeydew, yellow leaves, or weak growth may follow."
        case .aphids: "Soft green, brown, or black insects crowd around new growth. Young leaves may curl, and white shed skins or sticky honeydew may appear."
        case .fungusGnats: "Tiny dark flies run across or hover above damp potting mix. Adults are mostly a nuisance, but larvae live in the mix and may harm roots when numerous."
        case .thrips: "Leaves or flowers develop silvery scraped patches, streaks, distortion, or tiny black specks. The insects are narrow and difficult to see."
        }
    }

    var locationKey: String {
        switch self {
        case .spiderMites: "Check leaf undersides, growing tips, and the joints where leaves meet stems. Use bright light to spot webbing."
        case .mealybugs: "Look in leaf axils, along stems and veins, under leaves, and around tight crevices near the pot rim."
        case .scale: "Inspect stems, leaf veins, and leaf undersides. Compare suspicious bumps with normal stem texture."
        case .aphids: "Inspect curled young leaves, buds, tender stems, and leaf undersides. Ants or sticky surfaces can be extra clues."
        case .fungusGnats: "Watch the soil surface and nearby leaves after watering. A yellow sticky card near the pot can help confirm flying adults."
        case .thrips: "Look under leaves, inside flowers, around buds, and in tight folds. Check damaged areas for slender insects and black specks."
        }
    }

    var actionKey: String {
        switch self {
        case .spiderMites: "Isolate the plant. Rinse leaves thoroughly, especially underneath, wipe away webbing, and inspect again every few days."
        case .mealybugs: "Isolate the plant. Remove visible insects with a damp cotton swab, rinse sturdy leaves, and repeat checks because hidden bugs can return."
        case .scale: "Isolate the plant. Gently wipe or lift off visible scale if the plant tolerates it, and prune heavily infested growth."
        case .aphids: "Isolate the plant. Wash aphids off with water and remove badly infested tips. Repeat the inspection as new growth opens."
        case .fungusGnats: "Let the top layer of mix dry as much as the plant safely allows, clear decaying debris, and use sticky cards to reduce and monitor adults."
        case .thrips: "Isolate the plant. Rinse foliage, remove badly damaged flowers or leaves, and repeat close inspections because thrips hide in crevices."
        }
    }

    var preventionKey: String {
        switch self {
        case .spiderMites: "Inspect leaves weekly, clean dusty foliage, and avoid letting the plant remain severely dry or stressed."
        case .mealybugs: "Quarantine new plants for several weeks and inspect every joint before placing them with your collection."
        case .scale: "Check stems and leaf undersides before buying or bringing a plant indoors, then quarantine new arrivals."
        case .aphids: "Inspect tender growth often and quarantine new plants, cuttings, or plants returning from outdoors."
        case .fungusGnats: "Avoid keeping potting mix constantly wet. Use drainage holes and remove fallen leaves from the soil surface."
        case .thrips: "Quarantine new plants and inspect flowers, buds, and leaf undersides before adding them to your collection."
        }
    }
}
