//
//  GTFSRealtime.swift
//  MTAPRO
//
//  Created by Alexander Siener on 5/7/26.
//
//  Simplified GTFS Realtime structures for MTA feeds
//

import Foundation

// MARK: - Main Feed Message
struct GTFSRealtimeFeed: Codable {
    let header: FeedHeader
    let entity: [FeedEntity]
}

struct FeedHeader: Codable {
    let gtfsRealtimeVersion: String
    let incrementality: Int?
    let timestamp: UInt64?
    
    enum CodingKeys: String, CodingKey {
        case gtfsRealtimeVersion = "gtfs_realtime_version"
        case incrementality
        case timestamp
    }
}

// MARK: - Feed Entity
struct FeedEntity: Codable {
    let id: String
    let tripUpdate: TripUpdate?
    let vehicle: VehiclePosition?
    let alert: Alert?
    
    enum CodingKeys: String, CodingKey {
        case id
        case tripUpdate = "trip_update"
        case vehicle
        case alert
    }
}

// MARK: - Trip Update
struct TripUpdate: Codable {
    let trip: TripDescriptor
    let stopTimeUpdate: [StopTimeUpdate]?
    let vehicle: VehicleDescriptor?
    let timestamp: UInt64?
    
    enum CodingKeys: String, CodingKey {
        case trip
        case stopTimeUpdate = "stop_time_update"
        case vehicle
        case timestamp
    }
}

struct StopTimeUpdate: Codable {
    let stopSequence: UInt32?
    let stopId: String?
    let arrival: StopTimeEvent?
    let departure: StopTimeEvent?
    
    enum CodingKeys: String, CodingKey {
        case stopSequence = "stop_sequence"
        case stopId = "stop_id"
        case arrival
        case departure
    }
}

struct StopTimeEvent: Codable {
    let delay: Int?
    let time: Int64?
    let uncertainty: Int?
}

// MARK: - Trip Descriptor
struct TripDescriptor: Codable {
    let tripId: String?
    let routeId: String?
    let directionId: UInt32?
    let startTime: String?
    let startDate: String?
    
    enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
        case routeId = "route_id"
        case directionId = "direction_id"
        case startTime = "start_time"
        case startDate = "start_date"
    }
}

// MARK: - Vehicle Position
struct VehiclePosition: Codable {
    let trip: TripDescriptor?
    let vehicle: VehicleDescriptor?
    let position: Position?
    let currentStopSequence: UInt32?
    let stopId: String?
    let currentStatus: Int?
    let timestamp: UInt64?
    
    enum CodingKeys: String, CodingKey {
        case trip
        case vehicle
        case position
        case currentStopSequence = "current_stop_sequence"
        case stopId = "stop_id"
        case currentStatus = "current_status"
        case timestamp
    }
}

struct Position: Codable {
    let latitude: Float
    let longitude: Float
    let bearing: Float?
    let odometer: Double?
    let speed: Float?
}

struct VehicleDescriptor: Codable {
    let id: String?
    let label: String?
    let licensePlate: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case label
        case licensePlate = "license_plate"
    }
}

// MARK: - Alert
struct Alert: Codable {
    let activePeriod: [TimeRange]?
    let informedEntity: [EntitySelector]?
    let headerText: TranslatedString?
    let descriptionText: TranslatedString?
    
    enum CodingKeys: String, CodingKey {
        case activePeriod = "active_period"
        case informedEntity = "informed_entity"
        case headerText = "header_text"
        case descriptionText = "description_text"
    }
}

struct TimeRange: Codable {
    let start: UInt64?
    let end: UInt64?
}

struct EntitySelector: Codable {
    let agencyId: String?
    let routeId: String?
    let routeType: Int?
    let trip: TripDescriptor?
    let stopId: String?
    
    enum CodingKeys: String, CodingKey {
        case agencyId = "agency_id"
        case routeId = "route_id"
        case routeType = "route_type"
        case trip
        case stopId = "stop_id"
    }
}

struct TranslatedString: Codable {
    let translation: [Translation]
}

struct Translation: Codable {
    let text: String
    let language: String?
}
