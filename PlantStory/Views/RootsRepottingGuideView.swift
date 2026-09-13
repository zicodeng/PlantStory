import SwiftUI

struct RootsRepottingGuideView: View {
    @State private var selectedCondition: RootCondition?

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)
    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let terracotta = Color(red: 0.80, green: 0.43, blue: 0.25)

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    intro

                    guideSection(title: "Read the roots", icon: "waveform.path.ecg") {
                        VStack(spacing: 12) {
                            ForEach(RootCondition.allCases) { condition in
                                Button {
                                    selectedCondition = condition
                                } label: {
                                    conditionRow(condition)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens root condition details")
                            }
                        }
                    }

                    guideSection(title: "Is it time to repot?", icon: "questionmark.circle.fill") {
                        VStack(spacing: 0) {
                            checklistRow("Roots circle the root ball or grow through drainage holes")
                            Divider().padding(.leading, 48)
                            checklistRow("The potting mix dries much faster than it used to")
                            Divider().padding(.leading, 48)
                            checklistRow("Growth has slowed during the plant’s active season")
                            Divider().padding(.leading, 48)
                            checklistRow("The plant is top-heavy or roots are stressing the pot")
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                        Text("One clue alone is not proof. If you are unsure, gently slide out the root ball and look before choosing a larger pot.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    guideSection(title: "Choose the next pot", icon: "shippingbox.fill") {
                        VStack(spacing: 0) {
                            adviceRow(
                                icon: "drop.fill",
                                title: "Drainage first",
                                text: "Use a container with an open drainage hole so extra water can escape."
                            )
                            Divider().padding(.leading, 60)
                            adviceRow(
                                icon: "arrow.up.right.and.arrow.down.left",
                                title: "Go up one size",
                                text: "For many small and medium houseplants, choose a pot roughly 1–2 inches wider than the current one."
                            )
                            Divider().padding(.leading, 60)
                            adviceRow(
                                icon: "leaf.fill",
                                title: "Match the potting mix",
                                text: "Use fresh potting mix suited to the plant instead of soil taken from the garden."
                            )
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    guideSection(title: "Repot step by step", icon: "list.number") {
                        VStack(spacing: 0) {
                            ForEach(Array(RepottingStep.allCases.enumerated()), id: \.element) { index, step in
                                stepRow(number: index + 1, step: step)

                                if index < RepottingStep.allCases.count - 1 {
                                    Divider().padding(.leading, 56)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    Label {
                        Text("Some plants prefer a snug pot. Repot because the roots and watering behavior show a need—not just because a date arrived.")
                    } icon: {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(terracotta)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .background(terracotta.opacity(0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Roots & repotting")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedCondition) { condition in
            RootConditionDetailView(condition: condition)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("BELOW THE SOIL", systemImage: "arrow.down.circle.fill")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(Color(red: 0.98, green: 0.69, blue: 0.39))

            Text("Give roots room to breathe.")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Learn what healthy roots look like, when a plant needs more space, and how to repot without guesswork.")
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

    private func conditionRow(_ condition: RootCondition) -> some View {
        HStack(spacing: 14) {
            Image(condition.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)
                .padding(6)
                .background(condition.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(condition.titleKey))
                    .font(.headline)
                    .foregroundStyle(ink)

                Text(LocalizedStringKey(condition.cardDescriptionKey))
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
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func checklistRow(_ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(terracotta)
                .frame(width: 32)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 13)
    }

    private func adviceRow(
        icon: String,
        title: LocalizedStringKey,
        text: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(terracotta)
                .frame(width: 32, height: 32)
                .background(terracotta.opacity(0.12), in: Circle())

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

    private func stepRow(number: Int, step: RepottingStep) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(verbatim: "\(number)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(terracotta, in: Circle())

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
}

private struct RootConditionDetailView: View {
    let condition: RootCondition

    @Environment(\.dismiss) private var dismiss

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Canvas").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        detailRow(title: "What you might see", textKey: condition.signsKey, icon: "eye.fill")
                        detailRow(title: "What it can mean", textKey: condition.meaningKey, icon: "lightbulb.fill")
                        detailRow(title: "What to do", textKey: condition.actionKey, icon: "checklist")

                        if condition == .rootRot {
                            Text("Root color varies by species. Texture matters too: healthy roots are firm, while rotting roots are often soft or limp.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(16)
                                .background(condition.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
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
            Image(condition.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 230)
                .padding(14)
                .background(condition.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .accessibilityHidden(true)

            Label("ROOT CHECK", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.bold))
                .tracking(1.3)
                .foregroundStyle(condition.accent)

            Text(LocalizedStringKey(condition.titleKey))
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(ink)
        }
    }

    private func detailRow(title: LocalizedStringKey, textKey: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(condition.accent)
                .frame(width: 42, height: 42)
                .background(condition.accent.opacity(0.12), in: Circle())

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

private enum RootCondition: String, CaseIterable, Identifiable {
    case healthy
    case rootbound
    case rootRot

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .healthy: "Healthy roots"
        case .rootbound: "Rootbound"
        case .rootRot: "Possible root rot"
        }
    }

    var cardDescriptionKey: String {
        switch self {
        case .healthy: "Firm roots with room for potting mix"
        case .rootbound: "Dense roots circle the pot’s shape"
        case .rootRot: "Soft, dark roots need a closer look"
        }
    }

    var imageName: String {
        switch self {
        case .healthy: "PlantRootHealthy"
        case .rootbound: "PlantRootBound"
        case .rootRot: "PlantRootRot"
        }
    }

    var accent: Color {
        switch self {
        case .healthy: Color(red: 0.24, green: 0.67, blue: 0.37)
        case .rootbound: Color(red: 0.85, green: 0.56, blue: 0.20)
        case .rootRot: Color(red: 0.78, green: 0.31, blue: 0.25)
        }
    }

    var signsKey: String {
        switch self {
        case .healthy: "Roots feel firm and branch through the potting mix. Many species have cream, tan, or pale growing tips."
        case .rootbound: "Roots densely circle the outside or bottom of the root ball, push through drainage holes, or leave very little potting mix visible."
        case .rootRot: "Some roots look dark and feel soft, limp, or hollow. The plant may also wilt in wet mix, yellow, or lose vigor."
        }
    }

    var meaningKey: String {
        switch self {
        case .healthy: "The root system has air, moisture, and potting mix around it. A healthy plant does not automatically need a larger pot."
        case .rootbound: "The plant may be running out of room and water-holding potting mix. Some plants tolerate snug roots, so consider the plant’s overall behavior too."
        case .rootRot: "Roots may have been damaged by long-lasting wet conditions, poor drainage, cold, excess fertilizer, or disease. Color alone does not confirm rot."
        }
    }

    var actionKey: String {
        switch self {
        case .healthy: "Keep the root ball intact unless another problem needs attention. If you are repotting, use fresh suitable mix and avoid a needlessly large pot."
        case .rootbound: "If watering has become difficult or growth has slowed, move up one pot size and gently loosen the outer circling roots."
        case .rootRot: "Remove soft dead roots with clean shears, use fresh well-draining mix and a clean draining container, then correct the watering or drainage problem."
        }
    }
}

private enum RepottingStep: String, CaseIterable, Identifiable {
    case prepare
    case remove
    case inspect
    case loosen
    case replant
    case water

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .prepare: "Prepare the new home"
        case .remove: "Slide the plant out"
        case .inspect: "Inspect and trim"
        case .loosen: "Loosen circling roots"
        case .replant: "Keep the same depth"
        case .water: "Water and drain"
        }
    }

    var descriptionKey: String {
        switch self {
        case .prepare: "Choose a clean draining pot and lightly moisten fresh potting mix."
        case .remove: "Support the root ball, tip the container, and ease it free. Do not pull the plant by its stem."
        case .inspect: "Look for firm healthy roots and remove roots that are clearly dead, soft, or damaged using clean shears."
        case .loosen: "Gently tease apart the outer roots if they are tightly circling the root ball."
        case .replant: "Set the plant at its previous soil depth, then fill around it without packing the mix too firmly."
        case .water: "Water thoroughly, let excess water escape, and return the plant to suitable light while it settles."
        }
    }
}
