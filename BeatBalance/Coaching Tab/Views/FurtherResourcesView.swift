//
//  FurtherResourcesView.swift
//  BeatBalance
//
//  Created by Justin Laiti on 11/17/24.
//

import SwiftUI

struct FurtherResourcesView: View {
    @EnvironmentObject var userManager: AuthManager
    
    let resources = [
        ("Jigsaw", "https://jigsaw.ie/", "Free mental health support for young people, offering advice, online chats, and in-person services."),
        ("Childline", "https://www.childline.ie/", "A free, confidential, and 24/7 support service for   young people, available via phone, chat, or text."),
        ("Belong To", "https://www.belongto.org/", "Support for LGBTQ+ young people in Ireland, promoting mental health, acceptance, and advocacy."),
        ("spunout", "https://spunout.ie/", "Ireland’s youth information hub offering articles, resources, and support on mental health, education, and wellbeing."),
        ("HSE Recommended Mental Health Services", "https://www2.hse.ie/mental-health/services-support/supports-services/", "Ireland's public mental health services, providing information on available supports and guidance for accessing care.")
    ]
    
    var body: some View {
        NavigationView {
            List(resources, id: \.0) { resource in
                VStack(alignment: .leading) {
                    HStack {
                        Text(resource.0)
                            .font(.headline)
                        Spacer()
                        Link(destination: URL(string: resource.1)!) {
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.blue)
                        }
                    }
                    Text(resource.2) // Add the description
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                }
                .padding(.vertical, 5) // Add spacing between items
            }
            .navigationTitle("Further Supports")
            .onAppear {
                userManager.viewDidAppear(screen: "Further supports")
            }
        }
    }
}

#Preview {
    FurtherResourcesView()
}
