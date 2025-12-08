//
//  PeripheralSheetView.swift
//  BLEStreaming
//
//  Created by Justin Laiti on 4/10/24.
//

import SwiftUI

struct PeripheralSheetView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Binding var deviceID: String

    var body: some View {
        
        NavigationView {
            VStack {
                
                if !bluetoothManager.isConnected {
                    Text("Device Search")
                    TextField("Enter your device ID", text: $deviceID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    if bluetoothManager.isScanning {
                        Text("Scanning...")
                            .foregroundStyle(.secondary)
                    }
                    
                    //TODO: update this peripheral search to find the wearable
                    List(bluetoothManager.peripherals.filter { peripheral in
                        
                        guard deviceID.count == 3 else {
                            return false
                        }
                        return peripheral.name?.hasSuffix(deviceID) ?? false
                        
                    }, id: \.identifier) { peripheral in
                        HStack {
                            Text(peripheral.name ?? "Unknown Device")
                            
                            Button("Connect") {
                                bluetoothManager.connect(to: peripheral)
                                bluetoothManager.togglePeripheralDisplay()
                            }
                        }
                    }
                } else if let peripheral = bluetoothManager.connectedPeripheral {
                    
                    Text("Connected to \(peripheral.name ?? "device")")
                    
                    Button("Disconnect") {
                        bluetoothManager.disconnect()
                    }
                    
                    Button("Forget Device") {
                        bluetoothManager.disconnect()
                        bluetoothManager.forgetDevice()
                    }
                }

            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        bluetoothManager.togglePeripheralDisplay()
                    }
                }
            }
        }
    }
}
