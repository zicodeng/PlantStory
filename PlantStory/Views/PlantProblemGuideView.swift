import SwiftUI

struct PlantProblemGuideView: View {
    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)
    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    introCard

                    Text("Choose a symptom")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(ink)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(PlantSymptom.allCases) { symptom in
                            NavigationLink {
                                PlantSymptomDetailView(symptom: symptom)
                            } label: {
                                symptomCard(symptom)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens possible causes and checks")
                        }
                    }

                    Label {
                        Text("A symptom is a clue, not a diagnosis. Check the soil, light, roots, and leaves before changing care.")
                    } icon: {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Color("LeafGreen"))
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
        .navigationTitle("Plant problem guide")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("VISUAL CHECK", systemImage: "eye.fill")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(Color(red: 0.72, green: 0.91, blue: 0.51))

            Text("What is your plant showing?")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Start with the change you can see. We’ll help you decide what to inspect next.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(forest, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func symptomCard(_ symptom: PlantSymptom) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symptom.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(symptom.accent)
                .frame(width: 44, height: 44)
                .background(symptom.accent.opacity(0.14), in: Circle())

            Text(LocalizedStringKey(symptom.titleKey))
                .font(.headline)
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(LocalizedStringKey(symptom.cardDescriptionKey))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Image(systemName: "arrow.right.circle.fill")
                .font(.subheadline)
                .foregroundStyle(symptom.accent)
        }
        .frame(maxWidth: .infinity, minHeight: 164, alignment: .topLeading)
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct PlantSymptomDetailView: View {
    let symptom: PlantSymptom

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    symptomHeader

                    guideSection(title: "Common causes", icon: "magnifyingglass") {
                        VStack(spacing: 12) {
                            ForEach(symptom.causes) { cause in
                                causeCard(cause)
                            }
                        }
                    }

                    guideSection(title: "Check first", icon: "checklist") {
                        VStack(spacing: 0) {
                            ForEach(Array(symptom.checks.enumerated()), id: \.offset) { index, check in
                                checkRow(number: index + 1, textKey: check)

                                if index < symptom.checks.count - 1 {
                                    Divider()
                                        .padding(.leading, 48)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Keep in mind", systemImage: "leaf.fill")
                            .font(.headline)
                            .foregroundStyle(ink)

                        Text("Change one thing at a time, then give the plant time to respond. Several different problems can create the same symptom.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .background(symptom.accent.opacity(0.11), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(Text(LocalizedStringKey(symptom.titleKey)))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var symptomHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symptom.icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(symptom.accent)
                .frame(width: 62, height: 62)
                .background(symptom.accent.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text("VISIBLE SYMPTOM")
                    .font(.caption.weight(.bold))
                    .tracking(1.3)
                    .foregroundStyle(symptom.accent)

                Text(LocalizedStringKey(symptom.titleKey))
                    .font(.system(.title, design: .serif, weight: .semibold))
                    .foregroundStyle(ink)

                Text(LocalizedStringKey(symptom.summaryKey))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
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

    private func causeCard(_ cause: ProblemCause) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(symptom.accent)
                .frame(width: 8, height: 8)
                .padding(.top, 7)

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(cause.titleKey))
                    .font(.headline)
                    .foregroundStyle(ink)

                Text(LocalizedStringKey(cause.explanationKey))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func checkRow(number: Int, textKey: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(symptom.accent, in: Circle())

            Text(LocalizedStringKey(textKey))
                .font(.subheadline)
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 14)
    }
}

private struct ProblemCause: Identifiable {
    let titleKey: String
    let explanationKey: String

    var id: String { titleKey }
}

private enum PlantSymptom: String, CaseIterable, Identifiable {
    case yellowLeaves
    case brownTips
    case drooping
    case leafSpots
    case curlingLeaves
    case droppingLeaves

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .yellowLeaves: "Yellow leaves"
        case .brownTips: "Brown tips"
        case .drooping: "Drooping"
        case .leafSpots: "Leaf spots"
        case .curlingLeaves: "Curling leaves"
        case .droppingLeaves: "Dropping leaves"
        }
    }

    var cardDescriptionKey: String {
        switch self {
        case .yellowLeaves: "Pale or yellowing foliage"
        case .brownTips: "Dry, dark leaf edges"
        case .drooping: "Soft or hanging leaves"
        case .leafSpots: "Dark, pale, or wet marks"
        case .curlingLeaves: "Edges rolling inward or out"
        case .droppingLeaves: "Leaves falling unexpectedly"
        }
    }

    var summaryKey: String {
        switch self {
        case .yellowLeaves: "Leaves are turning pale or yellow on one part of the plant or across the whole plant."
        case .brownTips: "Leaf tips or edges are becoming dry, crisp, and brown."
        case .drooping: "Leaves and stems are hanging lower than usual or feel soft and limp."
        case .leafSpots: "Leaves have distinct dark, pale, yellow, or water-soaked patches."
        case .curlingLeaves: "Leaf edges are rolling, cupping, or twisting away from their usual shape."
        case .droppingLeaves: "The plant is losing more leaves than usual, sometimes while they are still green."
        }
    }

    var icon: String {
        switch self {
        case .yellowLeaves: "leaf.fill"
        case .brownTips: "flame.fill"
        case .drooping: "arrow.down.circle.fill"
        case .leafSpots: "circle.grid.3x3.fill"
        case .curlingLeaves: "arrow.triangle.2.circlepath"
        case .droppingLeaves: "wind"
        }
    }

    var accent: Color {
        switch self {
        case .yellowLeaves: Color(red: 0.78, green: 0.64, blue: 0.05)
        case .brownTips: Color(red: 0.69, green: 0.35, blue: 0.18)
        case .drooping: Color(red: 0.18, green: 0.49, blue: 0.72)
        case .leafSpots: Color(red: 0.77, green: 0.28, blue: 0.26)
        case .curlingLeaves: Color(red: 0.47, green: 0.34, blue: 0.68)
        case .droppingLeaves: Color(red: 0.22, green: 0.59, blue: 0.43)
        }
    }

    var causes: [ProblemCause] {
        switch self {
        case .yellowLeaves:
            [
                ProblemCause(titleKey: "Too much water", explanationKey: "Constantly wet soil can reduce oxygen around the roots and cause leaves to yellow."),
                ProblemCause(titleKey: "Natural aging", explanationKey: "An older lower leaf may yellow and fall while the rest of the plant remains healthy."),
                ProblemCause(titleKey: "Light or nutrient stress", explanationKey: "Too little light or a lasting nutrient shortage can cause broader yellowing.")
            ]
        case .brownTips:
            [
                ProblemCause(titleKey: "Dry soil or air", explanationKey: "Long dry periods or very dry air can leave delicate leaf tips crisp."),
                ProblemCause(titleKey: "Mineral or fertilizer buildup", explanationKey: "Salts left by tap water or excess fertilizer can collect in soil and damage leaf edges."),
                ProblemCause(titleKey: "Root stress", explanationKey: "Damaged, crowded, or unhealthy roots may struggle to deliver water evenly to each leaf.")
            ]
        case .drooping:
            [
                ProblemCause(titleKey: "Needs water", explanationKey: "Dry soil can reduce water pressure inside leaves and stems, making them hang."),
                ProblemCause(titleKey: "Too much water", explanationKey: "Soggy soil can damage roots, so the plant may droop even when the pot is wet."),
                ProblemCause(titleKey: "Heat or intense light", explanationKey: "A plant may temporarily droop when it loses water faster than its roots can replace it.")
            ]
        case .leafSpots:
            [
                ProblemCause(titleKey: "Moisture and low airflow", explanationKey: "Wet leaves and still air can encourage some fungal or bacterial problems."),
                ProblemCause(titleKey: "Sun scorch", explanationKey: "A sudden move into strong direct light can leave pale, tan, or brown damaged patches."),
                ProblemCause(titleKey: "Pests or physical damage", explanationKey: "Feeding insects, rubbing, or bruising can leave scattered marks that resemble disease.")
            ]
        case .curlingLeaves:
            [
                ProblemCause(titleKey: "Water stress", explanationKey: "Both very dry and persistently wet soil can cause leaves to curl."),
                ProblemCause(titleKey: "Heat or dry air", explanationKey: "Leaves may curl to reduce moisture loss in hot or low-humidity conditions."),
                ProblemCause(titleKey: "Hidden pests", explanationKey: "Small pests often feed along leaf undersides or new growth and distort the leaf as it opens.")
            ]
        case .droppingLeaves:
            [
                ProblemCause(titleKey: "A sudden change", explanationKey: "A move, cold draft, heat source, or sharp light change can trigger leaf drop."),
                ProblemCause(titleKey: "Water or root stress", explanationKey: "A very dry root ball or damaged roots can make a plant shed leaves."),
                ProblemCause(titleKey: "Season or natural aging", explanationKey: "Some plants regularly lose older leaves or slow their growth as conditions change.")
            ]
        }
    }

    var checks: [String] {
        switch self {
        case .yellowLeaves:
            [
                "Feel the soil below the surface before watering again.",
                "Check whether yellowing is limited to older lower leaves or is spreading.",
                "Compare the plant’s current light with the conditions it normally prefers."
            ]
        case .brownTips:
            [
                "Check whether the soil has been staying dry for long periods.",
                "Look for a white mineral crust on the soil or around the pot.",
                "Inspect visible roots and confirm that excess water can drain from the pot."
            ]
        case .drooping:
            [
                "Feel the soil first; do not assume every drooping plant needs water.",
                "Notice whether the pot is unusually light, heavy, hot, or cold.",
                "Move the plant away from harsh midday sun or a strong draft while it recovers."
            ]
        case .leafSpots:
            [
                "Inspect both sides of several leaves with bright light.",
                "Check whether spots are dry and bleached or soft and spreading.",
                "Keep affected leaves dry and give the plant space for air to move around it."
            ]
        case .curlingLeaves:
            [
                "Check soil moisture at root depth rather than only at the surface.",
                "Inspect curled edges, leaf undersides, and new growth for tiny pests or webbing.",
                "Look for nearby heaters, vents, or intense sunlight that may be drying the plant."
            ]
        case .droppingLeaves:
            [
                "Think about any recent move or change in temperature, light, or watering.",
                "Check fallen leaves for yellowing, spots, pests, or soft tissue.",
                "Inspect soil moisture and roots before changing the watering schedule."
            ]
        }
    }
}
