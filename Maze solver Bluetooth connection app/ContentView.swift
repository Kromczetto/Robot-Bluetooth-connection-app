//
//  ContentView.swift
//  Maze solver Bluetooth connection app
//
//  Created by Kuba Kromołowski on 15/03/2026.
//

import SwiftUI

struct ContentView: View {

    @StateObject var ble = BLEManager()
    @StateObject var maze = MazeModel()

    var body: some View {

        TabView {

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

                        // 🧠 DEBUG POZYCJI
                        Text("Pos: (\(latest.x), \(latest.y)) dir: \(latest.dir)")
                            .foregroundColor(.purple)
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

                                Text("(\(t.x), \(t.y)) dir: \(t.dir)")
                                    .foregroundColor(.purple)
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
//            .onAppear {
//                let test = Telemetry(
//                    front: 10,
//                    left: 10,
//                    right: 10,
//                    angle: 0,
//                    state: "TEST",
//                    x: 3,
//                    y: 3,
//                    dir: 0,
//                    walls: 15
//                )
//                maze.update(test)
//            }
            .tabItem {
                Label("Log", systemImage: "list.bullet")
            }

            MazeView(
                maze: maze,
                telemetry: ble.telemetryHistory.first
            )
            .tabItem {
                Label("Maze", systemImage: "square.grid.3x3")
            }
        }

        .onReceive(ble.$telemetryHistory) { history in
            if let latest = history.first {
                maze.update(latest)
            }
        }
    }
}
