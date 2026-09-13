import SwiftUI

struct NewGrowthLifeStagesGuideView: View {
    @State private var selectedStage: GrowthStage?

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)
    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let freshGreen = Color(red: 0.19, green: 0.71, blue: 0.38)

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    intro

                    guideSection(title: "Follow a new leaf", icon: "leaf.fill") {
                        GrowthStageMapView { stage in
                            selectedStage = stage
                        }

                        Text("Tap a numbered stage to follow the leaf’s journey.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 12) {
                            ForEach(GrowthStage.allCases) { stage in
                                Button {
                                    selectedStage = stage
                                } label: {
                                    stageRow(stage)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens growth stage details")
                            }
                        }
                    }

                    guideSection(title: "Where growth begins", icon: "point.bottomleft.forward.to.point.topright.scurvepath") {
                        VStack(spacing: 0) {
                            factRow(
                                icon: "arrow.up.right",
                                title: "Growing tips",
                                text: "New stems and leaves often develop at the active tip of a shoot."
                            )
                            Divider().padding(.leading, 60)
                            factRow(
                                icon: "circle.hexagongrid.fill",
                                title: "Nodes and buds",
                                text: "A node is the point where a leaf or bud attaches to a stem. New branches and roots can also begin there."
                            )
                            Divider().padding(.leading, 60)
                            factRow(
                                icon: "arrow.up.and.down.and.arrow.left.and.right",
                                title: "Crown or base",
                                text: "Some plants push new leaves or small offsets from the crown or base instead of a vining tip."
                            )
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    guideSection(title: "The plant’s bigger story", icon: "arrow.triangle.2.circlepath") {
                        VStack(spacing: 0) {
                            factRow(
                                icon: "circle.dotted",
                                title: "A fresh start",
                                text: "Depending on the species, a new plant can begin from a seed, spore, cutting, division, or offset."
                            )
                            Divider().padding(.leading, 60)
                            factRow(
                                icon: "leaf.fill",
                                title: "Juvenile phase",
                                text: "A young plant builds roots, stems, and leaves. In some species, juvenile leaves look different from adult leaves."
                            )
                            Divider().padding(.leading, 60)
                            factRow(
                                icon: "camera.macro",
                                title: "Adult phase",
                                text: "A mature plant gains the ability to reproduce through flowers, cones, or spores, though indoor conditions may not trigger them."
                            )
                            Divider().padding(.leading, 60)
                            factRow(
                                icon: "moon.stars.fill",
                                title: "Rest and regrowth",
                                text: "Some houseplants slow down when days are shorter, then resume stronger growth when light and conditions improve."
                            )
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    guideSection(title: "Normal changes", icon: "clock.arrow.circlepath") {
                        VStack(spacing: 12) {
                            signalCard(
                                icon: "paintpalette.fill",
                                title: "New leaves may look different",
                                text: "Tender leaves are often softer or lighter than mature foliage. Their color and texture may change as they expand."
                            )
                            signalCard(
                                icon: "pause.fill",
                                title: "Growth can pause",
                                text: "Shorter days, lower light, cooler conditions, or the plant’s natural rhythm can slow new growth."
                            )
                            signalCard(
                                icon: "leaf.arrow.triangle.circlepath",
                                title: "Older leaves eventually retire",
                                text: "An occasional older leaf may yellow and drop. Several leaves changing quickly deserve a closer check."
                            )
                        }
                    }

                    guideSection(title: "Protect tender growth", icon: "shield.lefthalf.filled") {
                        VStack(spacing: 0) {
                            factRow(
                                icon: "hand.raised.fill",
                                title: "Let it open on its own",
                                text: "Do not pull or force a folded leaf open. Tender tissue is easy to tear."
                            )
                            Divider().padding(.leading, 60)
                            factRow(
                                icon: "equal.circle.fill",
                                title: "Keep care steady",
                                text: "Avoid sudden swings in watering, temperature, or light while new growth is developing."
                            )
                            Divider().padding(.leading, 60)
                            factRow(
                                icon: "magnifyingglass",
                                title: "Check the newest leaves",
                                text: "Pests often gather around tender shoots and folded leaves, so inspect them gently."
                            )
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    guideSection(title: "Pause or problem?", icon: "stethoscope") {
                        VStack(spacing: 12) {
                            statusCard(
                                title: "Usually a pause",
                                icon: "moon.stars.fill",
                                accent: Color(red: 0.39, green: 0.54, blue: 0.66),
                                text: "No new leaf during a slower season can be normal when the existing foliage and roots remain stable."
                            )
                            statusCard(
                                title: "Look more closely",
                                icon: "exclamationmark.triangle.fill",
                                accent: Color(red: 0.92, green: 0.45, blue: 0.20),
                                text: "Black or mushy tips, repeated deformity, spreading discoloration, pests, or several symptoms together call for a full care check."
                            )
                        }
                    }

                    Label {
                        Text("New growth is a progress signal, not proof that every care condition is perfect. Read it together with the roots, older leaves, and potting mix.")
                    } icon: {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(freshGreen)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .background(freshGreen.opacity(0.11), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("New Growth & Life Stages")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedStage) { stage in
            GrowthStageDetailView(stage: stage)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("FOLLOW NEW GROWTH", systemImage: "sparkles")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(freshGreen)

            Text("Watch a new leaf take shape.")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Learn where growth begins, what changes as a leaf opens, and which signals deserve a closer look.")
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
}

private extension NewGrowthLifeStagesGuideView {
    func stageRow(_ stage: GrowthStage) -> some View {
        HStack(spacing: 14) {
            Text(verbatim: "\(stage.number)")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(stage.accent, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(stage.titleKey))
                    .font(.headline)
                    .foregroundStyle(ink)
                Text(LocalizedStringKey(stage.summaryKey))
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

    func factRow(icon: String, title: LocalizedStringKey, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(freshGreen)
                .frame(width: 32, height: 32)
                .background(freshGreen.opacity(0.12), in: Circle())

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

    func signalCard(icon: String, title: LocalizedStringKey, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(freshGreen)
                .frame(width: 42, height: 42)
                .background(freshGreen.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline).foregroundStyle(ink)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func statusCard(title: LocalizedStringKey, icon: String, accent: Color, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 42, height: 42)
                .background(accent.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline).foregroundStyle(ink)
                Text(text)
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

private struct GrowthStageMapView: View {
    var highlightedStage: GrowthStage?
    var onSelect: ((GrowthStage) -> Void)?

    init(highlightedStage: GrowthStage? = nil, onSelect: ((GrowthStage) -> Void)? = nil) {
        self.highlightedStage = highlightedStage
        self.onSelect = onSelect
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image("PlantGrowthStages")
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .accessibilityHidden(true)

                ForEach(GrowthStage.allCases) { stage in
                    marker(for: stage)
                        .position(
                            x: proxy.size.width * stage.markerPosition.x,
                            y: proxy.size.height * stage.markerPosition.y
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
    private func marker(for stage: GrowthStage) -> some View {
        if let onSelect {
            Button {
                onSelect(stage)
            } label: {
                markerBadge(for: stage)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(LocalizedStringKey(stage.titleKey)))
            .accessibilityHint("Opens growth stage details")
        } else {
            markerBadge(for: stage)
                .accessibilityLabel(Text(LocalizedStringKey(stage.titleKey)))
        }
    }

    private func markerBadge(for stage: GrowthStage) -> some View {
        let isHighlighted = highlightedStage == nil || highlightedStage == stage
        return Text(verbatim: "\(stage.number)")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(stage.accent, in: Circle())
            .overlay {
                Circle().stroke(.white, lineWidth: highlightedStage == stage ? 3 : 1.5)
            }
            .shadow(color: .black.opacity(isHighlighted ? 0.28 : 0.10), radius: 3, y: 1)
            .scaleEffect(highlightedStage == stage ? 1.16 : 1)
            .opacity(isHighlighted ? 1 : 0.45)
    }
}

private struct GrowthStageDetailView: View {
    let stage: GrowthStage
    @Environment(\.dismiss) private var dismiss

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Canvas").ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        GrowthStageMapView(highlightedStage: stage)

                        Label("GROWTH STAGE", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .tracking(1.3)
                            .foregroundStyle(stage.accent)

                        Text(LocalizedStringKey(stage.titleKey))
                            .font(.system(.largeTitle, design: .serif, weight: .semibold))
                            .foregroundStyle(ink)

                        Text(LocalizedStringKey(stage.detailKey))
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        detailRow(title: "What to notice", textKey: stage.noticeKey, icon: "eye.fill")
                        detailRow(title: "How to help", textKey: stage.helpKey, icon: "heart.fill")
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
                .foregroundStyle(stage.accent)
                .frame(width: 42, height: 42)
                .background(stage.accent.opacity(0.12), in: Circle())
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

private enum GrowthStage: String, CaseIterable, Identifiable {
    case growthPoint
    case emerging
    case unfurling
    case mature

    var id: Self { self }

    var number: Int {
        switch self {
        case .growthPoint: 1
        case .emerging: 2
        case .unfurling: 3
        case .mature: 4
        }
    }

    var titleKey: String {
        switch self {
        case .growthPoint: "Growth point"
        case .emerging: "Emerging leaf"
        case .unfurling: "Unfurling leaf"
        case .mature: "Mature leaf"
        }
    }

    var summaryKey: String {
        switch self {
        case .growthPoint: "A bud or shoot tip begins the next step"
        case .emerging: "Tender growth appears folded or rolled"
        case .unfurling: "The leaf expands and begins to flatten"
        case .mature: "The leaf firms up and reaches its working shape"
        }
    }

    var detailKey: String {
        switch self {
        case .growthPoint: "A new leaf begins in a protected growing region. On many vining plants, look near the shoot tip or a node where a leaf joins the stem."
        case .emerging: "The young leaf becomes visible but stays compact. Folding or rolling protects tender tissue while it grows."
        case .unfurling: "The blade expands and opens. It may still look soft, pale, glossy, or slightly uneven while the tissue finishes developing."
        case .mature: "The leaf reaches its fuller size and working form. Its color and texture become more stable, though the final look varies by species."
        }
    }

    var noticeKey: String {
        switch self {
        case .growthPoint: "Look for a small pointed bud, swelling, or fresh tip. Compare it with nearby older growth so you can recognize what is new."
        case .emerging: "Notice the fresh color and compact shape. Check nearby folds gently for pests without prying the leaf apart."
        case .unfurling: "One side may open before the other. Minor temporary wrinkles can smooth as the leaf expands."
        case .mature: "Compare size, spacing, color, and shape with older leaves. A repeated pattern of smaller or distorted leaves can signal stress."
        }
    }

    var helpKey: String {
        switch self {
        case .growthPoint: "Keep light, watering, and temperature appropriate for the species. Avoid making several major care changes at once."
        case .emerging: "Give it space and resist touching it often. Keep the plant away from abrupt drafts, heat, or strong new sunlight."
        case .unfurling: "Let the leaf open by itself. Do not peel, pull, or rub the tender blade."
        case .mature: "Keep watching the whole plant rather than chasing perfect leaves. Record changes over time if a pattern concerns you."
        }
    }

    var markerPosition: CGPoint {
        switch self {
        case .growthPoint: CGPoint(x: 0.14, y: 0.72)
        case .emerging: CGPoint(x: 0.37, y: 0.72)
        case .unfurling: CGPoint(x: 0.58, y: 0.72)
        case .mature: CGPoint(x: 0.78, y: 0.72)
        }
    }

    var accent: Color {
        switch self {
        case .growthPoint: Color(red: 0.74, green: 0.57, blue: 0.30)
        case .emerging: Color(red: 0.55, green: 0.75, blue: 0.20)
        case .unfurling: Color(red: 0.24, green: 0.72, blue: 0.34)
        case .mature: Color(red: 0.08, green: 0.45, blue: 0.24)
        }
    }
}
