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
    let angle: Int
    let state: String
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var telemetryCharacteristic: CBCharacteristic?

    private var buffer = ""

    @Published var telemetryHistory: [Telemetry] = []
    @Published var isConnected = false

    private var latestTelemetry: Telemetry?
    private var timer: Timer?

    let serviceUUID = CBUUID(string: "FFE0")
    let characteristicUUID = CBUUID(string: "FFE1")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        startTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in // TIMER 100MS

            guard let telemetry = self.latestTelemetry else { return }

            DispatchQueue.main.async {

                self.telemetryHistory.insert(telemetry, at: 0)

                if self.telemetryHistory.count > 300 {
                    self.telemetryHistory.removeLast()
                }
            }
        }
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
            parseTelemetry(lines[i])
        }

        buffer = lines.last ?? ""
    }

    func parseTelemetry(_ string: String) {

        let clean = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = clean.split(separator: ",")

        if parts.count == 5 {

            let telemetry = Telemetry(
                front: Int(parts[0]) ?? 0,
                left:  Int(parts[1]) ?? 0,
                right: Int(parts[2]) ?? 0,
                angle: Int(parts[3]) ?? 0,
                state: String(parts[4])
            )

            latestTelemetry = telemetry

        } else {
            print("BAD DATA:", clean)
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
