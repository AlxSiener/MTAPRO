//
//  TrainNetworkClientSimple.swift
//  MTAPRO
//
//  Created by Alexander Siener on 5/7/26.
//
//  Alternative implementation that doesn't require SwiftProtobuf
//  Uses raw data parsing or a conversion service
//

import Foundation

@Observable
class TrainNetworkClientSimple {
    private let session: URLSession
    
    // Cache for train data
    var trains: [Train] = []
    var lastUpdated: Date?
    var isLoading: Bool = false
    var errorMessage: String?
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Fetch Raw GTFS Data
    
    /// Fetches raw protobuf data from the MTA GTFS feed for a specific train line
    /// - Parameter trainLine: The train line identifier (e.g., "g", "1", "ace")
    /// - Returns: Raw binary data from the feed
    func fetchRawGTFSData(for trainLine: String) async throws -> Data {
        let urlString = "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-\(trainLine)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        let (data, response) = try await session.data(for: request)
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
    
    // MARK: - Parse Protobuf Manually (Basic Approach)
    
    /// Attempts to extract basic information from protobuf data
    /// Note: This is a simplified approach that looks for specific patterns
    /// For production use, you should use SwiftProtobuf library
    func parseGTFSDataSimple(_ data: Data) -> [Train] {
        var trains: [Train] = []
        
        // Convert data to string representation to look for route IDs
        // This is a hack and not a proper protobuf parser!
        let dataString = String(data: data, encoding: .utf8) ?? ""
        
        // Common NYC subway line identifiers
        let lineIdentifiers = ["A", "C", "E", "B", "D", "F", "M", "G", "L", 
                              "N", "Q", "R", "W", "J", "Z", "1", "2", "3", 
                              "4", "5", "6", "7"]
        
        // Try to find line identifiers in the data
        for line in lineIdentifiers {
            // Count occurrences (rough estimate of active trains)
            let occurrences = dataString.components(separatedBy: line).count - 1
            
            if occurrences > 0 {
                // Create train objects for found lines
                let train = Train(
                    name: Character(line),
                    trainLine: line,
                    direction: "Unknown"
                )
                trains.append(train)
            }
        }
        
        return trains
    }
    
    // MARK: - High-Level Fetch Methods
    
    /// Fetches and parses train data for a specific line
    /// - Parameter trainLine: The train line identifier (e.g., "g", "1", "ace")
    func fetchTrainData(for trainLine: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try await fetchRawGTFSData(for: trainLine)
            let parsedTrains = parseGTFSDataSimple(data)
            
            await MainActor.run {
                self.trains = parsedTrains
                self.lastUpdated = Date()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch train data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Gets the appropriate feed identifier for a train line type
    static func feedIdentifier(for lineType: TrainLineType) -> String {
        switch lineType {
        case .A, .C, .E:
            return "ace"
        case .B, .D, .F, .M:
            return "bdfm"
        case .N, .Q, .R, .W:
            return "nqrw"
        case .G:
            return "g"
        case .J, .Z:
            return "jz"
        case .L:
            return "l"
        case .one, .two, .three, .four, .five, .six:
            return "1234567"
        case .seven:
            return "7"
        }
    }
    
    /// Saves raw protobuf data to documents directory for inspection
    func saveRawDataForInspection(_ data: Data, filename: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("Saved data to: \(fileURL.path)")
        } catch {
            print("Failed to save data: \(error)")
        }
    }
}

// MARK: - MTA Feed Identifiers

extension TrainNetworkClientSimple {
    /// All available MTA GTFS feed identifiers
    static let allFeedIdentifiers = [
        "ace",      // A, C, E lines
        "bdfm",     // B, D, F, M lines
        "g",        // G line
        "jz",       // J, Z lines
        "l",        // L line
        "nqrw",     // N, Q, R, W lines
        "1234567",  // 1, 2, 3, 4, 5, 6, 7 lines
        "si"        // Staten Island Railway
    ]
}
