//
//  TrainLineStationView.swift
//  MTAPRO
//
//  Created by Student on 4/30/26.
//

import SwiftUI

struct TrainLineStationView: View {
    let trainLine: TrainLineType
    let gStations: [Station] = [
        Station(name: "Court Sq", line: .G, stopNumber: 0),
        Station(name: "21st St", line: .G, stopNumber: 1),
        Station(name: "Greenpoint Av", line: .G, stopNumber: 2),
        Station(name: "Nassau Av", line: .G, stopNumber: 3),
        Station(name: "metropolitan-lorimer St", line: .G, stopNumber: 4),
        Station(name: "broadway", line: .G, stopNumber: 5)
    ]
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(),
                    GridItem()
                ], spacing: 20) {
                    ForEach(gStations) { station in
                        NavigationLink {
                            TrainArrivalBoardView(station: station.name)
                        } label: {
                            Text("\(station.name)")
                        }
                        .padding()
                        .background(Color("ElementColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: .blue.opacity(0.2), radius: 8, y: 4)
                    }
                }
                .frame(maxWidth: .infinity,  maxHeight: .infinity)
            }
            .padding()
        }
    }
}

#Preview {
    NavigationStack {
        TrainLineStationView(trainLine: .G)
    }
}
