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
        var value: Int = 255
    }

    @Published var width: Int = 16
    @Published var height: Int = 16

    @Published var grid: [[Cell]] = []

    init() {
        resize(width: 16, height: 16)
    }

    func resize(width: Int, height: Int) {

        self.width = width
        self.height = height

        grid = Array(
            repeating: Array(repeating: Cell(), count: height),
            count: width
        )
    }

    func update(_ t: Telemetry) {

        guard t.x >= 0 && t.x < width && t.y >= 0 && t.y < height else { return }

        grid[t.x][t.y].visited = true
        grid[t.x][t.y].walls = t.walls
        grid[t.x][t.y].value = t.value
    }

    func hasWall(x: Int, y: Int, dir: Int) -> Bool {
        guard x < width && y < height else { return false }
        return (grid[x][y].walls & (1 << dir)) != 0
    }

    func updateFromMazeDebug(_ gridValues: [[Int]]) {

        guard !gridValues.isEmpty else { return }

        let newHeight = gridValues.count
        let newWidth = gridValues[0].count

        if newWidth != width || newHeight != height {
            resize(width: newWidth, height: newHeight)
        }

        for y in 0..<newHeight {
            for x in 0..<newWidth {

                let newValue = gridValues[y][x]
                let oldValue = grid[x][y].value

                if newValue == 255 && oldValue != 255 {
                    continue
                }

                if newValue != oldValue {
                    grid[x][y].value = newValue
                }

                if newValue != 255 {
                    grid[x][y].visited = true
                }
            }
        }
    }
}
