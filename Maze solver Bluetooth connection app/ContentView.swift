//
//  ContentView.swift
//  Maze solver Bluetooth connection app
//
//  Created by Kuba Kromołowski on 15/03/2026.
//

import SwiftUI

struct ContentView: View {

    @StateObject var ble = BLEManager()

    var body: some View {
        VStack {
            // Status połączenia
            Text(ble.isConnected ? "Connected 🟢" : "Searching 🔴")
                .font(.headline)
            
            // Sterowanie robotem
            Text("Robot Control")
                .font(.title2)
            
            HStack(spacing: 40) {
                
                Button("START") {
                    ble.sendCommand("R")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("STOP") {
                    ble.sendCommand("S")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        
            ScrollView {
                
                VStack(spacing: 20) {
                    
                    // Tytuł
                    Text("Robot Telemetry")
                        .font(.largeTitle)
                        .padding(.top)
                    
                    
                    Divider()
                    
                    // Historia telemetry
                    Text("Telemetry History")
                        .font(.title2)
                    
                    ForEach(ble.telemetryHistory) { t in
                        
                        VStack(alignment: .leading, spacing: 6) {
                            
                            Text("Front: \(t.front) cm")
                            Text("Left: \(t.left) cm")
                            Text("Right: \(t.right) cm")
                            
                            Text("State: \(t.state)")
                                .fontWeight(.bold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Divider()
                    
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            
        }
    }
}
