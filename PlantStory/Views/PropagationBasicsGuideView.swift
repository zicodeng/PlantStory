import SwiftUI

struct PropagationBasicsGuideView: View {
    @State private var selectedMethod: PropagationMethod?

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)
    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let mint = Color(red: 0.20, green: 0.72, blue: 0.52)

    var body: some View {
        ZStack {
            Color("Canvas").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    intro

                    guideSection(title: "Choose a propagation method", icon: "square.grid.2x2.fill") {
                        PropagationMethodMapView { method in
                            selectedMethod = method
                        }

                        Text("Tap a numbered method to learn which plant part it uses.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 12) {
                            ForEach(PropagationMethod.allCases) { method in
                                Button {
                                    selectedMethod = method
                                } label: {
                                    methodRow(method)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens propagation method details")
                            }
                        }

                        Text("The right method depends on the species. A leaf that grows roots does not always have the tissue needed to grow a new shoot.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    guideSection(title: "Before you start", icon: "checklist") {
                        VStack(spacing: 0) {
                            factRow(
                                icon: "book.fill",
                                title: "Match the method to the plant",
                                text: "Check a reliable, species-specific guide before removing anything from the parent plant."
                            )
                            Divider().padding(.leading, 60)
                            factRow(
                                icon: "heart.fill",
                                title: "Choose healthy material",
                                text: "Start with growth that is free of pests, disease, rot, and severe stress."
                            )
                            Divider().padding(.leading, 60)
                            factRow(
                                icon: "scissors",
                                title: "Use clean, sharp tools",
                                text: "Clean tools make a neater cut and reduce the chance of carrying pests or pathogens between plants."
                            )
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    guideSection(title: "A simple workflow", icon: "arrow.forward.circle.fill") {
                        VStack(spacing: 12) {
                            workflowCard(
                                number: 1,
                                title: "Find the viable part",
                                text: "Identify the node, leaf, rooted division, or offset required by your chosen method."
                            )
                            workflowCard(
                                number: 2,
                                title: "Prepare the new home",
                                text: "Use a clean container and fresh, airy propagation medium—or water when the species and method suit it."
                            )
                            workflowCard(
                                number: 3,
                                title: "Cut or separate gently",
                                text: "Keep the part you need intact. Remove only leaves that would sit below water or the medium."
                            )
                            workflowCard(
                                number: 4,
                                title: "Label and observe",
                                text: "Record the plant and date, then watch for roots, new shoots, and signs of rot or drying."
                            )
                        }
                    }

                    guideSection(title: "Water or potting mix?", icon: "arrow.left.arrow.right") {
                        VStack(spacing: 12) {
                            choiceCard(
                                icon: "drop.fill",
                                title: "Starting in water",
                                accent: Color(red: 0.30, green: 0.68, blue: 0.91),
                                text: "You can see roots develop and monitor the water level. Move the cutting to mix before the water roots become a crowded tangle."
                            )
                            choiceCard(
                                icon: "circle.grid.cross.fill",
                                title: "Starting in a medium",
                                accent: Color(red: 0.67, green: 0.47, blue: 0.27),
                                text: "Roots develop in the material where the plant may continue growing, but progress is harder to see. Use a fresh, airy medium."
                            )
                        }

                        Text("Both approaches can work for some plants. Follow the method recommended for your species rather than choosing only by appearance.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    guideSection(title: "Help new roots succeed", icon: "sun.and.horizon.fill") {
                        VStack(spacing: 0) {
                            factRow(
                                icon: "sun.max.fill",
                                title: "Bright, indirect light",
                                text: "Give the propagule useful light without harsh direct sun that can dry or scorch tender growth."
                            )
                            Divider().padding(.leading, 60)
                            factRow(
                                icon: "drop.degreesign.fill",
                                title: "Moist, not saturated",
                                text: "Keep the rooting medium evenly moist and airy. Constantly soggy conditions can encourage rot."
                            )
                            Divider().padding(.leading, 60)
                            factRow(
                                icon: "wind",
                                title: "Humidity with airflow",
                                text: "Extra humidity can reduce water loss, but trapped condensation and stale air can encourage disease."
                            )
                            Divider().padding(.leading, 60)
                            factRow(
                                icon: "hourglass",
                                title: "Patience",
                                text: "Rooting speed varies widely by species, season, temperature, and method. Avoid disturbing the cutting repeatedly."
                            )
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    guideSection(title: "Ready for the next pot?", icon: "shippingbox.fill") {
                        VStack(spacing: 12) {
                            choiceCard(
                                icon: "checkmark.circle.fill",
                                title: "Look for an established start",
                                accent: mint,
                                text: "Wait for several healthy roots or a rooted division that holds together. New shoot growth is another encouraging sign."
                            )
                            choiceCard(
                                icon: "exclamationmark.triangle.fill",
                                title: "Pause if it is struggling",
                                accent: Color(red: 0.92, green: 0.45, blue: 0.20),
                                text: "Black, mushy, foul-smelling, or collapsing tissue suggests rot. Remove damaged material and review moisture, cleanliness, and airflow."
                            )
                        }
                    }

                    Label {
                        Text("Propagation is an experiment, not a promise. Start with one healthy piece, label it, and learn how that species responds before taking more.")
                    } icon: {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(mint)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .background(mint.opacity(0.11), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Propagation Basics")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedMethod) { method in
            PropagationMethodDetailView(method: method)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("GROW ONE INTO MANY", systemImage: "point.3.connected.trianglepath.dotted")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(mint)

            Text("Start with the right plant part.")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Learn four common ways to make a new plant, what each method needs, and how to care for it while roots develop.")
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

private extension PropagationBasicsGuideView {
    func methodRow(_ method: PropagationMethod) -> some View {
        HStack(spacing: 14) {
            Text(verbatim: "\(method.number)")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(method.accent, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(method.titleKey))
                    .font(.headline)
                    .foregroundStyle(ink)
                Text(LocalizedStringKey(method.summaryKey))
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
                .foregroundStyle(mint)
                .frame(width: 32, height: 32)
                .background(mint.opacity(0.12), in: Circle())
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

    func workflowCard(number: Int, title: LocalizedStringKey, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(verbatim: "\(number)")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(mint, in: Circle())
                .accessibilityHidden(true)
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

    func choiceCard(icon: String, title: LocalizedStringKey, accent: Color, text: LocalizedStringKey) -> some View {
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

private struct PropagationMethodMapView: View {
    var highlightedMethod: PropagationMethod?
    var onSelect: ((PropagationMethod) -> Void)?

    init(highlightedMethod: PropagationMethod? = nil, onSelect: ((PropagationMethod) -> Void)? = nil) {
        self.highlightedMethod = highlightedMethod
        self.onSelect = onSelect
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image("PlantPropagationMethods")
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .accessibilityHidden(true)

                ForEach(PropagationMethod.allCases) { method in
                    marker(for: method)
                        .position(
                            x: proxy.size.width * method.markerPosition.x,
                            y: proxy.size.height * method.markerPosition.y
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
    private func marker(for method: PropagationMethod) -> some View {
        if let onSelect {
            Button {
                onSelect(method)
            } label: {
                markerBadge(for: method)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(LocalizedStringKey(method.titleKey)))
            .accessibilityHint("Opens propagation method details")
        } else {
            markerBadge(for: method)
                .accessibilityLabel(Text(LocalizedStringKey(method.titleKey)))
        }
    }

    private func markerBadge(for method: PropagationMethod) -> some View {
        let isHighlighted = highlightedMethod == nil || highlightedMethod == method
        return Text(verbatim: "\(method.number)")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(method.accent, in: Circle())
            .overlay {
                Circle().stroke(.white, lineWidth: highlightedMethod == method ? 3 : 1.5)
            }
            .shadow(color: .black.opacity(isHighlighted ? 0.28 : 0.10), radius: 3, y: 1)
            .scaleEffect(highlightedMethod == method ? 1.16 : 1)
            .opacity(isHighlighted ? 1 : 0.45)
    }
}

private struct PropagationMethodDetailView: View {
    let method: PropagationMethod
    @Environment(\.dismiss) private var dismiss

    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Canvas").ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        PropagationMethodMapView(highlightedMethod: method)

                        Label("PROPAGATION METHOD", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .tracking(1.3)
                            .foregroundStyle(method.accent)

                        Text(LocalizedStringKey(method.titleKey))
                            .font(.system(.largeTitle, design: .serif, weight: .semibold))
                            .foregroundStyle(ink)

                        Text(LocalizedStringKey(method.detailKey))
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        detailRow(title: "What to take", textKey: method.takeKey, icon: "scissors")
                        detailRow(title: "How to start", textKey: method.startKey, icon: "sparkles")
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
                .foregroundStyle(method.accent)
                .frame(width: 42, height: 42)
                .background(method.accent.opacity(0.12), in: Circle())
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

private enum PropagationMethod: String, CaseIterable, Identifiable {
    case stemCutting
    case leafCutting
    case division
    case offset

    var id: Self { self }

    var number: Int {
        switch self {
        case .stemCutting: 1
        case .leafCutting: 2
        case .division: 3
        case .offset: 4
        }
    }

    var titleKey: String {
        switch self {
        case .stemCutting: "Stem cutting"
        case .leafCutting: "Leaf cutting"
        case .division: "Division"
        case .offset: "Offsets and plantlets"
        }
    }

    var summaryKey: String {
        switch self {
        case .stemCutting: "Root a stem section with the right node"
        case .leafCutting: "Grow from a leaf when the species allows it"
        case .division: "Separate a rooted clump into complete plants"
        case .offset: "Detach a small plant produced by its parent"
        }
    }

    var detailKey: String {
        switch self {
        case .stemCutting: "A piece of stem produces roots and a new shoot. This is common for many vining and trailing houseplants, but the location of the node matters."
        case .leafCutting: "A whole leaf, petiole, or leaf section can form a new plant in certain species. Other plants may grow roots from a leaf but never produce a shoot."
        case .division: "An established clump is separated into smaller plants. Each division begins with both growing points and roots, so it does not need to build a root system from a bare cutting."
        case .offset: "Some parent plants naturally produce pups, offsets, or plantlets. These can become independent plants once they have enough of their own structure and roots."
        }
    }

    var takeKey: String {
        switch self {
        case .stemCutting: "Choose a healthy, preferably non-flowering stem with the number of nodes recommended for the species. A node is where a leaf or bud joins the stem."
        case .leafCutting: "Use the leaf, petiole, or leaf section specified for that plant. Keep track of which end is the base when orientation matters."
        case .division: "Choose a natural clump with more than one growing point. Plan sections so every new plant keeps healthy shoots and roots."
        case .offset: "Choose an offset or plantlet that has begun forming roots, or keep it attached while it roots when the species allows layering."
        }
    }

    var startKey: String {
        switch self {
        case .stemCutting: "Place the correct lower node in water or fresh rooting medium while keeping leaves above the surface. Remove submerged or buried leaves."
        case .leafCutting: "Place the correct cut surface or petiole in fresh rooting medium. Some fleshy plants need the cut to dry first, so check species-specific instructions."
        case .division: "Gently tease or make a clean cut between sections, keeping roots attached. Pot each division at about the same depth it was growing before."
        case .offset: "Separate it with a clean cut only when ready, preserve its roots, and place it in a small container with an appropriate fresh mix."
        }
    }

    var markerPosition: CGPoint {
        switch self {
        case .stemCutting: CGPoint(x: 0.14, y: 0.75)
        case .leafCutting: CGPoint(x: 0.34, y: 0.75)
        case .division: CGPoint(x: 0.61, y: 0.75)
        case .offset: CGPoint(x: 0.87, y: 0.75)
        }
    }

    var accent: Color {
        switch self {
        case .stemCutting: Color(red: 0.24, green: 0.65, blue: 0.78)
        case .leafCutting: Color(red: 0.42, green: 0.70, blue: 0.28)
        case .division: Color(red: 0.74, green: 0.53, blue: 0.25)
        case .offset: Color(red: 0.13, green: 0.53, blue: 0.31)
        }
    }
}
