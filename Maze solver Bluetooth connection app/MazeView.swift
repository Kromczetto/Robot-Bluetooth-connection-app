//
//  MazeView.swift
//  Maze solver Bluetooth connection app
//
//  Created by Kuba Kromołowski on 11/04/2026.
//

import SwiftUI

struct MazeView: View {

    @ObservedObject var maze: MazeModel
    var telemetry: Telemetry?

    var body: some View {

        GeometryReader { geo in

            let cell = geo.size.width / CGFloat(maze.width)

            ZStack {

                ForEach(0..<maze.width, id: \.self) { x in
                    ForEach(0..<maze.height, id: \.self) { y in

                        let posX = CGFloat(x) * cell + cell / 2
                        let posY = CGFloat(maze.height - 1 - y) * cell + cell / 2

                        ZStack {

                            Rectangle()
                                .fill(maze.grid[x][y].visited ? Color.green.opacity(0.2) : Color.clear)

                            Path { path in

                                let w = cell
                                let h = cell

                                if maze.hasWall(x: x, y: y, dir: 0) {
                                    path.move(to: CGPoint(x: 0, y: 0))
                                    path.addLine(to: CGPoint(x: w, y: 0))
                                }

                                if maze.hasWall(x: x, y: y, dir: 1) {
                                    path.move(to: CGPoint(x: w, y: 0))
                                    path.addLine(to: CGPoint(x: w, y: h))
                                }

                                if maze.hasWall(x: x, y: y, dir: 2) {
                                    path.move(to: CGPoint(x: 0, y: h))
                                    path.addLine(to: CGPoint(x: w, y: h))
                                }

                                if maze.hasWall(x: x, y: y, dir: 3) {
                                    path.move(to: CGPoint(x: 0, y: 0))
                                    path.addLine(to: CGPoint(x: 0, y: h))
                                }
                            }
                            .stroke(Color.white, lineWidth: 2)

                            let value = maze.grid[x][y].value

                            Text(value == 255 ? "?" : "\(value)")
                                .font(.system(size: cell * 0.35, weight: .bold))
                                .foregroundColor(value == 255 ? .gray : .white)
                        }
                        .frame(width: cell, height: cell)
                        .position(x: posX, y: posY)
                    }
                }

                Circle()
                    .stroke(Color.yellow, lineWidth: 3)
                    .frame(width: cell * 0.7, height: cell * 0.7)
                    .position(
                        x: CGFloat(maze.goalX) * cell + cell / 2,
                        y: CGFloat(maze.height - 1 - maze.goalY) * cell + cell / 2
                    )

                if let t = telemetry {

                    Circle()
                        .fill(Color.red)
                        .frame(width: cell * 0.6, height: cell * 0.6)
                        .position(
                            x: CGFloat(t.x) * cell + cell / 2,
                            y: CGFloat(maze.height - 1 - t.y) * cell + cell / 2
                        )
                }
            }
        }
    }
}
