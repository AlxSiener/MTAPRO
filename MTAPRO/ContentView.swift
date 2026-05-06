//
//  ContentView.swift
//  MTAPRO
//
//  Created by Alexander Siener on 4/28/26.
//

import SwiftUI

struct ContentView: View {
   // @Environment(TrainNetworkClient.self) private var client
    @State private var trainOn: Bool = false
    var body: some View {
    
        VStack {
            
            
            
            TrainLineView()
            
        
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
                                withAnimation(.easeOut(duration: 1.2)){
                                    trainOn = !trainOn
                                }
                                
                                
                            }
                        }
                        .padding()
        }
    
    }

#Preview {
    NavigationStack {
        ContentView()
    }
       // .environment(TrainNetworkClient())
}
