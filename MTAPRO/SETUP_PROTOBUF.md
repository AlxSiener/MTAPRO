# Setting Up GTFS Protobuf Parsing

## Current Status
✅ **Compilation Error Fixed** - Your code now compiles without errors
⚠️ **Protobuf Parsing Disabled** - The `parseGTFSData` method returns empty data

## What's Needed
The MTA GTFS feeds return **binary Protocol Buffer** data, which requires special Swift files to decode.

---

## Option 1: Complete Setup (Recommended)

### Step 1: Install Protobuf Compiler
Open Terminal and run:
```bash
brew install protobuf
```

### Step 2: Generate Swift Files
Navigate to your project directory and run:
```bash
cd /path/to/your/MTAPRO/project
protoc --swift_out=. gtfs-realtime.proto
```

This creates a file named `gtfs-realtime.pb.swift`

### Step 3: Add Generated File to Xcode
1. In Xcode, right-click your project
2. Select "Add Files to MTAPRO..."
3. Choose `gtfs-realtime.pb.swift`
4. Make sure "Add to targets: MTAPRO" is checked

### Step 4: Add SwiftProtobuf Package
1. In Xcode: **File > Add Package Dependencies**
2. Enter URL: `https://github.com/apple/swift-protobuf.git`
3. Select version **2.0.0** or higher
4. Click **Add Package**

### Step 5: Activate the Protobuf Code
In `TrainNetworkClient.swift`:
1. **Uncomment** line 9: Change `// import SwiftProtobuf` to `import SwiftProtobuf`
2. **Replace** the `parseGTFSData` method with the commented-out code at the bottom of that method

### Step 6: Build and Test
Build your project. You should now be able to parse real MTA data!

---

## Option 2: Use a Third-Party Package

Instead of generating files yourself, use a pre-made Swift package:

### Add Transit Realtime Swift Package
1. **File > Add Package Dependencies**
2. Enter: `https://github.com/googletransit/gtfs-realtime-bindings`
3. Add to your target

This package includes pre-generated Swift code for GTFS Realtime.

---

## Option 3: Keep Temporary Mock Data

If you want to continue development without real data:
- Your code will compile and run
- `parseGTFSData` returns an empty array
- You can use mock data for testing

Add this to your code for testing:
```swift
// In your view or test code
let mockTrains = [
    Train(name: "G", trainLine: "G", direction: "North"),
    Train(name: "L", trainLine: "L", direction: "South"),
    Train(name: "7", trainLine: "7", direction: "North")
]
```

---

## Verification

Once set up, test with:
```swift
let client = TrainNetworkClient()
await client.fetchTrainData(for: "g")
print("Trains found: \(client.trains.count)")
```

You should see actual trains from the MTA feed!

---

## Troubleshooting

### "protoc: command not found"
Install Homebrew first:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then: `brew install protobuf`

### "Cannot find TransitRealtime_FeedMessage in scope"
- Make sure you added the `.pb.swift` file to your Xcode project
- Check that it's included in your target
- Build your project (Cmd+B)

### SwiftProtobuf Package Errors
- Update to latest Xcode
- Use SwiftProtobuf version 2.0.0 or higher
- Make sure your deployment target is iOS 13+ or macOS 10.15+

---

## Next Steps After Setup

Once protobuf parsing works:
1. Parse stop time updates for arrival predictions
2. Extract vehicle positions for map display
3. Parse alerts for service changes
4. Add automatic refresh every 30 seconds
5. Cache data locally for offline viewing

---

## Files in Your Project

- ✅ `gtfs-realtime.proto` - Protocol Buffer definition
- ⏳ `gtfs-realtime.pb.swift` - **You need to generate this**
- ✅ `TrainNetworkClient.swift` - Ready to use protobuf (once enabled)
- ✅ `GTFSRealtime.swift` - Custom Swift structs (not currently used)

---

## Resources

- [MTA GTFS API Documentation](https://api.mta.info/#/landing)
- [Google GTFS Realtime Reference](https://developers.google.com/transit/gtfs-realtime)
- [SwiftProtobuf GitHub](https://github.com/apple/swift-protobuf)
- [Protocol Buffers Guide](https://protobuf.dev/getting-started/swifttutorial/)
