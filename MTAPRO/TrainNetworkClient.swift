//
//
//  TrainNetworkClient.swift
//  MTAPRO
//
//  Created by Alexander Siener on 5/7/26.
//

import Foundation
import SwiftProtobuf

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
        // Decode the protobuf using SwiftProtobuf
        let feedMessage = try TransitRealtime_FeedMessage(serializedData: data)
        
        var trains: [Train] = []
        var seenVehicles: Set<String> = [] // Track unique vehicles to avoid duplicates
        
        print("📡 Parsing GTFS feed with \(feedMessage.entity.count) entities")
        print("📅 Feed timestamp: \(Date(timeIntervalSince1970: TimeInterval(feedMessage.header.timestamp)))")
        
        // Process each entity in the feed
        for entity in feedMessage.entity {
            // Priority 1: Use vehicle position data (most accurate for active trains)
            if entity.hasVehicle {
                let vehicle = entity.vehicle
                
                // Check if vehicle has trip information
                guard vehicle.hasTrip else { continue }
                
                let trip = vehicle.trip
                guard trip.hasTripID, trip.hasRouteID else { continue }
                
                // Create unique identifier for this vehicle
                let vehicleIdentifier = trip.tripID
                
                // Skip if we've already processed this vehicle
                guard !seenVehicles.contains(vehicleIdentifier) else { continue }
                seenVehicles.insert(vehicleIdentifier)
                
                // Extract route information
                let routeID = trip.routeID
                let directionID = trip.hasDirectionID ? trip.directionID : 0
                
                // Determine direction (MTA convention: 0 = North/Manhattan-bound, 1 = South/Brooklyn-bound)
                let direction: String
                switch directionID {
                case 0:
                    direction = "Northbound"
                case 1:
                    direction = "Southbound"
                default:
                    direction = "Unknown"
                }
                
                // Extract current stop information if available
                var currentStop: String? = nil
                if vehicle.hasStopID {
                    currentStop = vehicle.stopID
                }
                
                // Extract status
                var status: String = "In Transit"
                if vehicle.hasCurrentStatus {
                    switch vehicle.currentStatus {
                    case .incomingAt:
                        status = "Arriving"
                    case .stoppedAt:
                        status = "At Station"
                    case .inTransitTo:
                        status = "In Transit"
                    default:
                        status = "Unknown"
                    }
                }
                
                // Get the first character of route ID for train name
                let trainName = routeID.first ?? Character("?")
                
                // Create train object
                let train = Train(
                    name: trainName,
                    trainLine: routeID,
                    direction: direction
                )
                
                trains.append(train)
                
                // Debug output
                print("🚇 Train: \(routeID) | Direction: \(direction) | Status: \(status) | Stop: \(currentStop ?? "N/A")")
            }
            
            // Priority 2: Use trip updates if no vehicle position
            else if entity.hasTripUpdate {
                let tripUpdate = entity.tripUpdate
                
                // Check if trip update has trip information
                guard tripUpdate.hasTrip else { continue }
                
                let trip = tripUpdate.trip
                guard trip.hasTripID, trip.hasRouteID else { continue }
                
                // Create unique identifier
                let tripIdentifier = trip.tripID
                
                // Skip if already processed
                guard !seenVehicles.contains(tripIdentifier) else { continue }
                seenVehicles.insert(tripIdentifier)
                
                // Extract route information
                let routeID = trip.routeID
                let directionID = trip.hasDirectionID ? trip.directionID : 0
                
                // Determine direction
                let direction: String
                switch directionID {
                case 0:
                    direction = "Northbound"
                case 1:
                    direction = "Southbound"
                default:
                    direction = "Unknown"
                }
                
                // Get the first character of route ID
                let trainName = routeID.first ?? Character("?")
                
                // Create train object
                let train = Train(
                    name: trainName,
                    trainLine: routeID,
                    direction: direction
                )
                
                trains.append(train)
                
                print("🚇 Trip Update: \(routeID) | Direction: \(direction) | Stops: \(tripUpdate.stopTimeUpdate.count)")
            }
        }
        
        print("✅ Parsed \(trains.count) unique trains")
        
        return trains
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
    
    // MARK: - Advanced Parsing Methods
    
    /// Parses detailed stop time predictions from a trip update
    /// - Parameter tripUpdate: The trip update entity
    /// - Returns: Array of stop predictions with times
    func parseStopTimePredictions(from tripUpdate: TransitRealtime_TripUpdate) -> [(stopID: String, arrivalTime: Date?, departureTime: Date?)] {
        var predictions: [(stopID: String, arrivalTime: Date?, departureTime: Date?)] = []
        
        for stopTimeUpdate in tripUpdate.stopTimeUpdate {
            guard stopTimeUpdate.hasStopID else { continue }
            
            let stopID = stopTimeUpdate.stopID
            
            // Parse arrival time
            var arrivalTime: Date? = nil
            if stopTimeUpdate.hasArrival {
                let arrival = stopTimeUpdate.arrival
                if arrival.hasTime {
                    arrivalTime = Date(timeIntervalSince1970: TimeInterval(arrival.time))
                }
            }
            
            // Parse departure time
            var departureTime: Date? = nil
            if stopTimeUpdate.hasDeparture {
                let departure = stopTimeUpdate.departure
                if departure.hasTime {
                    departureTime = Date(timeIntervalSince1970: TimeInterval(departure.time))
                }
            }
            
            predictions.append((stopID: stopID, arrivalTime: arrivalTime, departureTime: departureTime))
        }
        
        return predictions
    }
    
    /// Extracts vehicle position information
    /// - Parameter vehicle: The vehicle position entity
    /// - Returns: Tuple with latitude, longitude, and bearing
    func parseVehiclePosition(from vehicle: TransitRealtime_VehiclePosition) -> (latitude: Double, longitude: Double, bearing: Float)? {
        guard vehicle.hasPosition else { return nil }
        
        let position = vehicle.position
        guard position.hasLatitude, position.hasLongitude else { return nil }
        
        let bearing = position.hasBearing ? position.bearing : 0.0
        
        return (
            latitude: Double(position.latitude),
            longitude: Double(position.longitude),
            bearing: bearing
        )
    }
    
    /// Parses service alerts from the feed
    /// - Parameter data: Raw protobuf binary data
    /// - Returns: Array of alert messages
    func parseAlerts(_ data: Data) throws -> [(header: String, description: String)] {
        let feedMessage = try TransitRealtime_FeedMessage(serializedData: data)
        var alerts: [(header: String, description: String)] = []
        
        for entity in feedMessage.entity {
            guard entity.hasAlert else { continue }
            
            let alert = entity.alert
            
            // Extract header text
            var headerText = "Service Alert"
            if alert.hasHeaderText, !alert.headerText.translation.isEmpty {
                if let firstTranslation = alert.headerText.translation.first {
                    headerText = firstTranslation.text
                }
            }
            
            // Extract description text
            var descriptionText = ""
            if alert.hasDescriptionText, !alert.descriptionText.translation.isEmpty {
                if let firstTranslation = alert.descriptionText.translation.first {
                    descriptionText = firstTranslation.text
                }
            }
            
            alerts.append((header: headerText, description: descriptionText))
        }
        
        return alerts
    }
    
    /// Gets human-readable line names
    /// - Parameter routeID: The route identifier from GTFS
    /// - Returns: Display name for the line
    static func displayName(for routeID: String) -> String {
        switch routeID.uppercased() {
        case "A": return "A Train (8th Ave Express)"
        case "C": return "C Train (8th Ave Local)"
        case "E": return "E Train (8th Ave/Queens Blvd Express)"
        case "B": return "B Train (6th Ave Express)"
        case "D": return "D Train (6th Ave Express)"
        case "F": return "F Train (6th Ave Local)"
        case "M": return "M Train (6th Ave Local)"
        case "G": return "G Train (Brooklyn/Queens Crosstown)"
        case "L": return "L Train (14th St-Canarsie)"
        case "J": return "J Train (Nassau St Local)"
        case "Z": return "Z Train (Nassau St Express)"
        case "N": return "N Train (Broadway Express)"
        case "Q": return "Q Train (Broadway Express)"
        case "R": return "R Train (Broadway Local)"
        case "W": return "W Train (Broadway Local)"
        case "1": return "1 Train (Broadway-7th Ave Local)"
        case "2": return "2 Train (7th Ave Express)"
        case "3": return "3 Train (7th Ave Express)"
        case "4": return "4 Train (Lexington Ave Express)"
        case "5": return "5 Train (Lexington Ave Express)"
        case "6": return "6 Train (Lexington Ave Local)"
        case "7": return "7 Train (Flushing Local/Express)"
        default: return "\(routeID) Train"
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


