//
//  UserSettings.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/31/24.
//
import Foundation
import SwiftUI

class UserSettings: ObservableObject {
    // this ensures there is only one instance of the Settings
    //static let shared = UserSettings()
    
    @Published var primaryColor: Color {
        // runs a set of code as soon as a property value is set
        didSet {
            UserDefaults.standard.set(primaryColor.toHex(), forKey: "primaryColor")
        }
    }
    
    @Published var secondaryColor: Color {
        didSet {
            UserDefaults.standard.set(secondaryColor.toHex(), forKey: "secondaryColor")
        }
    }
    
    @Published var displayQuote: Bool {
            didSet {
                UserDefaults.standard.set(displayQuote, forKey: "displayQuote")
            }
        }
    
    init() {
        primaryColor = Color(hex: UserDefaults.standard.string(forKey: "primaryColor") ?? Color.blue.toHex())
        secondaryColor = Color(hex: UserDefaults.standard.string(forKey: "secondaryColor") ?? Color.blue.toHex())
        if UserDefaults.standard.object(forKey: "displayQuote") == nil {
            displayQuote = true
        } else {
            displayQuote = UserDefaults.standard.bool(forKey: "displayQuote")
        }
    }
    
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        let components = self.cgColor?.components
        let r = components?[0] ?? 17/255
        let g = components?[1] ?? 90/255
        let b = components?[2] ?? 232/255

        return String(format: "#%02lX%02lX%02lX", lround(Double(r * 255)), lround(Double(g * 255)), lround(Double(b * 255)))
    }
}
