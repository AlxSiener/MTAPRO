//
//  ContentView.swift
//  MTAPRO
//
//  Created by Alexander Siener on 4/28/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            HStack{
                Image(systemName: "train.side.rear.car")
                Image(systemName: "train.side.middle.car")
                Image(systemName: "train.side.front.car")
            }
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("MTA PRO APP")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
