//
//  BLEManager.swift
//  Maze solver Bluetooth connection app
//
//  Created by Kuba Kromołowski on 15/03/2026.
//

import Foundation
import CoreBluetooth
import SwiftUI
import Combine

struct Telemetry {

    let timestamp = Date()

    let front: Int
    let left: Int
    let right: Int

    let mazeSize: Int

    let state: String

    let x: Int
    let y: Int
    let dir: Int
    let walls: Int

    let value: Int
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var telemetryCharacteristic: CBCharacteristic?

    private var buffer = ""

    private var isReceivingMaze = false
    private var mazeBuffer: [String] = []

    @Published var telemetryHistory: [Telemetry] = []
    @Published var mazeDebug: [[Int]] = []
    @Published var lastRecalc: String = ""
    @Published var isConnected = false

    let serviceUUID = CBUUID(string: "FFE0")
    let characteristicUUID = CBUUID(string: "FFE1")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        if central.state == .poweredOn {
            print("BLE ready → scanning")
            centralManager.scanForPeripherals(withServices: nil)
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        guard let name = peripheral.name else { return }

        if name.contains("BT05") || name.contains("HMSoft") {

            self.peripheral = peripheral
            centralManager.stopScan()
            centralManager.connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {

        DispatchQueue.main.async {
            self.isConnected = true
        }

        print("Connected to \(peripheral.name ?? "device")")

        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {

        guard let services = peripheral.services else { return }

        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {

        guard let characteristics = service.characteristics else { return }

        for char in characteristics {

            if char.uuid == characteristicUUID {

                telemetryCharacteristic = char
                peripheral.setNotifyValue(true, for: char)

                print("Subscribed to telemetry")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {

        guard let data = characteristic.value,
              let chunk = String(data: data, encoding: .utf8) else { return }

        buffer += chunk

        let lines = buffer.components(separatedBy: "\n")

        for i in 0..<(lines.count - 1) {
            parseLine(lines[i])
        }

        buffer = lines.last ?? ""
    }

    func parseLine(_ line: String) {

        let clean = line.trimmingCharacters(in: .whitespacesAndNewlines)

        if clean.isEmpty { return }

        if clean == "MAZE_START" {
            isReceivingMaze = true
            mazeBuffer = []
            return
        }

        if clean == "MAZE_END" {

            let parsed = mazeBuffer.map {
                $0.split(separator: ",").compactMap { Int($0) }
            }

            DispatchQueue.main.async {
                self.mazeDebug = parsed
            }

            isReceivingMaze = false
            return
        }

        if clean.starts(with: "RECALC") {
            DispatchQueue.main.async {
                self.lastRecalc = clean
            }
            return
        }

        if isReceivingMaze {
            mazeBuffer.append(clean)
            return
        }

        parseTelemetry(clean)
    }

    func parseTelemetry(_ string: String) {

        let parts = string.split(separator: ",")

        guard parts.count == 10 else {
            print("❌ Bad telemetry:", string)
            return
        }

        let telemetry = Telemetry(
            front: Int(parts[0]) ?? 0,
            left:  Int(parts[1]) ?? 0,
            right: Int(parts[2]) ?? 0,

            mazeSize: Int(parts[3]) ?? 16,

            state: String(parts[4]),
            x: Int(parts[5]) ?? 0,
            y: Int(parts[6]) ?? 0,
            dir: Int(parts[7]) ?? 0,
            walls: Int(parts[8]) ?? 0,
            value: Int(parts[9]) ?? 255
        )

        DispatchQueue.main.async {

            self.telemetryHistory.insert(telemetry, at: 0)

            if self.telemetryHistory.count > 300 {
                self.telemetryHistory.removeLast()
            }
        }
    }

    func sendCommand(_ command: String) {

        guard let peripheral = peripheral,
              let characteristic = telemetryCharacteristic else { return }

        let data = command.data(using: .utf8)!

        peripheral.writeValue(
            data,
            for: characteristic,
            type: .withoutResponse
        )
    }
}
