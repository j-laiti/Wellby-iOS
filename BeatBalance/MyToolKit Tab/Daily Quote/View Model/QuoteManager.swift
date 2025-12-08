//
//  QuoteManager.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/31/24.
//

import Foundation

class QuoteManager: ObservableObject {
    @Published var todaysQuote: Quote?
    
    init() {
        self.todaysQuote = getTodaysQuote()
    }
    
    func getTodaysQuote() -> Quote? {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let targetID = (dayOfYear - 1) % 100 + 1 // Adjust if your IDs start from 0 or 1

        let decoder = JSONDecoder()
        if let quotes = try? decoder.decode([Quote].self, from: data) {
            return quotes.first { $0.id == targetID }
        }

        return nil
    }
    
}
