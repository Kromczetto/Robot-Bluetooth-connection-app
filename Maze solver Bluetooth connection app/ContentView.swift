//
//  Maze_solver_Bluetooth_connection_appApp.swift
//  Maze solver Bluetooth connection app
//
//  Created by Kuba Kromołowski on 15/03/2026.
//

import SwiftUI

import SwiftUI

struct ContentView: View {

    @StateObject var ble = BLEManager()
    @StateObject var maze = MazeModel()

    @State private var finalTime: Int? = nil

    var body: some View {

        TabView {

            dashboard
                .tabItem {
                    Label("Control", systemImage: "slider.horizontal.3")
                }

            MazeView(
                maze: maze,
                telemetry: ble.telemetryHistory.first
            )
            .tabItem {
                Label("Maze", systemImage: "square.grid.3x3")
            }

            configView
                .tabItem {
                    Label("Config", systemImage: "gearshape")
                }
        }

        .onReceive(ble.$telemetryHistory) { history in
            if let latest = history.first {

                maze.update(latest)

                if latest.x == maze.goalX && latest.y == maze.goalY {

                    if finalTime == nil {
                        finalTime = latest.time

                        ble.sendCommand("S")
                    }
                }
            }
        }

        .onReceive(ble.$mazeDebug) { grid in
            maze.updateFromMazeDebug(grid)
        }

        .onReceive(ble.$didRestart) { restart in
            if restart {

                ble.telemetryHistory.removeAll()
                maze.resize(width: maze.width, height: maze.height)

                finalTime = nil

                ble.didRestart = false
            }
        }
    }
}

extension ContentView {

    var dashboard: some View {

        ScrollView {

            VStack(spacing: 20) {

                connectionCard
                controlCard
                algorithmCard
                telemetryCard
            }
            .padding()
        }
    }
}

extension ContentView {

    var connectionCard: some View {
        HStack {
            Circle()
                .fill(ble.isConnected ? Color.green : Color.red)
                .frame(width: 12, height: 12)

            Text(ble.isConnected ? "Connected" : "Searching...")
                .font(.headline)

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    var controlCard: some View {
        VStack(spacing: 12) {

            Text("Robot Control")
                .font(.headline)

            HStack(spacing: 16) {

                Button {
                    ble.sendCommand("R")
                } label: {
                    Label("START", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    ble.sendCommand("S")
                } label: {
                    Label("STOP", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    var algorithmCard: some View {
        VStack(spacing: 12) {

            Text("Algorithm")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {

                algoButton("LEFT", 0)
                algoButton("FLOOD", 1)
                algoButton("TREMAUX", 2)
                algoButton("GREEDY", 3)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    func algoButton(_ name: String, _ id: Int) -> some View {
        Button {
            ble.sendCommand("ALG:\(id)")
        } label: {
            Text(name)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    var telemetryCard: some View {

        Group {
            if let t = ble.telemetryHistory.first {

                VStack(spacing: 12) {

                    Text("Telemetry")
                        .font(.headline)

                    HStack {
                        stat("Front", "\(t.front) cm")
                        stat("Left", "\(t.left)")
                        stat("Right", "\(t.right)")
                    }

                    Divider()

                    HStack {
                        stat("Pos", "\(t.x), \(t.y)")
                        stat("Dir", "\(t.dir)")
                        stat("State", t.state)
                    }

                    Divider()

                    HStack {
                        stat("Time", "\(t.time) ms")
                        stat("Cells", "\(t.cells)")
                        stat("Turns", "\(t.turns)")
                    }

                    Divider()

                    Text("Algorithm: \(algoName(t.algorithm))")
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            } else {

                Text("Waiting for telemetry...")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }

    func stat(_ title: String, _ value: String) -> some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }
}

extension ContentView {

    var configView: some View {

        VStack(spacing: 20) {

            Text("Goal is fixed at (2,2)")
                .font(.headline)

            Button("Send Goal to Robot") {
                ble.sendCommand("GOAL:2,2")
            }
        }
        .padding()
    }
}

func algoName(_ a: Int) -> String {
    switch a {
    case 0: return "LEFT"
    case 1: return "FLOOD"
    case 2: return "TREMAUX"
    case 3: return "GREEDY"
    default: return "?"
    }
}
