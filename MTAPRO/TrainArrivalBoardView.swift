//
//  TrainArrivalBoardView.swift
//  MTAPRO
//
//  Created by Student on 5/8/26.
//

import SwiftUI

struct TrainArrivalBoardView: View {
    
    @State private var direction: String = "Uptown"
    
    let arrivals = [
        ("A", "2 min"),
        ("C", "5 min"),
        ("E", "11 min")
    ]
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                
                
                HStack {
                    Text("34 St - Penn Station")
                        .foregroundStyle(.green)
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.tint(.secondary))
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 40)
                            .frame(maxWidth: 100, maxHeight: 70)
                            .glassEffect(.regular.tint(.blue))
                        
                        
                        Image("mtaLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 55, height: 55)
                    }
                }
                
                // MARK: Train Image / Graphic Area
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red, lineWidth: 2)
                        )
                    
                    VStack(spacing: 12) {
                        Image(systemName: "tram.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.red)
                        
                        Text("Insert train icon")
                            .foregroundColor(.red)
                            .font(.title3)
                            .italic()
                    }
                }
                .frame(height: 180)
                
                Divider()
                    .background(Color.black)
                
                // MARK: Bottom Section
                HStack(alignment: .top, spacing: 16) {
                    
                    // Arrival Times
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Arrival Times")
                            .font(.headline)
                            .foregroundColor(.purple)
                        
                        ForEach(arrivals, id: \.0) { train, time in
                            HStack {
                                Text(train)
                                    .bold()
                                    .frame(width: 28, height: 28)
                                    .background(.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                
                                Text(time)
                                    .font(.body)
                            }
                            .foregroundStyle(.blue)
                            
                            .padding(10)
                            .glassEffect()
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    Divider()
                        .frame(height: 180)
                    
                    // Right Controls
                    VStack(spacing: 16) {
                        
                        Button {
                            direction = direction == "Uptown"
                            ? "Downtown"
                            : "Uptown"
                        } label: {
                            VStack {
                                Image(systemName: "arrow.up.arrow.down")
                                Text("Change Direction")
                                    .multilineTextAlignment(.center)
                                    .font(.caption)
                            }
                            .padding()
                            .frame(width: 130)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.purple, lineWidth: 2)
                            )
                            //.background(Color("ElementColor"))
                        }
                        
                        VStack(spacing: 8) {
                            Text("Service Status")
                                .font(.headline)
                            
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                                
                                Text("Good Service")
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                        .frame(width: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.purple, lineWidth: 2)
                        )
                        
                        Spacer()
                    }
                    .foregroundColor(.purple)
                }
                .frame(height: 220)
            }
            .padding(20)
            .frame(maxWidth: 420)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .blue.opacity(0.4), radius: 10, y: 6)
            .padding()
            
        }
        
    }
}

#Preview {
    TrainArrivalBoardView()
}

#Preview {
    TrainArrivalBoardView()
}
