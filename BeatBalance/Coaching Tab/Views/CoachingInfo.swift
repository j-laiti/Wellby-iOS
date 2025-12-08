//
//  CoachingInfo.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/12/24.
//

import SwiftUI

struct CoachingInfo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Group {
                    Text("What is Health Coaching?")
                        .font(.title2)
                        .bold()
                    Text("Health coaching supports your lifestyle-related goals. Trained professionals, known as health coaches, provide support, guidance, and motivation toward improved health and wellbeing. Whether aiming to enhance your diet, increase exercise, or improve sleep habits, health coaches are there to support your journey.")
                }
                
                Group {
                    Text("What Health Coaching is Not")
                        .font(.title2)
                        .bold()
                        .padding(.top, 10)
                    Text("Health coaching is distinct from therapy. Unlike therapy, which addresses emotional or psychological issues, health coaching focuses on setting and achieving lifestyle goals.")
                }
                
                Group {
                    Text("How Can a Health Coach Support You as a Student?")
                        .font(.title2)
                        .bold()
                        .padding(.top, 10)
                    Text("• Navigate student life challenges.\n• Support lifestyle changes for stress management, better sleep, improved time management, and digital wellbeing.\n• Guide you to resources like Aware and Spunout, if needed.")
                }
                
                Group {
                    Text("How Are You Expected to Engage with Health Coaches?")
                        .font(.title2)
                        .bold()
                        .padding(.top, 10)
                    Text("Engagement with health coaches should be respectful, open, and in line with your school's code of behavior. These professionals volunteer their time to help you, aiming to build a supportive relationship focused on your well-being. Misconduct or disrespect can result in the loss of access to this support. The aim is to build a positive, supportive relationship focused on your wellbeing goals.")
                }
            }
            .padding()
        }
        .navigationTitle("Coaching Guidelines")
    }
}
