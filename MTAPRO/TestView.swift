//
//  TestView.swift
//  MTAPRO
//
//  Test view for displaying GTFS Realtime data from TrainNetworkClient
//

import SwiftUI
import SwiftProtobuf

struct TestView: View {
    @Environment(TrainNetworkClient.self) private var client
    @State private var selectedFeed: String = "g"
    @State private var showRawData: Bool = false
    @State private var viewMode: ViewMode = .byDirection
    @State private var stationArrivals: [StationArrival] = []
    @State private var isLoadingStations = false
    
    enum ViewMode: String, CaseIterable {
        case byDirection = "By Direction"
        case byStation = "By Station"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Control Panel
                controlPanel
                
                // Status Bar
                statusBar
                
                // Main Content
                if client.isLoading || isLoadingStations {
                    loadingView
                } else if let error = client.errorMessage {
                    errorView(error)
                } else if viewMode == .byDirection && client.trains.isEmpty {
                    emptyStateView
                } else if viewMode == .byStation && stationArrivals.isEmpty {
                    emptyStateView
                } else {
                    if viewMode == .byDirection {
                        trainListView
                    } else {
                        stationArrivalView
                    }
                }
            }
            .navigationTitle("🚇 GTFS Test View")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showRawData.toggle() }) {
                            Label(showRawData ? "Hide Details" : "Show Details", 
                                  systemImage: showRawData ? "eye.slash" : "eye")
                        }
                        
                        Divider()
                        
                        Button(action: refreshData) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Button(action: clearData) {
                            Label("Clear Data", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    // MARK: - Control Panel
    
    private var controlPanel: some View {
        VStack(spacing: 12) {
            // View Mode Selector
            VStack(alignment: .leading, spacing: 4) {
                Text("View Mode")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Picker("View Mode", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewMode) { oldValue, newValue in
                    if newValue == .byStation && stationArrivals.isEmpty {
                        Task {
                            await loadStationArrivals()
                        }
                    }
                }
            }
            
            // Feed Selector
            VStack(alignment: .leading, spacing: 4) {
                Text("Select Feed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Picker("Feed", selection: $selectedFeed) {
                    Text("G Train").tag("g")
                    Text("L Train").tag("l")
                    Text("A/C/E").tag("ace")
                    Text("B/D/F/M").tag("bdfm")
                    Text("N/Q/R/W").tag("nqrw")
                    Text("J/Z").tag("jz")
                    Text("1-7").tag("1234567")
                }
                .pickerStyle(.segmented)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: refreshData) {
                    Label("Fetch Data", systemImage: "arrow.down.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(client.isLoading || isLoadingStations)
                
                Button(action: fetchAllFeeds) {
                    Label("Fetch All", systemImage: "square.stack.3d.down.right.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(client.isLoading || isLoadingStations)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        HStack {
            // Train Count
            Label("\(client.trains.count)", systemImage: "tram.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            // Last Updated
            if let lastUpdated = client.lastUpdated {
                Label(
                    lastUpdated.formatted(date: .omitted, time: .shortened),
                    systemImage: "clock"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            // Loading Indicator
            if client.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Fetching GTFS Data...")
                .font(.headline)
            
            Text("Downloading and parsing protobuf data from MTA")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again", action: refreshData)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tram.circle")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("No Trains Found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try selecting a different feed or refresh the data")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Fetch Data", action: refreshData)
                .buttonStyle(.bordered)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Train List View
    
    private var trainListView: some View {
        List {
            // Summary Section
            Section("Summary") {
                HStack {
                    Text("Total Trains")
                    Spacer()
                    Text("\(client.trains.count)")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Feed ID")
                    Spacer()
                    Text(selectedFeed)
                        .fontWeight(.bold)
                        .font(.system(.body, design: .monospaced))
                }
                
                if let lastUpdated = client.lastUpdated {
                    HStack {
                        Text("Last Updated")
                        Spacer()
                        Text(lastUpdated.formatted())
                            .font(.caption)
                    }
                }
            }
            
            // Trains by Direction
            if !groupedByDirection.isEmpty {
                ForEach(Array(groupedByDirection.keys.sorted()), id: \.self) { direction in
                    Section("\(direction) (\(groupedByDirection[direction]?.count ?? 0) trains)") {
                        ForEach(groupedByDirection[direction] ?? []) { train in
                            TrainRow(train: train, showDetails: showRawData)
                        }
                    }
                }
            }
            
            // Raw Data Section (if enabled)
            if showRawData {
                Section("Raw Train Data") {
                    ForEach(client.trains) { train in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ID: \(train.id.uuidString)")
                                .font(.system(.caption, design: .monospaced))
                            Text("Name: \(String(train.name))")
                                .font(.system(.caption, design: .monospaced))
                            Text("Line: \(train.trainLine)")
                                .font(.system(.caption, design: .monospaced))
                            Text("Direction: \(train.direction)")
                                .font(.system(.caption, design: .monospaced))
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Station Arrival View
    
    private var stationArrivalView: some View {
        List {
            // Summary Section
            Section("Summary") {
                HStack {
                    Text("Total Stations")
                    Spacer()
                    Text("\(stationArrivals.count)")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Feed ID")
                    Spacer()
                    Text(selectedFeed)
                        .fontWeight(.bold)
                        .font(.system(.body, design: .monospaced))
                }
                
                if let lastUpdated = client.lastUpdated {
                    HStack {
                        Text("Last Updated")
                        Spacer()
                        Text(lastUpdated.formatted())
                            .font(.caption)
                    }
                }
            }
            
            // Stations with Arrivals
            ForEach(stationArrivals) { stationArrival in
                Section {
                    // Station Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stationArrival.stationName)
                            .font(.headline)
                        Text(stationArrival.stopID)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .font(.system(.caption, design: .monospaced))
                    }
                    .padding(.vertical, 4)
                    
                    // Group arrivals by direction
                    let groupedArrivals = Dictionary(grouping: stationArrival.arrivals) { $0.direction }
                    let directions = groupedArrivals.keys.sorted()
                    
                    ForEach(directions, id: \.self) { direction in
                        // Direction Header
                        HStack {
                            Image(systemName: direction == "Northbound" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundStyle(direction == "Northbound" ? .blue : .orange)
                            Text(direction)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(groupedArrivals[direction]?.count ?? 0) trains")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        
                        // Show up to 3 closest trains per direction
                        if let directionalArrivals = groupedArrivals[direction] {
                            ForEach(Array(directionalArrivals.prefix(3).enumerated()), id: \.element.id) { index, arrival in
                                StationArrivalRow(arrival: arrival, position: index + 1)
                            }
                            
                            if directionalArrivals.count > 3 {
                                Text("+ \(directionalArrivals.count - 3) more")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 4)
                            }
                        }
                        
                        // Add divider between directions (if not the last one)
                        if direction != directions.last {
                            Divider()
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Computed Properties
    
    private var groupedByDirection: [String: [Train]] {
        Dictionary(grouping: client.trains) { $0.direction }
    }
    
    // MARK: - Actions
    
    private func refreshData() {
        Task {
            await client.fetchTrainData(for: selectedFeed)
            if viewMode == .byStation {
                await loadStationArrivals()
            }
        }
    }
    
    private func fetchAllFeeds() {
        Task {
            await client.fetchTrainData(for: ["g", "l", "ace", "bdfm", "nqrw", "jz", "1234567"])
            if viewMode == .byStation {
                await loadStationArrivals()
            }
        }
    }
    
    private func clearData() {
        Task { @MainActor in
            client.trains = []
            client.lastUpdated = nil
            client.errorMessage = nil
            stationArrivals = []
        }
    }
    
    private func loadStationArrivals() async {
        isLoadingStations = true
        
        do {
            let data = try await client.fetchRawGTFSData(for: selectedFeed)
            let feedMessage = try TransitRealtime_FeedMessage(serializedBytes: data)
            
            // Dictionary to group trains by base station (without direction suffix)
            var stationMap: [String: [TrainArrivalInfo]] = [:]
            
            // Process each trip update
            for entity in feedMessage.entity {
                guard entity.hasTripUpdate else { continue }
                
                let tripUpdate = entity.tripUpdate
                guard tripUpdate.hasTrip else { continue }
                
                let trip = tripUpdate.trip
                guard trip.hasRouteID else { continue }
                
                let routeID = trip.routeID
                
                // Process each stop for this trip
                for stopTimeUpdate in tripUpdate.stopTimeUpdate {
                    guard stopTimeUpdate.hasStopID else { continue }
                    
                    let stopID = stopTimeUpdate.stopID
                    
                    // Determine direction from stop ID suffix (N/S) or trip direction
                    let direction: String
                    if stopID.hasSuffix("N") {
                        direction = "Northbound"
                    } else if stopID.hasSuffix("S") {
                        direction = "Southbound"
                    } else if trip.hasDirectionID {
                        direction = trip.directionID == 0 ? "Northbound" : "Southbound"
                    } else {
                        direction = "Unknown"
                    }
                    
                    // Get the base stop ID (without N/S suffix)
                    let baseStopID = stopID.hasSuffix("N") || stopID.hasSuffix("S")
                        ? String(stopID.dropLast())
                        : stopID
                    
                    // Get arrival time
                    var arrivalTime: Date? = nil
                    var delay: Int? = nil
                    
                    if stopTimeUpdate.hasArrival {
                        let arrival = stopTimeUpdate.arrival
                        if arrival.hasTime {
                            arrivalTime = Date(timeIntervalSince1970: TimeInterval(arrival.time))
                        }
                        if arrival.hasDelay {
                            delay = Int(arrival.delay)
                        }
                    }
                    
                    // Only include future arrivals within the next 60 minutes (closest trains)
                    guard let arrivalTime = arrivalTime,
                          arrivalTime > Date(),
                          arrivalTime.timeIntervalSinceNow <= 3600 else { continue }
                    
                    let trainInfo = TrainArrivalInfo(
                        trainLine: routeID,
                        direction: direction,
                        arrivalTime: arrivalTime,
                        delay: delay
                    )
                    
                    if stationMap[baseStopID] == nil {
                        stationMap[baseStopID] = []
                    }
                    stationMap[baseStopID]?.append(trainInfo)
                }
            }
            
            // Convert to StationArrival objects and sort
            await MainActor.run {
                self.stationArrivals = stationMap.compactMap { stopID, trains in
                    // Only include stations that have arrivals
                    guard !trains.isEmpty else { return nil }
                    
                    // Sort trains by arrival time (closest first)
                    let sortedTrains = trains.sorted { $0.arrivalTime < $1.arrivalTime }
                    
                    return StationArrival(
                        stopID: stopID,
                        stationName: StationNameMapper.name(for: stopID),
                        arrivals: sortedTrains
                    )
                }
                // Sort stations alphabetically by name
                .sorted { $0.stationName < $1.stationName }
            }
        } catch {
            print("Error loading station arrivals: \(error)")
        }
        
        isLoadingStations = false
    }
}

// MARK: - Train Row View

struct TrainRow: View {
    let train: Train
    let showDetails: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Train Badge
            Circle()
                .fill(trainColor)
                .frame(width: 44, height: 44)
                .overlay {
                    Text(String(train.name))
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                }
            
            // Train Info
            VStack(alignment: .leading, spacing: 4) {
                Text(TrainNetworkClient.displayName(for: train.trainLine))
                    .font(.headline)
                
                Text(train.direction)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if showDetails {
                    Text("ID: \(train.id.uuidString.prefix(8))...")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .font(.system(.caption2, design: .monospaced))
                }
            }
            
            Spacer()
            
            // Status Indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
    
    private var trainColor: Color {
        switch train.trainLine.uppercased() {
        case "A", "C", "E":
            return .blue
        case "B", "D", "F", "M":
            return .orange
        case "G":
            return .green
        case "L":
            return .gray
        case "J", "Z":
            return .brown
        case "N", "Q", "R", "W":
            return .yellow
        case "1", "2", "3":
            return .red
        case "4", "5", "6":
            return Color(red: 0, green: 0.5, blue: 0) // Dark green
        case "7":
            return .purple
        default:
            return .gray
        }
    }
}

// MARK: - Station Arrival Row

struct StationArrivalRow: View {
    let arrival: TrainArrivalInfo
    let position: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Position Badge
            ZStack {
                Circle()
                    .fill(badgeColor)
                    .frame(width: 32, height: 32)
                
                Text("\(position)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            
            // Train Badge
            Circle()
                .fill(trainColor)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(arrival.trainLine)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            
            // Train Info
            VStack(alignment: .leading, spacing: 4) {
                Text(TrainNetworkClient.displayName(for: arrival.trainLine))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    if let delay = arrival.delay, delay > 0 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(delay/60) min delay")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text("On time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Arrival Time
            VStack(alignment: .trailing, spacing: 2) {
                Text(arrivalCountdown)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(timeColor)
                
                Text(arrival.arrivalTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var arrivalCountdown: String {
        let timeInterval = arrival.arrivalTime.timeIntervalSinceNow
        if timeInterval < 60 {
            return "Arriving"
        } else {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) min"
        }
    }
    
    private var timeColor: Color {
        let timeInterval = arrival.arrivalTime.timeIntervalSinceNow
        let minutes = Int(timeInterval / 60)
        
        if minutes < 2 {
            return .red
        } else if minutes < 5 {
            return .orange
        } else {
            return .primary
        }
    }
    
    private var badgeColor: Color {
        switch position {
        case 1: return .green
        case 2: return .blue
        case 3: return .purple
        default: return .gray
        }
    }
    
    private var trainColor: Color {
        switch arrival.trainLine.uppercased() {
        case "A", "C", "E":
            return .blue
        case "B", "D", "F", "M":
            return .orange
        case "G":
            return .green
        case "L":
            return .gray
        case "J", "Z":
            return .brown
        case "N", "Q", "R", "W":
            return .yellow
        case "1", "2", "3":
            return .red
        case "4", "5", "6":
            return Color(red: 0, green: 0.5, blue: 0)
        case "7":
            return .purple
        default:
            return .gray
        }
    }
}

// MARK: - Data Models

struct StationArrival: Identifiable {
    let id = UUID()
    let stopID: String
    let stationName: String
    let arrivals: [TrainArrivalInfo]
}

struct TrainArrivalInfo: Identifiable {
    let id = UUID()
    let trainLine: String
    let direction: String
    let arrivalTime: Date
    let delay: Int?
}

// MARK: - Station Name Mapper

struct StationNameMapper {
    static func name(for stopID: String) -> String {
        // Remove direction suffix (N/S) if present
        let baseStopID = stopID.hasSuffix("N") || stopID.hasSuffix("S")
            ? String(stopID.dropLast())
            : stopID
        
        let mapping: [String: String] = [
            // G Train
            "G22": "Court Square",
            "G24": "21 St-Van Alst",
            "G26": "Greenpoint Ave",
            "G28": "Nassau Ave",
            "G29": "Metropolitan Ave",
            "G30": "Broadway",
            "G31": "Flushing Ave",
            "G32": "Myrtle-Willoughby",
            "G33": "Bedford-Nostrand",
            "G34": "Classon Ave",
            "G35": "Clinton-Washington",
            "G36": "Fulton St",
            
            // L Train
            "L01": "8th Ave",
            "L02": "6th Ave",
            "L03": "Union Sq-14th St",
            "L05": "3rd Ave",
            "L06": "1st Ave",
            "L08": "Bedford Ave",
            "L10": "Lorimer St",
            "L11": "Graham Ave",
            "L12": "Grand St",
            "L13": "Montrose Ave",
            "L14": "Morgan Ave",
            "L15": "Jefferson St",
            "L16": "DeKalb Ave",
            "L17": "Myrtle-Wyckoff",
            
            // A Train (partial)
            "A02": "Inwood-207 St",
            "A03": "Dyckman St",
            "A05": "190 St",
            "A06": "181 St",
            "A09": "175 St",
            "A10": "168 St",
            "A11": "163 St",
            "A12": "155 St",
            
            // Add more as needed
        ]
        
        return mapping[baseStopID] ?? baseStopID
    }
}

// MARK: - Test Data Generator

extension TestView {
    /// Generates mock data for testing UI without network
    static func generateMockData() -> [Train] {
        [
            Train(name: "G", trainLine: "G", direction: "Northbound"),
            Train(name: "G", trainLine: "G", direction: "Northbound"),
            Train(name: "G", trainLine: "G", direction: "Southbound"),
            Train(name: "G", trainLine: "G", direction: "Southbound"),
            Train(name: "G", trainLine: "G", direction: "Northbound"),
            Train(name: "L", trainLine: "L", direction: "Eastbound"),
            Train(name: "L", trainLine: "L", direction: "Westbound"),
        ]
    }
}

// MARK: - Preview

#Preview("Test View") {
    TestView()
        .environment(TrainNetworkClient())
}

#Preview("With Mock Data") {
    let client = TrainNetworkClient()
    client.trains = TestView.generateMockData()
    client.lastUpdated = Date()
    
    return TestView()
        .environment(client)
}

#Preview("Loading State") {
    let client = TrainNetworkClient()
    client.isLoading = true
    
    return TestView()
        .environment(client)
}

#Preview("Error State") {
    let client = TrainNetworkClient()
    client.errorMessage = "Failed to fetch train data: The Internet connection appears to be offline."
    
    return TestView()
        .environment(client)
}

#Preview("Empty State") {
    let client = TrainNetworkClient()
    client.trains = []
    
    return TestView()
        .environment(client)
}
#Preview("Station View") {
    let client = TrainNetworkClient()
    client.lastUpdated = Date()
    
    var testView = TestView()
    // Manually set to station mode
    let view = TestView()
    
    return view
        .environment(client)
        .onAppear {
            // This would normally be populated by actual data
        }
}

