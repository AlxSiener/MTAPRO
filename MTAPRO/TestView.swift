//
//  TestView.swift
//  MTAPRO
//
//  Test view for displaying GTFS Realtime data from TrainNetworkClient
//

import SwiftUI

struct TestView: View {
    @Environment(TrainNetworkClient.self) private var client
    @State private var selectedFeed: String = "g"
    @State private var showRawData: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Control Panel
                controlPanel
                
                // Status Bar
                statusBar
                
                // Main Content
                if client.isLoading {
                    loadingView
                } else if let error = client.errorMessage {
                    errorView(error)
                } else if client.trains.isEmpty {
                    emptyStateView
                } else {
                    trainListView
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
                .disabled(client.isLoading)
                
                Button(action: fetchAllFeeds) {
                    Label("Fetch All", systemImage: "square.stack.3d.down.right.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(client.isLoading)
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
    
    // MARK: - Computed Properties
    
    private var groupedByDirection: [String: [Train]] {
        Dictionary(grouping: client.trains) { $0.direction }
    }
    
    // MARK: - Actions
    
    private func refreshData() {
        Task {
            await client.fetchTrainData(for: selectedFeed)
        }
    }
    
    private func fetchAllFeeds() {
        Task {
            await client.fetchTrainData(for: ["g", "l", "ace", "bdfm", "nqrw", "jz", "1234567"])
        }
    }
    
    private func clearData() {
        Task { @MainActor in
            client.trains = []
            client.lastUpdated = nil
            client.errorMessage = nil
        }
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
