//
//  TrainLineView.swift
//  MTAPRO
//
//  Created by Student on 4/30/26.
//

import SwiftUI

struct TrainLineView: View {
    let trainlines: [TrainLine] = [
        TrainLine(name: "A", line: .A),
        TrainLine(name: "G", line: .G),
        TrainLine(name: "J", line: .J)
    ]
    var body: some View {
        List {
            ForEach(trainlines) {trainLine in
                NavigationLink {
                    TrainLineStationView(trainLine: trainLine.line)
                } label: {
                    Image(systemName: "flag")
                    Text("\(trainLine.name)")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TrainLineView()
    }
}
