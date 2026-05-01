//
//  TrainLineView.swift
//  MTAPRO
//
//  Created by Student on 4/30/26.
//

import SwiftUI

struct TrainLineView: View {
    let trainlines: [String] = [
        "A",
        "C",
        "F",
        "G",
        "L",
        "N",
        "Q",
        "D"
    ]
    var body: some View {
        List {
            ForEach(trainlines, id: \.self) {train in
                NavigationLink {
                    TrainLineStationView()
                } label: {
                    Image(systemName: "flag")
                    Text("\(train)")
                }
            }
            .onTapGesture {
                
            }
        }
        
    }
}

#Preview {
    NavigationStack {
        TrainLineView()
    }
}
