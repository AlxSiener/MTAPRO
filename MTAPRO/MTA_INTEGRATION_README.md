# MTA GTFS Real-time Data Integration

## Overview
This project now fetches real-time train data from the NYC MTA GTFS feeds. The data is provided in Protocol Buffer (protobuf) binary format and must be decoded properly.

## Required Setup

### 1. Add SwiftProtobuf Package Dependency

The MTA data is in protobuf format, so you need to add the SwiftProtobuf library:

1. In Xcode, go to **File > Add Package Dependencies**
2. Enter this URL: `https://github.com/apple/swift-protobuf.git`
3. Select the latest version (2.0.0 or higher)
4. Click "Add Package"

### 2. Add GTFS Realtime Protobuf Definitions

You need to add the official GTFS Realtime protobuf definitions. Download or create a file with the GTFS-realtime protobuf schema:

1. Download the `.proto` file from: https://github.com/google/transit/blob/master/gtfs-realtime/proto/gtfs-realtime.proto
2. Add it to your Xcode project
3. Use the `protoc` compiler to generate Swift code:

```bash
protoc --swift_out=. gtfs-realtime.proto
```

This will create a `gtfs-realtime.pb.swift` file that you should add to your project.

### Alternative: Use Pre-compiled Swift Files

If you don't want to deal with protoc compilation, you can:

1. Download the pre-generated Swift file from the MTA's documentation
2. Or use a Swift package that already includes them

## How the TrainNetworkClient Works

### Feed Identifiers

The MTA groups subway lines into different feeds:

- **ace**: A, C, E trains
- **bdfm**: B, D, F, M trains
- **g**: G train
- **jz**: J, Z trains
- **l**: L train
- **nqrw**: N, Q, R, W trains
- **1234567**: 1, 2, 3, 4, 5, 6, 7 trains (numbered lines)
- **si**: Staten Island Railway

### Usage Example

```swift
// Fetch G train data
await client.fetchTrainData(for: "g")

// Fetch multiple lines
await client.fetchTrainData(for: ["g", "l", "ace"])

// Use the helper to get feed identifier from TrainLineType
let feedID = TrainNetworkClient.feedIdentifier(for: .G)
await client.fetchTrainData(for: feedID)
```

### Accessing Train Data

The client stores parsed trains in the `trains` property:

```swift
@Environment(TrainNetworkClient.self) private var client

// Access trains
for train in client.trains {
    print("\(train.name) - \(train.trainLine) going \(train.direction)")
}

// Check loading state
if client.isLoading {
    // Show loading indicator
}

// Check for errors
if let error = client.errorMessage {
    // Display error
}

// Check last update time
if let lastUpdated = client.lastUpdated {
    // Display update time
}
```

## App Entry Point

Make sure to add the TrainNetworkClient to your app's environment. In your main App file:

```swift
import SwiftUI

@main
struct MTAPROApp: App {
    @State private var trainClient = TrainNetworkClient()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(trainClient)
        }
    }
}
```

## API Endpoints

Base URL: `https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/`

Examples:
- G train: `https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-g`
- A/C/E trains: `https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-ace`
- 1-7 trains: `https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-1234567`

## Data Refresh Rate

The MTA recommends polling the feeds no more frequently than once every 30 seconds. The data is updated in real-time but excessive polling is discouraged.

## Troubleshooting

### Compile Errors with SwiftProtobuf

Make sure you've added the SwiftProtobuf package and imported it in TrainNetworkClient.swift:
```swift
import SwiftProtobuf
```

### "Unknown type TransitRealtime_FeedMessage"

This means you need to add the GTFS Realtime protobuf definitions. Follow step 2 above.

### HTTP Errors

- 404: Check your feed identifier
- 503: MTA service might be temporarily unavailable
- Timeout: Network connection issue or MTA server slow

## Next Steps

1. Add proper error handling UI
2. Implement automatic refresh (every 30-60 seconds)
3. Parse stop time updates for arrival predictions
4. Display vehicle positions on a map
5. Filter trains by direction or specific stops
6. Add push notifications for train alerts

## Resources

- [MTA GTFS Documentation](https://api.mta.info/#/landing)
- [GTFS Realtime Reference](https://developers.google.com/transit/gtfs-realtime)
- [SwiftProtobuf Documentation](https://github.com/apple/swift-protobuf)
