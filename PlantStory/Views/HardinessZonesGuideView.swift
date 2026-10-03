import SwiftUI

struct HardinessZonesGuideView: View {
    @State private var selectedZone = USDAHardinessZone.defaultZone

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)
    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let accent = Color(red: 0.43, green: 0.55, blue: 0.94)

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    intro
                    mapSection
                    zoneExplorer
                    practicalGuide
                    sourceNote
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("U.S. Hardiness Zones")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("OUTDOOR GROWING, MAPPED", systemImage: "map.fill")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(Color(red: 0.63, green: 0.71, blue: 1.0))

            Text("Know your winter cold.")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("The USDA map groups U.S. locations by their average annual extreme minimum winter temperature.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(forest, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var mapSection: some View {
        guideSection(title: "Explore the U.S. map", icon: "map.fill") {
            NavigationLink {
                HardinessZoneMapDetailView()
            } label: {
                VStack(spacing: 0) {
                    Image("USDAHardinessZones")
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel("2023 USDA Plant Hardiness Zone Map")

                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                        Text("Tap to explore the full map")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ink)
                    .padding(14)
                }
                .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.black.opacity(0.06), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens a larger scrollable map")

            Text("The map includes the lower 48 states, Alaska, Hawaii, and Puerto Rico.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var zoneExplorer: some View {
        guideSection(title: "Explore each zone", icon: "thermometer.snowflake") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(USDAHardinessZone.allCases) { zone in
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                selectedZone = zone
                            }
                        } label: {
                            Text(verbatim: "\(zone.number)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(zone.labelColor)
                                .frame(width: 42, height: 42)
                                .background(zone.color, in: Circle())
                                .overlay {
                                    if selectedZone == zone {
                                        Circle().stroke(ink, lineWidth: 3)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(zone.accessibilityLabel)
                        .accessibilityAddTraits(selectedZone == zone ? .isSelected : [])
                    }
                }
                .padding(.vertical, 3)
                .padding(.horizontal, 1)
            }

            zoneDetailCard(selectedZone)
        }
    }

    private func zoneDetailCard(_ zone: USDAHardinessZone) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(AppLocalization.string("Zone %lld", Int64(zone.number)))
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(ink)

                Spacer()

                Text(zone.fullTemperatureRange)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(ink)
            }

            Text("Average annual extreme minimum temperature")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                halfZoneCard(label: "\(zone.number)a", range: zone.colderHalfRange, color: zone.color)
                halfZoneCard(label: "\(zone.number)b", range: zone.warmerHalfRange, color: zone.color.opacity(0.76))
            }

            Text("Each numbered zone spans 10°F. The a half is colder; the b half is warmer.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func halfZoneCard(label: String, range: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(verbatim: label)
                .font(.headline)
                .foregroundStyle(ink)
            Text(range)
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(ink.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.28), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var practicalGuide: some View {
        guideSection(title: "Use zones as a starting point", icon: "leaf.fill") {
            VStack(spacing: 0) {
                informationRow(
                    icon: "snowflake",
                    title: "What the zone tells you",
                    text: "It summarizes winter cold and helps compare the likely cold hardiness of outdoor perennial plants."
                )
                Divider().padding(.leading, 58)
                informationRow(
                    icon: "sun.max.fill",
                    title: "What it does not tell you",
                    text: "Sun, summer heat, humidity, wind, soil moisture, and the length of a cold spell still matter."
                )
                Divider().padding(.leading, 58)
                informationRow(
                    icon: "house.and.flag.fill",
                    title: "Expect local differences",
                    text: "Cities, slopes, valleys, elevation, and nearby water can create microclimates within the same area."
                )
            }
            .padding(.horizontal, 16)
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Link(destination: URL(string: "https://planthardiness.ars.usda.gov/")!) {
                HStack(spacing: 12) {
                    Image(systemName: "location.magnifyingglass")
                        .font(.headline)
                        .foregroundStyle(accent)
                        .frame(width: 42, height: 42)
                        .background(accent.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Find your exact USDA zone")
                            .font(.headline)
                            .foregroundStyle(ink)
                        Text("Use the official ZIP-code lookup")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the USDA website")
        }
    }

    private var sourceNote: some View {
        Text("Source: USDA Plant Hardiness Zone Map, 2023. Mapping by the PRISM Climate Group, Oregon State University.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
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

    private func informationRow(
        icon: String,
        title: LocalizedStringKey,
        text: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 32, height: 32)
                .background(accent.opacity(0.11), in: Circle())

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

private struct HardinessZoneMapDetailView: View {
    @State private var showsDetail = false

    var body: some View {
        GeometryReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                Image("USDAHardinessZones")
                    .resizable()
                    .scaledToFit()
                    .frame(width: mapWidth(for: proxy.size.width))
                    .frame(minHeight: proxy.size.height, alignment: .center)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showsDetail.toggle()
                        }
                    }
                    .accessibilityLabel("2023 USDA Plant Hardiness Zone Map")
                    .accessibilityHint("Double tap to switch between fit and detailed views")
                    .accessibilityAction {
                        showsDetail.toggle()
                    }
            }
            .background(Color(red: 0.82, green: 0.86, blue: 0.88))
        }
        .navigationTitle("2023 USDA zone map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showsDetail.toggle()
                    }
                } label: {
                    Label(
                        showsDetail ? "Fit map" : "Zoom map",
                        systemImage: showsDetail
                            ? "arrow.down.right.and.arrow.up.left"
                            : "arrow.up.left.and.arrow.down.right"
                    )
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func mapWidth(for availableWidth: CGFloat) -> CGFloat {
        showsDetail ? max(availableWidth * 2.75, 1_000) : availableWidth
    }
}

private struct USDAHardinessZone: Identifiable, Equatable, CaseIterable {
    static let allCases: [USDAHardinessZone] = [
        USDAHardinessZone(number: 1, color: Color(red: 0.78, green: 0.72, blue: 0.94)),
        USDAHardinessZone(number: 2, color: Color(red: 0.72, green: 0.63, blue: 0.92)),
        USDAHardinessZone(number: 3, color: Color(red: 0.81, green: 0.48, blue: 0.89)),
        USDAHardinessZone(number: 4, color: Color(red: 0.65, green: 0.44, blue: 0.86)),
        USDAHardinessZone(number: 5, color: Color(red: 0.46, green: 0.55, blue: 0.86)),
        USDAHardinessZone(number: 6, color: Color(red: 0.30, green: 0.68, blue: 0.44)),
        USDAHardinessZone(number: 7, color: Color(red: 0.61, green: 0.80, blue: 0.35)),
        USDAHardinessZone(number: 8, color: Color(red: 0.90, green: 0.83, blue: 0.39)),
        USDAHardinessZone(number: 9, color: Color(red: 0.91, green: 0.66, blue: 0.25)),
        USDAHardinessZone(number: 10, color: Color(red: 0.91, green: 0.47, blue: 0.20)),
        USDAHardinessZone(number: 11, color: Color(red: 0.90, green: 0.36, blue: 0.27)),
        USDAHardinessZone(number: 12, color: Color(red: 0.77, green: 0.23, blue: 0.18)),
        USDAHardinessZone(number: 13, color: Color(red: 0.58, green: 0.15, blue: 0.12))
    ]

    static let defaultZone = allCases[6]

    let number: Int
    let color: Color

    var id: Int { number }

    var lowerBound: Int {
        -70 + (number * 10)
    }

    var upperBound: Int {
        lowerBound + 10
    }

    var fullTemperatureRange: String {
        temperatureRange(from: lowerBound, to: upperBound)
    }

    var colderHalfRange: String {
        temperatureRange(from: lowerBound, to: lowerBound + 5)
    }

    var warmerHalfRange: String {
        temperatureRange(from: lowerBound + 5, to: upperBound)
    }

    var labelColor: Color {
        number >= 10 ? .white : Color(red: 0.045, green: 0.16, blue: 0.19)
    }

    var accessibilityLabel: String {
        AppLocalization.string(
            "Zone %lld, %lld°F to %lld°F",
            Int64(number),
            Int64(lowerBound),
            Int64(upperBound)
        )
    }

    private func temperatureRange(from lower: Int, to upper: Int) -> String {
        AppLocalization.string(
            "%lld°F to %lld°F",
            Int64(lower),
            Int64(upper)
        )
    }
}
