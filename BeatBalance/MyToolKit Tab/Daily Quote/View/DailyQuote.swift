//
//  DailyQuote
//
//  Created by Justin Laiti on 1/30/24.
//

import SwiftUI

struct DailyQuote: View {
    @StateObject var quoteManager = QuoteManager()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
    
            VStack {
                if let quote = quoteManager.todaysQuote {
                    Text("\"\(quote.quote)\"")
                        .fontWeight(.medium)
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                    
                    Text("- \(quote.author)")
                        .foregroundStyle(.secondary)
                } else {
                    Text("No quote available")
                        .italic()
                }
            }
            .padding()
            .background(
                Group {
                    if colorScheme == .light {
                        Color.white
                    } else {
                        Color.gray.opacity(0.3)
                    }
                })
            .cornerRadius(25)
            .shadow(radius: 5)
            .padding(.horizontal)
            
    }
}
