import SwiftUI

struct LightMadeSimpleGuideView: View {
    @State private var selectedLevel: IndoorLightLevel?

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)
    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let gold = Color(red: 0.94, green: 0.62, blue: 0.15)

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    intro

                    guideSection(title: "Meet the light levels", icon: "sun.max.fill") {
                        LightRoomMapView { level in
                            selectedLevel = level
                        }

                        Text("Tap a numbered plant to explore its light level.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 12) {
                            ForEach(IndoorLightLevel.allCases) { level in
                                Button {
                                    selectedLevel = level
                                } label: {
                                    lightLevelRow(level)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens light level details")
                            }
                        }

                        Text("“Low light” does not mean darkness. Every plant needs usable light, and each species has its own range.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    guideSection(title: "Read the room", icon: "house.fill") {
                        VStack(spacing: 0) {
                            observationRow(
                                icon: "arrow.left.and.right",
                                title: "Distance matters",
                                text: "Light usually becomes weaker as a plant moves farther from a window."
                            )
                            Divider().padding(.leading, 60)
                            observationRow(
                                icon: "eye.fill",
                                title: "Watch the sun",
                                text: "Check the spot at several times of day to see whether direct rays actually reach the leaves."
                            )
                            Divider().padding(.leading, 60)
                            observationRow(
                                icon: "building.2.fill",
                                title: "Look for obstructions",
                                text: "Trees, nearby buildings, screens, curtains, and roof overhangs can reduce window light."
                            )
                            Divider().padding(.leading, 60)
                            observationRow(
                                icon: "calendar",
                                title: "Recheck each season",
                                text: "Day length, sun angle, and outdoor foliage can make the same spot brighter or dimmer over the year."
                            )
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    guideSection(title: "Read the plant", icon: "leaf.fill") {
                        VStack(spacing: 12) {
                            signalCard(
                                title: "Possible too little light",
                                icon: "arrow.up.right",
                                accent: Color(red: 0.48, green: 0.56, blue: 0.58),
                                text: "Long, thin growth, leaning toward a window, smaller new leaves, fading color, or fewer flowers can be clues."
                            )

                            signalCard(
                                title: "Possible too much light",
                                icon: "flame.fill",
                                accent: Color(red: 0.94, green: 0.41, blue: 0.20),
                                text: "Bleached areas, pale patches, curling, or dry scorched spots can appear when light is too intense."
                            )
                        }

                        Text("These symptoms can have other causes. Check watering, roots, temperature, and pests before moving the plant again.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    guideSection(title: "Adjust light safely", icon: "slider.horizontal.3") {
                        VStack(spacing: 0) {
                            adviceRow(
                                icon: "figure.walk",
                                title: "Move gradually",
                                text: "Introduce stronger light a little at a time, especially before placing an indoor plant outside."
                            )
                            Divider().padding(.leading, 60)
                            adviceRow(
                                icon: "arrow.triangle.2.circlepath",
                                title: "Rotate for even growth",
                                text: "Turn the pot periodically if one side keeps leaning toward the light."
                            )
                            Divider().padding(.leading, 60)
                            adviceRow(
                                icon: "lightbulb.fill",
                                title: "Supplement when needed",
                                text: "A suitable grow light can help in a dim spot. Follow its distance and timing instructions, and give plants a daily dark period."
                            )
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    Label {
                        Text("More light often means faster growth and faster drying. After changing a plant’s light, check its watering needs again.")
                    } icon: {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(gold)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .background(gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Light Made Simple")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedLevel) { level in
            IndoorLightLevelDetailView(level: level)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("FIND THE RIGHT SPOT", systemImage: "sun.max.fill")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.30))

            Text("See light through a plant’s eyes.")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Learn what common light labels mean, observe how light moves through your home, and notice when a plant wants a change.")
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

private extension LightMadeSimpleGuideView {
    func lightLevelRow(_ level: IndoorLightLevel) -> some View {
        HStack(spacing: 14) {
            Text(verbatim: "\(level.number)")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(level.accent, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(level.titleKey))
                    .font(.headline)
                    .foregroundStyle(ink)

                Text(LocalizedStringKey(level.summaryKey))
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

    func observationRow(
        icon: String,
        title: LocalizedStringKey,
        text: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(gold)
                .frame(width: 32, height: 32)
                .background(gold.opacity(0.12), in: Circle())

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

    func signalCard(
        title: LocalizedStringKey,
        icon: String,
        accent: Color,
        text: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 42, height: 42)
                .background(accent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
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
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func adviceRow(
        icon: String,
        title: LocalizedStringKey,
        text: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(gold)
                .frame(width: 32, height: 32)
                .background(gold.opacity(0.12), in: Circle())

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
}

private struct LightRoomMapView: View {
    var highlightedLevel: IndoorLightLevel?
    var onSelect: ((IndoorLightLevel) -> Void)?

    init(
        highlightedLevel: IndoorLightLevel? = nil,
        onSelect: ((IndoorLightLevel) -> Void)? = nil
    ) {
        self.highlightedLevel = highlightedLevel
        self.onSelect = onSelect
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image("PlantLightRoomMap")
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .accessibilityHidden(true)

                ForEach(IndoorLightLevel.allCases) { level in
                    marker(for: level)
                        .position(
                            x: proxy.size.width * level.markerPosition.x,
                            y: proxy.size.height * level.markerPosition.y
                        )
                }
            }
        }
        .aspectRatio(1.81, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func marker(for level: IndoorLightLevel) -> some View {
        if let onSelect {
            Button {
                onSelect(level)
            } label: {
                markerBadge(for: level)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(LocalizedStringKey(level.titleKey)))
            .accessibilityHint("Opens light level details")
        } else {
            markerBadge(for: level)
                .accessibilityLabel(Text(LocalizedStringKey(level.titleKey)))
        }
    }

    private func markerBadge(for level: IndoorLightLevel) -> some View {
        let isHighlighted = highlightedLevel == nil || highlightedLevel == level

        return Text(verbatim: "\(level.number)")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(level.accent, in: Circle())
            .overlay {
                Circle()
                    .stroke(.white, lineWidth: highlightedLevel == level ? 3 : 1.5)
            }
            .shadow(color: .black.opacity(isHighlighted ? 0.28 : 0.10), radius: 3, y: 1)
            .scaleEffect(highlightedLevel == level ? 1.16 : 1)
            .opacity(isHighlighted ? 1 : 0.45)
    }
}

private struct IndoorLightLevelDetailView: View {
    let level: IndoorLightLevel

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
                            title: "How to recognize it",
                            textKey: level.recognitionKey,
                            icon: "eye.fill"
                        )

                        detailRow(
                            title: "Beginner note",
                            textKey: level.noteKey,
                            icon: "lightbulb.fill"
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
        VStack(alignment: .leading, spacing: 14) {
            LightRoomMapView(highlightedLevel: level)

            Label("LIGHT LEVEL", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.bold))
                .tracking(1.3)
                .foregroundStyle(level.accent)

            Text(LocalizedStringKey(level.titleKey))
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(ink)

            Text(LocalizedStringKey(level.detailKey))
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func detailRow(title: LocalizedStringKey, textKey: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(level.accent)
                .frame(width: 42, height: 42)
                .background(level.accent.opacity(0.12), in: Circle())

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

private enum IndoorLightLevel: String, CaseIterable, Identifiable {
    case directSun
    case brightIndirect
    case medium
    case low

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .low: "Low light"
        case .medium: "Medium indirect light"
        case .brightIndirect: "Bright indirect light"
        case .directSun: "Direct sun"
        }
    }

    var summaryKey: String {
        switch self {
        case .low: "Daylight is present, but weak"
        case .medium: "Gentle, useful light without strong rays"
        case .brightIndirect: "A bright spot just outside direct rays"
        case .directSun: "Sunbeams fall directly on the leaves"
        }
    }

    var detailKey: String {
        switch self {
        case .low: "The space receives limited natural light. Only plants that tolerate low light are likely to maintain healthy growth here."
        case .medium: "The plant receives steady indirect daylight, but not the strongest window light or prolonged direct sun."
        case .brightIndirect: "The area is brightly illuminated for much of the day while curtains, angle, or placement keep strong sunbeams off the leaves."
        case .directSun: "Unfiltered sunlight reaches the foliage for part of the day. This is much more intense than a bright room."
        }
    }

    var recognitionKey: String {
        switch self {
        case .low: "The room has daytime visibility without lamps, but the plant is well away from bright windows or near a window with major obstructions."
        case .medium: "The plant may be close to a gentler window or several feet back from a brighter one. The spot looks comfortably lit, not glaring."
        case .brightIndirect: "The area near the plant looks very bright, but you do not see a hard-edged patch of sun traveling across its leaves."
        case .directSun: "You can see a distinct patch of sunlight or a crisp shadow on or beside the plant when the sun reaches the window."
        }
    }

    var noteKey: String {
        switch self {
        case .low: "Low-light tolerant means the plant can cope—not that it will grow quickly. Watch for stretching, small leaves, or fading color."
        case .medium: "This is a comfortable range for many foliage plants, but always check the care needs of the individual species."
        case .brightIndirect: "Many tropical foliage plants favor this range. A sheer curtain can soften stronger window light."
        case .directSun: "Use this for plants that are adapted to strong sun. Acclimate plants gradually because sudden intense light can scorch leaves."
        }
    }

    var icon: String {
        switch self {
        case .low: "sun.min.fill"
        case .medium: "cloud.sun.fill"
        case .brightIndirect: "sun.max.fill"
        case .directSun: "sun.max.circle.fill"
        }
    }

    var number: Int {
        switch self {
        case .directSun: 1
        case .brightIndirect: 2
        case .medium: 3
        case .low: 4
        }
    }

    var markerPosition: CGPoint {
        switch self {
        case .directSun: CGPoint(x: 0.18, y: 0.52)
        case .brightIndirect: CGPoint(x: 0.39, y: 0.35)
        case .medium: CGPoint(x: 0.56, y: 0.63)
        case .low: CGPoint(x: 0.88, y: 0.54)
        }
    }

    var accent: Color {
        switch self {
        case .low: Color(red: 0.47, green: 0.57, blue: 0.62)
        case .medium: Color(red: 0.35, green: 0.67, blue: 0.70)
        case .brightIndirect: Color(red: 0.96, green: 0.68, blue: 0.18)
        case .directSun: Color(red: 0.95, green: 0.43, blue: 0.18)
        }
    }
}
