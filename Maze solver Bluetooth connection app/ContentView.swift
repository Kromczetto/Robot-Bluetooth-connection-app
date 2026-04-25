import SwiftUI
import Combine

struct ContentView: View {

    @StateObject var ble = BLEManager()
    @StateObject var maze = MazeModel()

    var body: some View {

        TabView {

            logView
                .tabItem {
                    Label("Log", systemImage: "list.bullet")
                }

            mazeTab
                .tabItem {
                    Label("Maze", systemImage: "square.grid.3x3")
                }
        }
        .onReceive(ble.$telemetryHistory) { history in
            if let latest = history.first {

                if latest.mazeSize > 0 && latest.mazeSize != maze.width {
                    maze.resize(width: latest.mazeSize, height: latest.mazeSize)
                }

                maze.update(latest)
            }
        }
        .onReceive(ble.$mazeDebug.receive(on: RunLoop.main)) { grid in
            maze.updateFromMazeDebug(grid)
        }
    }
}

extension ContentView {

    var mazeTab: some View {

        Group {
            if maze.width == 0 || maze.height == 0 {

                Text("Waiting for maze...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {

                MazeView(
                    maze: maze,
                    telemetry: ble.telemetryHistory.first
                )
            }
        }
    }
}

extension ContentView {

    var logView: some View {
        VStack {

            headerView
            controlButtons
            recalcView
            liveView

            Divider()

            historyView
        }
    }

    var headerView: some View {
        VStack {
            Text(ble.isConnected ? "Connected 🟢" : "Searching 🔴")
                .font(.headline)
                .padding(.top)

            Text("Robot Control")
                .font(.title2)
        }
    }

    var controlButtons: some View {
        HStack(spacing: 20) {

            Button("START") {
                ble.sendCommand("R")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Button("STOP") {
                ble.sendCommand("S")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
    }

    var recalcView: some View {
        Text("Last: \(ble.lastRecalc)")
            .foregroundColor(.orange)
            .padding(.bottom, 5)
    }
}

extension ContentView {

    var liveView: some View {

        Group {
            if let latest = ble.telemetryHistory.first {

                VStack(spacing: 6) {
                    Text("LIVE")
                        .font(.headline)

                    Text("Front: \(latest.front) cm")
                    Text("Left: \(latest.left) cm")
                    Text("Right: \(latest.right) cm")

                    Text("Maze: \(latest.mazeSize)x\(latest.mazeSize)")
                        .foregroundColor(.blue)

                    Text("State: \(latest.state)")
                        .fontWeight(.bold)

                    Text("Pos: (\(latest.x), \(latest.y)) dir: \(latest.dir)")
                        .foregroundColor(.purple)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
}

extension ContentView {

    var historyView: some View {

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
                        Text("Maze: \(t.mazeSize)x\(t.mazeSize)")
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
}
