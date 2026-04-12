//
//  MazeModel.swift
//  Maze solver Bluetooth connection app
//
//  Created by Kuba Kromołowski on 11/04/2026.
//
import Foundation
import Combine

class MazeModel: ObservableObject {

    struct Cell {
        var visited = false
        var walls: Int = 0
    }

    @Published var grid: [[Cell]] =
        Array(repeating: Array(repeating: Cell(), count: 16), count: 16)

    func update(_ t: Telemetry) {

        guard t.x >= 0 && t.x < 16 && t.y >= 0 && t.y < 16 else { return }

        grid[t.x][t.y].visited = true
        grid[t.x][t.y].walls = t.walls
    }

    func hasWall(x: Int, y: Int, dir: Int) -> Bool {
        (grid[x][y].walls & (1 << dir)) != 0
    }
}
