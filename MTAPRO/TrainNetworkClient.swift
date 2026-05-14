//
//
//  TrainNetworkClient.swift
//  MTAPRO
//
//  Created by Alexander Siener on 5/7/26.
//

import Foundation
// TODO: Add SwiftProtobuf package and generate protobuf files
// import SwiftProtobuf
@Observable
class TrainNetworkClient {
    private let session: URLSession
    private let baseURL = URL(string: "https://api-endpoint.mta.info")!
    
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
    /// - Parameter trainLine: The train line identifier (e.g., "g", "1", "a-c-e")
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
    
    // MARK: - Parse Protobuf to Train Objects
    
    /// Parses GTFS Realtime protobuf data and converts it to Train objects
    /// - Parameter data: Raw protobuf binary data
    /// - Returns: Array of Train objects
    func parseGTFSData(_ data: Data) throws -> [Train] {
        // TODO: This is a placeholder implementation
        // To properly parse MTA GTFS data, you need to:
        // 1. Install protobuf compiler: brew install protobuf
        // 2. Generate Swift files: protoc --swift_out=. gtfs-realtime.proto
        // 3. Add the generated .pb.swift file to your project
        // 4. Add SwiftProtobuf package dependency
        // 5. Uncomment the import SwiftProtobuf at the top
        // 6. Replace this implementation with the real protobuf parsing
        
        // For now, return empty array to prevent crash
        print("⚠️ WARNING: Protobuf parsing not yet implemented")
        print("Binary data size: \(data.count) bytes")
        
        // Temporary: Return mock data or empty array
        return []
        
        /* REPLACE WITH THIS ONCE PROTOBUF IS SET UP:
        
        // Decode the protobuf using SwiftProtobuf
        let feedMessage = try TransitRealtime_FeedMessage(serializedData: data)
        
        var trains: [Train] = []
        
        // Process each entity in the feed
        for entity in feedMessage.entity {
            // We're primarily interested in trip updates and vehicle positions
            if entity.hasTripUpdate {
                let tripUpdate = entity.tripUpdate
                
                // Extract trip information
                let routeID = tripUpdate.trip.routeID
                let directionID = tripUpdate.trip.directionID
                let direction = directionID == 0 ? "North" : "South"
                
                // Create train object
                let train = Train(
                    name: Character(routeID.uppercased()),
                    trainLine: routeID.uppercased(),
                    direction: direction
                )
                
                trains.append(train)
            }
            
            // Alternative: Use vehicle position data
            if entity.hasVehicle {
                let vehicle = entity.vehicle
                
                if vehicle.hasTrip {
                    let routeID = vehicle.trip.routeID
                    let directionID = vehicle.trip.directionID
                    let direction = directionID == 0 ? "North" : "South"
                    
                    let train = Train(
                        name: Character(routeID.uppercased()),
                        trainLine: routeID.uppercased(),
                        direction: direction
                    )
                    
                    trains.append(train)
                }
            }
        }
        
        return trains
        */
    }
    
    // MARK: - High-Level Fetch Methods
    
    /// Fetches and parses train data for a specific line
    /// - Parameter trainLine: The train line identifier (e.g., "g", "1", "a-c-e")
    func fetchTrainData(for trainLine: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try await fetchRawGTFSData(for: trainLine)
            let parsedTrains = try parseGTFSData(data)
            
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
    
    /// Fetches train data for multiple lines
    /// - Parameter trainLines: Array of train line identifiers
    func fetchTrainData(for trainLines: [String]) async {
        isLoading = true
        errorMessage = nil
        var allTrains: [Train] = []
        
        for line in trainLines {
            do {
                let data = try await fetchRawGTFSData(for: line)
                let parsedTrains = try parseGTFSData(data)
                allTrains.append(contentsOf: parsedTrains)
            } catch {
                print("Failed to fetch data for line \(line): \(error)")
            }
        }
        
        await MainActor.run {
            self.trains = allTrains
            self.lastUpdated = Date()
            self.isLoading = false
        }
    }
    
    // MARK: - Helper Methods
    
    /// Gets the appropriate feed identifier for a train line type
    /// - Parameter lineType: The TrainLineType enum value
    /// - Returns: The MTA feed identifier string
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
}

// MARK: - MTA Feed Identifiers

extension TrainNetworkClient {
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


