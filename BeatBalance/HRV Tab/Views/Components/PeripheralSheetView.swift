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
                    TextField("Filter for your device ID", text: $deviceID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    if bluetoothManager.isScanning {
                        Text("Scanning...")
                            .foregroundStyle(.secondary)
                    }
                    
                    //TODO: update this peripheral search to find the wearable
                    List(bluetoothManager.peripherals, id: \.identifier) { peripheral in
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
