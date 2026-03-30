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

            Text(ble.isConnected ? "Connected 🟢" : "Searching 🔴")
                .font(.headline)

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

                    Text("Robot Telemetry")
                        .font(.largeTitle)
                        .padding(.top)

                    Divider()

                    Text("Telemetry History")
                        .font(.title2)

                    Text("Count: \(ble.telemetryHistory.count)")
                        .foregroundColor(.gray)

                    ForEach(Array(ble.telemetryHistory.enumerated()), id: \.offset) { index, t in

                        VStack(alignment: .leading, spacing: 6) {

                            Text("Time: \(t.timestamp.formatted(date: .omitted, time: .standard))")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text("Front: \(t.front) cm")
                            Text("Left: \(t.left) cm")
                            Text("Right: \(t.right) cm")

                            Text("State: \(t.state)")
                                .fontWeight(.bold)

                            Text("Angle: \(t.angle)")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
    }
}
