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

// MARK: - Telemetry Model

struct Telemetry: Identifiable {

    let id = UUID()

    let front: Int
    let left: Int
    let right: Int
    let state: String
}


// MARK: - BLE Manager

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?

    private var telemetryCharacteristic: CBCharacteristic?

    // historia danych z robota
    @Published var telemetryHistory: [Telemetry] = []

    @Published var isConnected = false

    let serviceUUID = CBUUID(string: "FFE0")
    let characteristicUUID = CBUUID(string: "FFE1")


    override init() {
        super.init()

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }


    // MARK: Bluetooth state

    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        if central.state == .poweredOn {

            print("BLE ready → scanning")

            centralManager.scanForPeripherals(withServices: nil)
        }
    }


    // MARK: Device found

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        guard let name = peripheral.name else { return }

        print("Found device:", name)

        // dopasowanie do BT05
        if name.contains("BT05") || name.contains("HMSoft") {

            self.peripheral = peripheral

            centralManager.stopScan()

            centralManager.connect(peripheral)
        }
    }


    // MARK: Connected

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {

        print("Connected to BLE device")

        DispatchQueue.main.async {
            self.isConnected = true
        }

        peripheral.delegate = self

        peripheral.discoverServices([serviceUUID])
    }


    // MARK: Services

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {

        guard let services = peripheral.services else { return }

        for service in services {

            if service.uuid == serviceUUID {

                peripheral.discoverCharacteristics(
                    [characteristicUUID],
                    for: service
                )
            }
        }
    }


    // MARK: Characteristics

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {

        guard let characteristics = service.characteristics else { return }

        for char in characteristics {

            if char.uuid == characteristicUUID {

                telemetryCharacteristic = char

                peripheral.setNotifyValue(true, for: char)

                print("Notifications enabled")
            }
        }
    }


    // MARK: Receive data

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {

        guard let data = characteristic.value,
              let string = String(data: data, encoding: .utf8) else { return }

        parseTelemetry(string)
    }


    // MARK: Parse telemetry

    func parseTelemetry(_ string: String) {

        let clean = string.trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = clean.split(separator: ",")

        if parts.count == 4 {

            let front = Int(parts[0]) ?? 0
            let left  = Int(parts[1]) ?? 0
            let right = Int(parts[2]) ?? 0
            let state = String(parts[3])

            let telemetry = Telemetry(
                front: front,
                left: left,
                right: right,
                state: state
            )

            DispatchQueue.main.async {

                // dodaj na początek historii
                self.telemetryHistory.insert(telemetry, at: 0)

                // limit historii (żeby RAM nie rósł w nieskończoność)
                if self.telemetryHistory.count > 300 {
                    self.telemetryHistory.removeLast()
                }
            }
        }
    }


    // MARK: Send command to robot

    func sendCommand(_ command: String) {

        guard let peripheral = peripheral,
              let characteristic = telemetryCharacteristic else { return }

        let data = command.data(using: .utf8)!

        peripheral.writeValue(
            data,
            for: characteristic,
            type: .withoutResponse   // ważne
        )
    }
}
