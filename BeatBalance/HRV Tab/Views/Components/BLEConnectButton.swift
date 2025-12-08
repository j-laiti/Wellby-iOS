//
//  BLEConnectButton.swift
//  BLEStreaming
//
//  Created by Justin Laiti on 4/10/24.
//

import SwiftUI

struct BLEConnectButton: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @State private var deviceID = ""

    var body: some View {
        HStack {
            Button {
                if bluetoothManager.isConnected {
                    bluetoothManager.togglePeripheralDisplay()
                } else {
                    
                    if let storedIdentifier = UserDefaults.standard.string(forKey: "lastConnectedPeripheralId"),
                       let uuid = UUID(uuidString: storedIdentifier) {
                        bluetoothManager.reconnectToPeripheral(with: uuid)
                    } else {
                        bluetoothManager.startScanning()
                        bluetoothManager.togglePeripheralDisplay()
                    }
                    
                    
                }
            } label: {
                Image(systemName: bluetoothManager.isConnected ? "applewatch" : "applewatch.slash")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .padding(.top, 10)
            }
            
            if bluetoothManager.searchingForSavedDevice {
                ProgressView()
            }
        }
        .sheet(isPresented: $bluetoothManager.displayPeripherals) {
            PeripheralSheetView(bluetoothManager: bluetoothManager, deviceID: $deviceID)
        }
    }
}
