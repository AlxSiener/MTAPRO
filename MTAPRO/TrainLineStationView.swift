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
        Station(name: "21st st", line: .G, stopNumber: 1),
        Station(name: "Greenpoint Av", line: .G, stopNumber: 2),
        Station(name: "Nassau Av", line: .G, stopNumber: 3),
        Station(name: "metropolitan-lorimer st", line: .G, stopNumber: 4),
        Station(name: "broadway", line: .G, stopNumber: 5)
    ]
    
    var body: some View {
        List {
            ForEach(gStations) { station in
                NavigationLink {
                    StationView()
                } label: {
                    Text("\(station.name)")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TrainLineStationView(trainLine: .G)
    }
}
