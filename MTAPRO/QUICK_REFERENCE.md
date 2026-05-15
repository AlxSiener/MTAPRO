# 🚇 TrainNetworkClient Quick Reference

## Installation

### 1. Add SwiftProtobuf Package
```
File → Add Package Dependencies
URL: https://github.com/apple/swift-protobuf.git
Version: 2.0.0+
```

### 2. Files Required (Already in Project)
- ✅ `TrainNetworkClient.swift`
- ✅ `gtfs-realtime.pb.swift`
- ✅ `DataModels.swift`

---

## Setup in App

```swift
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

---

## Basic Usage

```swift
struct MyView: View {
    @Environment(TrainNetworkClient.self) private var client
    
    var body: some View {
        List(client.trains) { train in
            Text("\(train.trainLine) - \(train.direction)")
        }
        .task {
            await client.fetchTrainData(for: "g")
        }
    }
}
```

---

## Fetch Methods

### Single Feed
```swift
await client.fetchTrainData(for: "g")
```

### Multiple Feeds
```swift
await client.fetchTrainData(for: ["g", "l", "ace"])
```

### Using TrainLineType
```swift
let feedID = TrainNetworkClient.feedIdentifier(for: .G)
await client.fetchTrainData(for: feedID)
```

---

## Feed Identifiers

| ID | Lines | Code |
|---|---|---|
| `"g"` | G | `fetchTrainData(for: "g")` |
| `"l"` | L | `fetchTrainData(for: "l")` |
| `"ace"` | A, C, E | `fetchTrainData(for: "ace")` |
| `"bdfm"` | B, D, F, M | `fetchTrainData(for: "bdfm")` |
| `"nqrw"` | N, Q, R, W | `fetchTrainData(for: "nqrw")` |
| `"jz"` | J, Z | `fetchTrainData(for: "jz")` |
| `"1234567"` | 1-7 | `fetchTrainData(for: "1234567")` |

---

## Client Properties

| Property | Type | Description |
|----------|------|-------------|
| `trains` | `[Train]` | Parsed train objects |
| `isLoading` | `Bool` | Loading state |
| `errorMessage` | `String?` | Error message if failed |
| `lastUpdated` | `Date?` | Last successful update |

---

## Access Data

```swift
// Check loading
if client.isLoading {
    ProgressView()
}

// Check errors
if let error = client.errorMessage {
    Text("Error: \(error)")
}

// Loop through trains
ForEach(client.trains) { train in
    HStack {
        Text(String(train.name))
        Text(train.trainLine)
        Text(train.direction)
    }
}

// Check last update
if let updated = client.lastUpdated {
    Text("Updated: \(updated.formatted())")
}
```

---

## Pull to Refresh

```swift
List(client.trains) { train in
    Text(train.trainLine)
}
.refreshable {
    await client.fetchTrainData(for: "g")
}
```

---

## Auto-Refresh (30 seconds)

```swift
.onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
    Task {
        await client.fetchTrainData(for: "g")
    }
}
```

---

## Helper Methods

### Get Display Name
```swift
let name = TrainNetworkClient.displayName(for: "G")
// "G Train (Brooklyn/Queens Crosstown)"
```

### Get Feed ID
```swift
let feedID = TrainNetworkClient.feedIdentifier(for: .G)
// "g"
```

### Parse Alerts
```swift
let alerts = try client.parseAlerts(data)
for alert in alerts {
    print("\(alert.header): \(alert.description)")
}
```

---

## Train Object

```swift
class Train: Identifiable {
    var name: Character      // "G"
    var trainLine: String    // "G"
    var direction: String    // "Northbound"
    var id = UUID()
}
```

---

## Console Output

```
📡 Parsing GTFS feed with 47 entities
📅 Feed timestamp: 2026-05-14 15:23:45 +0000
🚇 Train: G | Direction: Northbound | Status: In Transit | Stop: G22
🚇 Train: G | Direction: Southbound | Status: At Station | Stop: G26
✅ Parsed 6 unique trains
```

---

## Error Handling

```swift
do {
    let data = try await client.fetchRawGTFSData(for: "g")
    let trains = try client.parseGTFSData(data)
} catch {
    print("Error: \(error)")
}
```

---

## Example Views

See `TrainNetworkClient-Usage-Examples.swift` for:
1. BasicTrainListView
2. MultiLineTrainView
3. AutoRefreshTrainView
4. StationTrainView
5. MultipleFeedsView
6. Direct data access
7. App setup

---

## MTA API Endpoints

Base: `https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/`

G Train:
```
https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-g
```

All 1-7 Trains:
```
https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-1234567
```

---

## Best Practices

✅ Refresh every 30 seconds (no more frequently)
✅ Show loading indicator while fetching
✅ Display error messages to users
✅ Cache last known data for offline use
✅ Show last update timestamp
✅ Use `.task` for initial load
✅ Use `.refreshable` for pull-to-refresh

❌ Don't poll more than once per 30 seconds
❌ Don't ignore errors silently
❌ Don't block the main thread

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Cannot find TransitRealtime_FeedMessage" | Add SwiftProtobuf package |
| "No such module SwiftProtobuf" | Rebuild project after adding package |
| No trains returned | Check network, verify feed ID |
| Empty trains array | Check console for parsing errors |

---

## Documentation

- **IMPLEMENTATION_GUIDE.md** - Full technical guide
- **IMPLEMENTATION_SUMMARY.md** - Implementation overview
- **TrainNetworkClient-Usage-Examples.swift** - Code examples
- **MTA_INTEGRATION_README.md** - Setup guide

---

## Quick Test

```swift
struct QuickTest: View {
    @Environment(TrainNetworkClient.self) private var client
    
    var body: some View {
        VStack {
            Button("Test") {
                Task { await client.fetchTrainData(for: "g") }
            }
            Text("Trains: \(client.trains.count)")
        }
    }
}
```

---

**Ready to Use!** 🚀

Just add the SwiftProtobuf package and you're all set.
