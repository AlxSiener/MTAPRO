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
            if (trainOn) {
                HStack{
                    Image(systemName: "train.side.rear.car")
                    Image(systemName: "train.side.middle.car")
                    Image(systemName: "train.side.front.car")
                }
                .transition(.move(edge: .leading))
                .font(.largeTitle)
                .foregroundStyle(.tint)
            }
           
                
            Text("MTA PRO APP")
                .font(Font.largeTitle)
            Button("PUSH"){
                withAnimation(.easeOut(duration: 2.0)){
                    trainOn = !trainOn
                }
                    
                

                
            }
            Button("PULL INFO"){
                //tbd
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environment(TrainNetworkClient())
}
