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
                .padding(.top)

            Text("Robot Control")
                .font(.title2)

            HStack(spacing: 20) {

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
            .padding()

            // 🔥 LIVE DATA
            if let latest = ble.telemetryHistory.first {

                VStack(spacing: 6) {
                    Text("LIVE")
                        .font(.headline)

                    Text("Front: \(latest.front) cm")
                    Text("Left: \(latest.left) cm")
                    Text("Right: \(latest.right) cm")
                    Text("Angle: \(latest.angle)")
                        .foregroundColor(.blue)

                    Text("State: \(latest.state)")
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }

            Divider()

            ScrollView {

                VStack(spacing: 12) {

                    Text("History")
                        .font(.title2)

                    Text("Count: \(ble.telemetryHistory.count)")
                        .foregroundColor(.gray)

                    ForEach(Array(ble.telemetryHistory.enumerated()), id: \.offset) { _, t in

                        VStack(alignment: .leading, spacing: 4) {

                            Text("\(t.timestamp.formatted(date: .omitted, time: .standard))")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text("F: \(t.front)  L: \(t.left)  R: \(t.right)")
                            Text("Angle: \(t.angle)")
                            Text("State: \(t.state)")
                                .fontWeight(.bold)
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
