import SwiftUI

struct WateringBasicsGuideView: View {
    @State private var selectedMoisture: MoistureCheck?

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)
    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let blue = Color(red: 0.12, green: 0.55, blue: 0.82)

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    intro

                    guideSection(title: "Check before you water", icon: "hand.point.up.left.fill") {
                        VStack(spacing: 12) {
                            ForEach(MoistureCheck.allCases) { moisture in
                                Button {
                                    selectedMoisture = moisture
                                } label: {
                                    moistureRow(moisture)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens moisture check details")
                            }
                        }

                        Text("These are starting points, not universal rules. Learn how much drying your plant species prefers.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    guideSection(title: "Water thoroughly", icon: "drop.fill") {
                        VStack(spacing: 0) {
                            ForEach(Array(WateringStep.allCases.enumerated()), id: \.element) { index, step in
                                stepRow(number: index + 1, step: step)

                                if index < WateringStep.allCases.count - 1 {
                                    Divider().padding(.leading, 56)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    guideSection(title: "Why the schedule changes", icon: "calendar.badge.clock") {
                        VStack(spacing: 0) {
                            factorRow(
                                icon: "sun.max.fill",
                                title: "Light",
                                text: "Brighter conditions often help the plant and potting mix use water faster."
                            )
                            Divider().padding(.leading, 60)
                            factorRow(
                                icon: "thermometer",
                                title: "Temperature and humidity",
                                text: "Warm, dry air usually speeds drying; cool or humid air usually slows it."
                            )
                            Divider().padding(.leading, 60)
                            factorRow(
                                icon: "shippingbox.fill",
                                title: "Pot and potting mix",
                                text: "Pot size, drainage, material, and mix all change how long moisture remains."
                            )
                            Divider().padding(.leading, 60)
                            factorRow(
                                icon: "leaf.fill",
                                title: "Growth and season",
                                text: "A plant often uses less water when growth slows or available light decreases."
                            )
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    guideSection(title: "Too dry or too wet?", icon: "magnifyingglass") {
                        VStack(spacing: 12) {
                            symptomCard(
                                title: "Possible underwatering",
                                icon: "sun.max.fill",
                                accent: Color(red: 0.91, green: 0.52, blue: 0.17),
                                symptoms: "Dry mix, a noticeably light pot, drooping or curling leaves, and crisp edges can be clues."
                            )

                            symptomCard(
                                title: "Possible overwatering",
                                icon: "drop.triangle.fill",
                                accent: Color(red: 0.20, green: 0.48, blue: 0.75),
                                symptoms: "Mix that stays wet, yellowing leaves, soft stems, odor, or declining roots deserve a closer look."
                            )
                        }

                        Text("Wilting can happen when a plant is too dry or when damaged roots cannot take up water. Check the potting mix and roots before reacting.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Label {
                        Text("A reminder tells you when to check your plant. The plant and potting mix tell you whether to water.")
                    } icon: {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(blue)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .background(blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Watering basics")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedMoisture) { moisture in
            MoistureCheckDetailView(moisture: moisture)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("WATER WITH A REASON", systemImage: "drop.fill")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(Color(red: 0.43, green: 0.80, blue: 1.0))

            Text("Check first. Water fully.")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Build a simple habit: inspect the potting mix, water evenly when needed, and always let the excess escape.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(forest, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
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

    private func moistureRow(_ moisture: MoistureCheck) -> some View {
        HStack(spacing: 14) {
            Image(systemName: moisture.icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(moisture.accent)
                .frame(width: 54, height: 54)
                .background(moisture.accent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(moisture.titleKey))
                    .font(.headline)
                    .foregroundStyle(ink)

                Text(LocalizedStringKey(moisture.summaryKey))
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
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func stepRow(number: Int, step: WateringStep) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(verbatim: "\(number)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(blue, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(step.titleKey))
                    .font(.headline)
                    .foregroundStyle(ink)

                Text(LocalizedStringKey(step.descriptionKey))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 14)
    }

    private func factorRow(
        icon: String,
        title: LocalizedStringKey,
        text: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(blue)
                .frame(width: 32, height: 32)
                .background(blue.opacity(0.11), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(ink)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 14)
    }

    private func symptomCard(
        title: LocalizedStringKey,
        icon: String,
        accent: Color,
        symptoms: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(accent)
                .frame(width: 42, height: 42)
                .background(accent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(ink)

                Text(symptoms)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct MoistureCheckDetailView: View {
    let moisture: MoistureCheck

    @Environment(\.dismiss) private var dismiss

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Canvas").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 14) {
                            Image(systemName: moisture.icon)
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundStyle(moisture.accent)
                                .frame(width: 82, height: 82)
                                .background(moisture.accent.opacity(0.12), in: Circle())

                            Label("MOISTURE CHECK", systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.bold))
                                .tracking(1.3)
                                .foregroundStyle(moisture.accent)

                            Text(LocalizedStringKey(moisture.titleKey))
                                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                                .foregroundStyle(ink)

                            Text(LocalizedStringKey(moisture.detailKey))
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        detailRow(
                            title: "Try this",
                            textKey: moisture.testKey,
                            icon: "hand.point.up.left.fill"
                        )

                        detailRow(
                            title: "Next step",
                            textKey: moisture.actionKey,
                            icon: "arrow.right.circle.fill"
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

    private func detailRow(title: LocalizedStringKey, textKey: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(moisture.accent)
                .frame(width: 42, height: 42)
                .background(moisture.accent.opacity(0.12), in: Circle())

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

private enum MoistureCheck: String, CaseIterable, Identifiable {
    case dry
    case moist
    case wet

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .dry: "Dry and light"
        case .moist: "Still slightly moist"
        case .wet: "Wet and heavy"
        }
    }

    var summaryKey: String {
        switch self {
        case .dry: "It may be time to water"
        case .moist: "Wait and check again"
        case .wet: "Do not add more water"
        }
    }

    var detailKey: String {
        switch self {
        case .dry: "The potting mix feels dry to the depth recommended for this plant, and the pot feels lighter than it does after watering."
        case .moist: "The potting mix still feels cool or slightly damp below the surface. Many houseplants can wait, but moisture-loving species may differ."
        case .wet: "The mix feels wet below the surface and the pot is still heavy. Adding water now can keep air away from the roots."
        }
    }

    var testKey: String {
        switch self {
        case .dry: "Press a finger into the potting mix rather than judging only the surface. Lift the pot too, if it is safe to handle."
        case .moist: "Check again after a day or two. Notice how the pot’s weight and the feel of the mix change as it dries."
        case .wet: "Confirm that drainage holes are open and empty any water collected inside the saucer or decorative outer pot."
        }
    }

    var actionKey: String {
        switch self {
        case .dry: "If this plant prefers to dry to this depth, water slowly and evenly until excess drains from the bottom."
        case .moist: "Skip watering for now. Use the reminder as a prompt to inspect again, not as an instruction to pour water."
        case .wet: "Wait for the mix to dry to the plant’s preferred level. If it stays wet unusually long, inspect drainage, light, pot size, and root health."
        }
    }

    var icon: String {
        switch self {
        case .dry: "sun.max.fill"
        case .moist: "drop.halffull"
        case .wet: "drop.fill"
        }
    }

    var accent: Color {
        switch self {
        case .dry: Color(red: 0.91, green: 0.52, blue: 0.17)
        case .moist: Color(red: 0.18, green: 0.67, blue: 0.60)
        case .wet: Color(red: 0.12, green: 0.55, blue: 0.82)
        }
    }
}

private enum WateringStep: String, CaseIterable, Identifiable {
    case inspect
    case pour
    case drain
    case empty

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .inspect: "Test below the surface"
        case .pour: "Pour slowly and evenly"
        case .drain: "Watch for drainage"
        case .empty: "Empty standing water"
        }
    }

    var descriptionKey: String {
        switch self {
        case .inspect: "Feel the potting mix at the depth your plant prefers and notice whether the pot feels light or heavy."
        case .pour: "Move around the pot so the whole root ball is moistened instead of wetting only one small area."
        case .drain: "Continue until some water exits the drainage holes. Very dry mix may need a second slow pass."
        case .empty: "Let the pot finish draining, then discard water from its saucer or decorative outer pot."
        }
    }
}
