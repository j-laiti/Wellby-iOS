//
//  BLEController.swift
//  BLEStreaming
//
//  Created by Justin Laiti on 3/30/24.
//

import CoreBluetooth
import SwiftUI

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var peripherals = [CBPeripheral]()
    @Published var isConnected = false
    @Published var isRecording = false
    @Published var beginRecoringViewEnabled = false
    @Published var startRecording = false
    @Published var sdnn = "--"
    @Published var rmssd = "--"
    @Published var averageHR = "--"
    @Published var signalQuality = "--"
    @Published var batteryStatus = ""
    //@ObservedObject var hrvDataManager: HRVDataManager
    
    var centralManager: CBCentralManager! //manages ble hardware interactions
    var connectedPeripheral: CBPeripheral?
    
    let xiaoServiceUUID = CBUUID(string: "2ef946af-49fc-43f4-95c1-882a483f0a76")
    let hrvCharacteristicUUID = CBUUID(string: "8881ab16-7694-4891-aebe-b0b11c6549d4")
    let rawPpgCharacteristicUUID = CBUUID(string: "4aa76196-2777-4205-8260-8e3274beb327")
    let batteryCharacteristicUUID = CBUUID(string: "a20a1ce0-5f2e-4230-88fe-05eb329dc545")
    let recordingControlCharacteristicUUID = CBUUID(string: "684c8f42-a60c-431c-b8ed-251e966d6a9a")
    
    var recordingControlCharacteristic: CBCharacteristic?
    
    var scanTimer: Timer?
    let scanTimeoutSeconds = 10.0
    @Published var isScanning = false
    @Published var displayPeripherals = false
    @Published var searchingForSavedDevice = false
    
    @Published var sessionID = UUID()
    
    // info for the raw PPG reading
    @Published var rawPPGReadings: [Double] = []
    private var rawPPGBuffer: [Double] = []  // Buffer for raw readings before smoothing
    private let smoothingWindowSize = 3  // Window size for moving average filter
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // required delegate method to manage state updates
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
        }

    }
    
    // called when peripherals are discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        DispatchQueue.main.async {
            if !self.peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                self.peripherals.append(peripheral)
            }
        }
    }
    
    func connect(to peripheral: CBPeripheral) {
            centralManager.connect(peripheral, options: nil)
            connectedPeripheral = peripheral
            peripheral.delegate = self
        }
        
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        searchingForSavedDevice = false
        stopScanning()
        peripheral.discoverServices([xiaoServiceUUID])
        
        // save the connected peripheral so it can try to autoconnect next time :)
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: "lastConnectedPeripheralId")
    }
    
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedPeripheral = nil
    }

    func startScanning() {
        if centralManager.state == .poweredOn {
            peripherals.removeAll()
            isScanning = true

            centralManager.scanForPeripherals(withServices: [xiaoServiceUUID], options: nil)

            // Invalidate any existing timer
            scanTimer?.invalidate()

            // Start a new timer
            scanTimer = Timer.scheduledTimer(withTimeInterval: scanTimeoutSeconds, repeats: false) { [weak self] _ in
                // Stop scanning when the timer fires
                self?.stopScanning()
                // Optionally, notify the user or update the UI here to indicate that scanning has stopped
            }
        }
    }

    func stopScanning() {
        if isScanning {
            centralManager.stopScan()
            isScanning = false
            scanTimer?.invalidate() // Invalidate the timer as we're manually stopping scanning
        }
    }
    
    func reconnectToPeripheral(with identifier: UUID) {
        searchingForSavedDevice = true
        
        let knownPeripherals = centralManager.retrievePeripherals(withIdentifiers: [identifier])
        if let peripheralToReconnect = knownPeripherals.first {
            connect(to: peripheralToReconnect)
            
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                if !(self?.isConnected ?? false) {
                        self?.searchingForSavedDevice = false
                        self?.togglePeripheralDisplay()
                        self?.startScanning()
                    }
                }
        } else {
            togglePeripheralDisplay()
            startScanning()
        }
    }
    
    func forgetDevice() {
        UserDefaults.standard.removeObject(forKey: "lastConnectedPeripheralId")
        isConnected = false
        connectedPeripheral = nil
        stopScanning()
    }

    func togglePeripheralDisplay() {
        displayPeripherals.toggle()
    }
    
    // Peripheral Delegate Methods
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == xiaoServiceUUID {
                peripheral.discoverCharacteristics([
                    hrvCharacteristicUUID,
                    rawPpgCharacteristicUUID,
                    batteryCharacteristicUUID,
                    recordingControlCharacteristicUUID
                ], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            switch characteristic.uuid {
            case hrvCharacteristicUUID:
                peripheral.setNotifyValue(true, for: characteristic)
                print("HRV Characteristic found.")
            case rawPpgCharacteristicUUID:
                peripheral.setNotifyValue(true, for: characteristic)
                print("Raw PPG Characteristic found.")
            case recordingControlCharacteristicUUID:
                // Save a reference to the recording control characteristic for later use
                self.recordingControlCharacteristic = characteristic
                print("Recording Characteristic found.")
            case batteryCharacteristicUUID:
                peripheral.setNotifyValue(true, for: characteristic)
                print("Battery Characteristic found.")
            default:
                print("Discovered other characteristic: \(characteristic.uuid)")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            switch characteristic.uuid {
            case hrvCharacteristicUUID:
                publishCharacteristicData(value)
            case rawPpgCharacteristicUUID:
                if beginRecoringViewEnabled {
                    // new logic to upload raw data and display it in real time
                    HRVDataManager.shared.uploadRawDataToFirebase(sessionID: sessionID.uuidString, data: value)
                    
                    let hexString = value.map { String(format: "%02x", $0) }.joined()
                    let regexPattern = "(\\w{4})(fe)"
                    let regex = try! NSRegularExpression(pattern: regexPattern, options: [])
                    let matches = regex.matches(in: hexString, options: [], range: NSRange(location: 0, length: hexString.utf16.count))
                    
                    let readings = matches.compactMap {
                        if let intValue = Int(String(hexString[Range($0.range(at: 1), in: hexString)!]), radix: 16) {
                            return Double(intValue)
                        }
                        return nil
                    }
                    
                    DispatchQueue.main.async {
                        // Add each raw reading to buffer and smooth it
                        self.rawPPGBuffer.append(contentsOf: readings)
                        
                        // Smooth the buffer
                        if self.rawPPGBuffer.count >= self.smoothingWindowSize {
                            let smoothedValue = self.rawPPGBuffer.suffix(self.smoothingWindowSize).reduce(0, +) / Double(self.smoothingWindowSize)
                            self.rawPPGReadings.append(smoothedValue)
                            
                            // Limit rawPPGReadings to a certain number of points to prevent memory overload
                            if self.rawPPGReadings.count > 20 {
                                self.rawPPGReadings.removeFirst(self.rawPPGReadings.count - 20)
                            }
                            
                            // Remove the oldest data from the buffer to maintain the window size
                            self.rawPPGBuffer.removeFirst(readings.count)
                        }
                    }
                }
            case batteryCharacteristicUUID:
                print("we got this far buddy")
                
                let batteryLevelByte = [UInt8](value)[0]
                var batteryLevelString = ""
                switch batteryLevelByte {
                case 0x52: // ASCII for 'R'
                    batteryLevelString = "R"
                case 0x59: // ASCII for 'Y'
                    batteryLevelString = "Y"
                case 0x47: // ASCII for 'G'
                    batteryLevelString = "G"
                default:
                    batteryLevelString = "Unknown"
                }
                DispatchQueue.main.async {
                    self.batteryStatus = batteryLevelString
                    print("Battery status updated: \(batteryLevelString)")
                }
            default:
                break
            }
        }
    }
    
    private func publishCharacteristicData(_ data: Data) {
        // Filter out non-printable and irrelevant characters before attempting to decode
        let printableData = data.filter { byte in
            (byte >= 48 && byte <= 57) || // Numeric 0-9
            byte == 32 || // Space
            byte == 46 || // Period '.'
            byte == 71 || // 'G'
            byte == 80 || // 'P'
            byte == 69 || // 'E'
            byte == 73    // 'I'
        }

        if let dataString = String(data: printableData, encoding: .utf8) {
            print("Received data string: \(dataString)")
            processReceivedData(dataString)
        } else {
            print("Decoding Error: Data could not be decoded to String")
            print("Hex dump of received data: \(data.map { String(format: "%02hhx", $0) }.joined(separator: " "))")
        }
    }

    private func processReceivedData(_ dataString: String) {
        let components = dataString.split(separator: " ")
        if components.count == 4,
            let sdnn = Float(components[0]),
            let rmssd = Float(components[1]),
            let averageHR = Float(components[2]),
            let signalQualityChar = components[3].first {
            
            // Formatting the float values to a string with two decimal places
            let formattedSdnn = String(format: "%.1f", sdnn)
            let formattedRmssd = String(format: "%.1f", rmssd)
            let formattedAverageHR = String(format: "%.1f", averageHR)

            DispatchQueue.main.async {
                self.sdnn = formattedSdnn
                self.rmssd = formattedRmssd
                self.averageHR = formattedAverageHR
                self.signalQuality = self.describeSignalQuality(from: signalQualityChar)
            }
        } else {
            print("Parsing Error: Data format is incorrect")
        }
    }


    private func describeSignalQuality(from char: Character) -> String {
        switch char {
        case "I": return "Invalid"
        case "P": return "Low"
        case "G": return "Good"
        case "E": return "Excellent"
        default: return "Unknown"
        }
    }
    
    // new - function to initiate PPG recording from the app!
    func startPPGRecording() {        
        print("Starting recording with sessionID: \(self.sessionID)")
        
        guard isConnected, let peripheral = connectedPeripheral, let characteristic = recordingControlCharacteristic else {
            print("No connected peripheral or recording characteristic not found.")
            return
        }

        // Write the value 0x01 to start recording
        let startValue: UInt8 = 0x01
        let data = Data([startValue])
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        
        beginRecoringViewEnabled = true
    }

    // also new
    func stopPPGRecording() {
        guard isConnected, let peripheral = connectedPeripheral, let characteristic = recordingControlCharacteristic else {
            print("No connected peripheral or recording characteristic not found.")
            return
        }

        // Write the value 0x00 to stop recording
        let stopValue: UInt8 = 0x00
        let data = Data([stopValue])
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        
//        beginRecoringViewEnabled = false // make the view close
    }
    
    func flushRemainingPPGData() {
        // This ensures any buffered data gets uploaded before processing
        // The rawPPGBuffer in HRVDataManager needs to be flushed
        HRVDataManager.shared.flushRawDataBuffer(sessionID: sessionID.uuidString)
    }
    
//    func startSession() {
//        isRecording = true
//        self.sessionID = UUID()
//        print("new UUID set: \(self.sessionID)")
//    }
    
    // check this in the recording screen/if isRecording is needed
//    func endSession() {
//        isRecording = false
//        beginRecoringViewEnabled = false
//        startRecording = false
//    }

}
