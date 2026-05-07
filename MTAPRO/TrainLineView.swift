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
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(), GridItem()
                ], spacing: 20) {
                    ForEach(trainlines) {trainLine in
                        NavigationLink {
                            TrainLineStationView(trainLine: trainLine.line)
                        } label: {
                            Image(systemName: "flag")
                            Text("\(trainLine.name)")
                        }
                        .padding()
                        .background(Color("ElementColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: .blue.opacity(0.2), radius: 8, y: 4)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TrainLineView()
    }
}
