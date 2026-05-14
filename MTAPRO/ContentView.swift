//
//  ContentView.swift
//  MTAPRO
//
//  Created by Alexander Siener on 4/28/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(TrainNetworkClient.self) private var client
    @State private var trainOn: Bool = false
    
    var body: some View {
        VStack {
            TrainLineView()
            
            if trainOn {
                HStack {
                    Image(systemName: "train.side.rear.car")
                    Image(systemName: "train.side.middle.car")
                    Image(systemName: "train.side.front.car")
                }
                .transition(.move(edge: .leading))
                .font(.largeTitle)
                .foregroundStyle(.tint)
            }
            
            Text("MTA PRO APP")
                .font(.largeTitle)
            
            // Display loading state
            if client.isLoading {
                ProgressView("Loading train data...")
                    .padding()
            }
            
            // Display error message if any
            if let error = client.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding()
            }
            
            // Display train count
            if !client.trains.isEmpty {
                Text("Active trains: \(client.trains.count)")
                    .font(.headline)
                    .padding(.top)
                
                // Display last updated time
                if let lastUpdated = client.lastUpdated {
                    Text("Last updated: \(lastUpdated, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Buttons
            HStack(spacing: 20) {
                Button("Animate") {
                    withAnimation(.easeOut(duration: 1.2)) {
                        trainOn = !trainOn
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Fetch G Train") {
                    Task {
                        await client.fetchTrainData(for: "g")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
    .environment(TrainNetworkClient())
}
