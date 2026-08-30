import SwiftUI

struct PlantListView: View {
    @EnvironmentObject private var store: PlantStore
    @State private var showingAddPlant = false
    @State private var plantToDelete: Plant?
    @State private var searchText = ""
    @State private var gardenView: GardenViewMode = .plants
    @State private var sortOption: PlantSortOption = .acquiredDate
    @State private var sortDirection: PlantSortDirection = .descending
    @Namespace private var gardenViewSelection

    private let warmCard = Color(red: 0.98, green: 0.91, blue: 0.76)
    private let ink = Color(red: 0.045, green: 0.16, blue: 0.19)
    private let botanical = Color(red: 0.08, green: 0.45, blue: 0.24)
    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let panel = Color(red: 0.105, green: 0.31, blue: 0.19)
    private let lime = Color(red: 0.36, green: 0.82, blue: 0.12)
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 14, alignment: .top)
    ]

    private var visiblePlants: [Plant] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredPlants: [Plant]
        if query.isEmpty {
            filteredPlants = store.plants
        } else {
            filteredPlants = store.plants.filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                ($0.otherName?.localizedCaseInsensitiveContains(query) ?? false) ||
                $0.species.localizedCaseInsensitiveContains(query)
            }
        }
        return filteredPlants.sorted { sortOption.precedes($0, $1, direction: sortDirection) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.plants.isEmpty {
                    emptyLanding
                } else {
                    populatedGarden
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                if let plant = store.plants.first(where: { $0.id == id }) {
                    PlantDetailView(plant: plant)
                        .toolbar(.visible, for: .navigationBar)
                }
            }
            .sheet(isPresented: $showingAddPlant) {
                NavigationStack { PlantFormView() }
            }
            .confirmationDialog(
                "Delete \(plantToDelete?.name ?? "this plant")?",
                isPresented: Binding(
                    get: { plantToDelete != nil },
                    set: { if !$0 { plantToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete plant", role: .destructive) {
                    if let plantToDelete { store.delete(plantToDelete) }
                    plantToDelete = nil
                }
                Button("Cancel", role: .cancel) { plantToDelete = nil }
            } message: {
                Text("Its notes, photos, watering history, and fertilizing history will also be removed.")
            }
        }
    }

    private var populatedGarden: some View {
        ZStack {
            forest.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    viewPicker

                    Group {
                        if gardenView == .plants {
                            searchField

                            HStack(spacing: 8) {
                                Text("Your collection")
                                    .font(.system(.title3, design: .serif, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()

                                Menu {
                                    Picker("Sort plants", selection: $sortOption) {
                                        ForEach(PlantSortOption.allCases) { option in
                                            Label(option.title, systemImage: option.icon)
                                            .tag(option)
                                        }
                                    }

                                    Divider()

                                    Picker("Sort direction", selection: $sortDirection) {
                                        ForEach(PlantSortDirection.allCases) { direction in
                                            Label(direction.title, systemImage: direction.icon)
                                                .tag(direction)
                                        }
                                    }
                                } label: {
                                    Label("Sort", systemImage: "arrow.up.arrow.down")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(lime)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.white.opacity(0.09), in: Capsule())
                                }
                                .accessibilityLabel("Sort plants")
                                .accessibilityValue("\(sortOption.title), \(sortDirection.title)")

                                Text("\(visiblePlants.count)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(lime)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.white.opacity(0.09), in: Capsule())
                            }

                            if visiblePlants.isEmpty {
                                noSearchResults
                            } else {
                                LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                                    ForEach(visiblePlants) { plant in
                                        NavigationLink(value: plant.id) {
                                            GardenPlantCard(plant: plant, panel: panel, lime: lime)
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            Button("Delete", systemImage: "trash", role: .destructive) {
                                                plantToDelete = plant
                                            }
                                        }
                                    }
                                }
                                .animation(.easeInOut(duration: 0.2), value: sortOption)
                                .animation(.easeInOut(duration: 0.2), value: sortDirection)
                            }
                        } else {
                            GardenCareCalendar(
                                plants: store.plants,
                                forest: forest,
                                panel: panel,
                                lime: lime
                            )
                        }
                    }
                    .id(gardenView)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: gardenView)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 36)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Garden")
                    .font(.system(size: 36, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                Text(collectionSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
            }
            Spacer()
            Button {
                showingAddPlant = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(forest)
                    .frame(width: 54, height: 54)
                    .background(lime, in: Circle())
                    .shadow(color: lime.opacity(0.25), radius: 12, y: 6)
            }
            .accessibilityLabel("Add plant")
        }
    }

    private var collectionSubtitle: String {
        let count = store.plants.count
        return count == 1 ? "You’re raising 1 plant" : "You’re raising \(count) plants"
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.55))
            TextField(
                "",
                text: $searchText,
                prompt: Text("Search your plants")
                    .foregroundStyle(.white.opacity(0.55))
            )
                .foregroundStyle(.white)
                .tint(lime)
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.45))
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 15)
        .frame(height: 48)
        .background(panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var viewPicker: some View {
        HStack(spacing: 4) {
            ForEach(GardenViewMode.allCases) { mode in
                let isSelected = gardenView == mode

                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        gardenView = mode
                    }
                } label: {
                    ZStack {
                        if isSelected {
                            Capsule()
                                .fill(.white)
                                .matchedGeometryEffect(
                                    id: "garden-view-selection",
                                    in: gardenViewSelection
                                )
                        }

                        Label(mode.title, systemImage: mode.icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? forest : .white.opacity(0.72))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(panel, in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Garden view")
    }

    private var noSearchResults: some View {
        VStack(spacing: 10) {
            Image(systemName: "leaf.circle")
                .font(.largeTitle)
                .foregroundStyle(lime)
            Text("No matching plants")
                .font(.system(.headline, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
            Text("Try another name or species.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 46)
    }

    private var emptyLanding: some View {
        ZStack {
            forest.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Label("MY GARDEN", systemImage: "leaf.fill")
                        .font(.caption.weight(.bold))
                        .tracking(2.2)
                        .foregroundStyle(lime)

                    ZStack {
                        LinearGradient(
                            colors: [panel.opacity(0.92), forest.opacity(0.96)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Circle()
                            .fill(.white.opacity(0.08))
                            .frame(width: 190, height: 190)

                        gardenEmblem
                    }
                    .frame(height: 270)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    }

                    Text("Start a garden\nof your own.")
                        .font(.system(size: 38, weight: .medium, design: .serif))
                        .foregroundStyle(.white)

                    Text("Add your first plant and keep its story growing through photos, notes, and care.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.68))

                    Button("Add a plant") { showingAddPlant = true }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(forest)
                        .padding(.horizontal, 18)
                        .frame(height: 50)
                        .background(lime, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
                .padding(.top, 22)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var gardenEmblem: some View {
        AnimatedGardenEmblem(
            forest: forest,
            botanical: botanical,
            lime: lime,
            warmCard: warmCard
        )
    }
}

private struct AnimatedGardenEmblem: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    let forest: Color
    let botanical: Color
    let lime: Color
    let warmCard: Color

    var body: some View {
        ZStack {
            Ellipse()
                .fill(forest.opacity(0.14))
                .frame(width: 150, height: 24)
                .offset(y: 78)

            Capsule()
                .fill(botanical)
                .frame(width: 10, height: 112)
                .offset(y: 4)

            Image(systemName: "leaf.fill")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(botanical)
                .rotationEffect(.degrees(isAnimating ? -33 : -42))
                .offset(x: -47, y: -30)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 2.8).repeatForever(autoreverses: true),
                    value: isAnimating
                )

            Image(systemName: "leaf.fill")
                .font(.system(size: 66, weight: .bold))
                .foregroundStyle(botanical.opacity(0.9))
                .rotationEffect(.degrees(isAnimating ? 36 : 45))
                .offset(x: 46, y: -18)
                .animation(
                    reduceMotion
                        ? nil
                        : .easeInOut(duration: 3.2)
                            .repeatForever(autoreverses: true)
                            .delay(0.3),
                    value: isAnimating
                )

            Image(systemName: "leaf.fill")
                .font(.system(size: 68, weight: .bold))
                .foregroundStyle(botanical)
                .rotationEffect(.degrees(-5))
                .offset(x: 4, y: -61)

            Image(systemName: "leaf.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(lime.opacity(0.85))
                .rotationEffect(.degrees(isAnimating ? 52 : 62))
                .offset(x: 34, y: isAnimating ? -63 : -58)
                .animation(
                    reduceMotion
                        ? nil
                        : .easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true)
                            .delay(0.45),
                    value: isAnimating
                )

            GardenPotShape()
                .fill(
                    LinearGradient(
                        colors: [warmCard, Color(red: 0.87, green: 0.68, blue: 0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 116, height: 78)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(warmCard)
                        .frame(width: 126, height: 20)
                        .overlay {
                            Capsule()
                                .stroke(forest.opacity(0.12), lineWidth: 1)
                        }
                        .offset(y: -4)
                }
                .offset(y: 53)
        }
        .frame(width: 240, height: 220)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Animated illustration of a growing potted plant")
        .onAppear {
            isAnimating = !reduceMotion
        }
        .onChange(of: reduceMotion) { _, shouldReduceMotion in
            isAnimating = !shouldReduceMotion
        }
    }
}

private enum PlantSortDirection: String, CaseIterable, Identifiable {
    case ascending
    case descending

    var id: Self { self }

    var title: String {
        switch self {
        case .ascending: "Ascending"
        case .descending: "Descending"
        }
    }

    var icon: String {
        switch self {
        case .ascending: "arrow.up"
        case .descending: "arrow.down"
        }
    }
}

private enum PlantSortOption: String, CaseIterable, Identifiable {
    case name
    case acquiredDate
    case lastWatered
    case lastFertilized

    var id: Self { self }

    var title: String {
        switch self {
        case .name: "Plant name"
        case .acquiredDate: "Acquired date"
        case .lastWatered: "Last watered"
        case .lastFertilized: "Last fertilized"
        }
    }

    var icon: String {
        switch self {
        case .name: "textformat.abc"
        case .acquiredDate: "calendar.badge.clock"
        case .lastWatered: "drop.fill"
        case .lastFertilized: "leaf.fill"
        }
    }

    func precedes(_ left: Plant, _ right: Plant, direction: PlantSortDirection) -> Bool {
        switch self {
        case .name:
            return namePrecedes(left, right, direction: direction)
        case .acquiredDate:
            guard left.acquisitionDate == right.acquisitionDate else {
                return direction == .ascending
                    ? left.acquisitionDate < right.acquisitionDate
                    : left.acquisitionDate > right.acquisitionDate
            }
            return namePrecedes(left, right, direction: direction)
        case .lastWatered:
            return recentDatePrecedes(
                left.lastWatered,
                right.lastWatered,
                left: left,
                right: right,
                direction: direction
            )
        case .lastFertilized:
            return recentDatePrecedes(
                left.lastFertilized,
                right.lastFertilized,
                left: left,
                right: right,
                direction: direction
            )
        }
    }

    private func recentDatePrecedes(
        _ leftDate: Date?,
        _ rightDate: Date?,
        left: Plant,
        right: Plant,
        direction: PlantSortDirection
    ) -> Bool {
        switch (leftDate, rightDate) {
        case let (leftDate?, rightDate?) where leftDate != rightDate:
            return direction == .ascending ? leftDate < rightDate : leftDate > rightDate
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        default:
            return namePrecedes(left, right, direction: direction)
        }
    }

    private func namePrecedes(
        _ left: Plant,
        _ right: Plant,
        direction: PlantSortDirection
    ) -> Bool {
        let comparison = left.name.localizedStandardCompare(right.name)
        if comparison == .orderedSame {
            return direction == .ascending
                ? left.id.uuidString < right.id.uuidString
                : left.id.uuidString > right.id.uuidString
        }
        return direction == .ascending
            ? comparison == .orderedAscending
            : comparison == .orderedDescending
    }
}

private enum GardenViewMode: String, CaseIterable, Identifiable {
    case plants
    case calendar

    var id: Self { self }

    var title: String {
        switch self {
        case .plants: "Plants"
        case .calendar: "Calendar"
        }
    }

    var icon: String {
        switch self {
        case .plants: "square.grid.2x2.fill"
        case .calendar: "calendar"
        }
    }
}

private struct GardenCareCalendar: View {
    let plants: [Plant]
    let forest: Color
    let panel: Color
    let lime: Color

    @State private var selectedMonth = Calendar.current.component(.month, from: .now)

    private let pruneColor = Color(red: 0.95, green: 0.62, blue: 0.25)
    private let monthColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    private var scheduledPlants: [GardenCareSchedule] {
        plants.compactMap { plant in
            let shouldFertilize = plant.fertilizingMonths?.contains(selectedMonth) ?? false
            let shouldPrune = plant.pruningMonths?.contains(selectedMonth) ?? false
            guard shouldFertilize || shouldPrune else { return nil }
            return GardenCareSchedule(
                plant: plant,
                shouldFertilize: shouldFertilize,
                shouldPrune: shouldPrune
            )
        }
        .sorted { $0.plant.name.localizedCaseInsensitiveCompare($1.plant.name) == .orderedAscending }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Care calendar")
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Choose a month to see the plants that need seasonal care.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))
            }

            HStack(spacing: 18) {
                calendarLegend(title: "Fertilize", color: lime)
                calendarLegend(title: "Prune", color: pruneColor)
            }

            LazyVGrid(columns: monthColumns, spacing: 10) {
                ForEach(1...12, id: \.self) { month in
                    monthButton(month)
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Text(monthName(selectedMonth))
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(careCountText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
            }
            .padding(.top, 4)

            if scheduledPlants.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(lime)
                    Text("No seasonal care scheduled")
                        .font(.system(.headline, design: .serif, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Edit a plant to add fertilizing or pruning months.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
                .padding(.horizontal, 18)
                .background(panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(scheduledPlants) { schedule in
                        NavigationLink(value: schedule.plant.id) {
                            GardenCarePlantRow(
                                schedule: schedule,
                                panel: panel,
                                lime: lime,
                                pruneColor: pruneColor
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func monthButton(_ month: Int) -> some View {
        let isSelected = month == selectedMonth
        let hasFertilizing = plants.contains {
            $0.fertilizingMonths?.contains(month) ?? false
        }
        let hasPruning = plants.contains {
            $0.pruningMonths?.contains(month) ?? false
        }
        let isCurrentMonth = month == Calendar.current.component(.month, from: .now)

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedMonth = month
            }
        } label: {
            VStack(spacing: 8) {
                Text(shortMonthName(month))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 5) {
                    if hasFertilizing {
                        Circle().fill(isSelected ? forest : lime).frame(width: 7, height: 7)
                    }
                    if hasPruning {
                        Circle().fill(isSelected ? forest.opacity(0.68) : pruneColor).frame(width: 7, height: 7)
                    }
                    if !hasFertilizing && !hasPruning {
                        Circle().fill(.clear).frame(width: 7, height: 7)
                    }
                }
            }
            .foregroundStyle(isSelected ? forest : .white)
            .frame(maxWidth: .infinity, minHeight: 62)
            .background(isSelected ? lime : panel, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                if isCurrentMonth && !isSelected {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(lime.opacity(0.75), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(monthName(month))
        .accessibilityValue(accessibilityValue(hasFertilizing: hasFertilizing, hasPruning: hasPruning))
    }

    private func calendarLegend(title: String, color: Color) -> some View {
        HStack(spacing: 7) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    private var careCountText: String {
        let count = scheduledPlants.count
        return count == 1 ? "1 plant" : "\(count) plants"
    }

    private func monthName(_ month: Int) -> String {
        Calendar.current.monthSymbols[month - 1]
    }

    private func shortMonthName(_ month: Int) -> String {
        Calendar.current.shortMonthSymbols[month - 1]
    }

    private func accessibilityValue(hasFertilizing: Bool, hasPruning: Bool) -> String {
        switch (hasFertilizing, hasPruning) {
        case (true, true): return "Fertilizing and pruning scheduled"
        case (true, false): return "Fertilizing scheduled"
        case (false, true): return "Pruning scheduled"
        case (false, false): return "No care scheduled"
        }
    }
}

private struct GardenCareSchedule: Identifiable {
    let plant: Plant
    let shouldFertilize: Bool
    let shouldPrune: Bool

    var id: UUID { plant.id }
}

private struct GardenCarePlantRow: View {
    let schedule: GardenCareSchedule
    let panel: Color
    let lime: Color
    let pruneColor: Color

    @State private var cardPhoto: Data?

    init(schedule: GardenCareSchedule, panel: Color, lime: Color, pruneColor: Color) {
        self.schedule = schedule
        self.panel = panel
        self.lime = lime
        self.pruneColor = pruneColor
        _cardPhoto = State(initialValue: schedule.plant.photos.randomElement())
    }

    var body: some View {
        HStack(spacing: 13) {
            PlantPhoto(data: cardPhoto, cornerRadius: 14)
                .frame(width: 66, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 9) {
                Text(schedule.plant.name)
                    .font(.system(.headline, design: .serif, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if schedule.shouldFertilize {
                        careChip("Fertilize", icon: "leaf.fill", color: lime)
                    }
                    if schedule.shouldPrune {
                        careChip("Prune", icon: "scissors", color: pruneColor)
                    }
                }
            }

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.38))
        }
        .padding(12)
        .background(panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.07), lineWidth: 1)
        }
        .onChange(of: schedule.plant.photos) { _, photos in
            if let cardPhoto, photos.contains(cardPhoto) { return }
            cardPhoto = photos.randomElement()
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens plant details")
    }

    private func careChip(_ title: String, icon: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(color.opacity(0.13), in: Capsule())
    }
}

private struct GardenPotShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.16, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY + 4)
        )
        path.closeSubpath()
        return path
    }
}

private struct GardenPlantCard: View {
    let plant: Plant
    let panel: Color
    let lime: Color
    @State private var cardPhoto: Data?

    init(plant: Plant, panel: Color, lime: Color) {
        self.plant = plant
        self.panel = panel
        self.lime = lime
        _cardPhoto = State(initialValue: plant.photos.randomElement())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    PlantPhoto(data: cardPhoto, cornerRadius: 0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(plant.name)
                    .font(.system(.headline, design: .serif, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                    Text("Day \(plant.daysRaised)")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(lime)

            }
            .padding(.horizontal, 12)
            .padding(.top, 11)
            .padding(.bottom, 13)
        }
        .onChange(of: plant.photos) { _, photos in
            if let cardPhoto, photos.contains(cardPhoto) {
                return
            }
            cardPhoto = photos.randomElement()
        }
        .padding(7)
        .background(panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.07), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens plant details")
    }
}
