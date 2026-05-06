//
//  TrainLineStationView.swift
//  MTAPRO
//
//  Created by Student on 4/30/26.
//

import SwiftUI

struct TrainLineStationView: View {
    let trainLine: TrainLineType
    let stations: [Station] = []
    
    var body: some View {
        Text("\(trainLine)")
    }
}

#Preview {
    TrainLineStationView(trainLine: .G)
}
