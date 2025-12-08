//
//  HRVInfoDetails.swift
//  BLEStreaming
//
//  Created by Justin Laiti on 4/11/24.
//

import SwiftUI

enum HRVQuestion: String, CaseIterable, Identifiable {
    case whatIsHRV = "What is HRV?"
    case linkedToStress = "How is HRV linked to stress?"
    case influenceOnHRV = "What can influence my HRV?"
    case measurementMeaning = "How is my HRV measured?"
    case breathworkInfluence = "How can breathwork influence HRV?"
    case differentBreathingExercises = "What's the difference between breathing exercises?"
    
    var id: String { self.rawValue }
}

// Define a view model that will provide the content based on the selected question
class HRVAnswerProvider {
    static func answerView(for question: HRVQuestion) -> AnyView {
        switch question {
        case .whatIsHRV:
            return AnyView(
                VStack(alignment: .leading, spacing: 10) {
                    Text("Generally, HRV is a good indicator of our ability to adapt to changes throughout the day, but what exactly is it?")
                        .bold()
                    
                    Text("Heart rate variability (HRV) is a measure of the changing time between your heart beats.")
                    
                    Text("For example, if your heart is beating at 60 beats per minute, it won’t beat exactly on the second every time.")
                    
                    Image("HRVq1")
                        .resizable() // Makes the image resizable
                        .aspectRatio(contentMode: .fit) // Keeps the aspect ratio of the image
                        .frame(maxWidth: .infinity) // Ensures the image does not overflow
                        .padding() // Adds padding on the sides

                    Text("Put simply, a healthy heart is NOT a metronome. Instead, think of your heart rate like waves on the beach. They can break more quickly, or more spaced apart all depending on what’s going on in the ocean.")
                    
                    Text("Just like waves, our heart rate changes in response to daily events ranging from playing sports, taking a test, or taking a relaxing bath in the evening.")
                        
                    Text("For instance, when you are playing a sport, your muscles need more oxygen so your heart will beat more rapidly to deliver oxygenated blood to your exercising muscles. On the other hand, when you are winding down before bed, your heart rate will decrease.")
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("References:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Link("1. HRV and Stress Research", destination: URL(string: "https://pubmed.ncbi.nlm.nih.gov/29034226/")!)
                        Link("2. HRV Explained - NCBI", destination: URL(string: "https://www.ncbi.nlm.nih.gov/books/NBK539845/")!)
                        Link("3. HRV Study on Athletes", destination: URL(string: "https://pubmed.ncbi.nlm.nih.gov/30872091/")!)
                    }
                    .foregroundColor(.blue) // Ensures links appear styled as clickable
                    .padding(.top, 5)
                }
                .padding()
            )
            // Add more text and images as needed
        case .linkedToStress:
            return AnyView(
                
                VStack(alignment: .leading, spacing: 10) {
                
                    Text("Variations in your heart rate (HRV) are due to the dynamic nature of our nervous systems. Within part of the nervous system there is the sympathetic nervous system (SNS) and the parasympathetic nervous system (PNS). Activation of the SNS evokes the “fight or flight” response, whereas activation of the PNS promotes the “rest and digest” response.")
                        
                    Text("The PNS can thought of us as a break pedal to your heart rate, while the SNS as an accelerator pedal.")
                            .bold()
                        
                    Text("There is a constant tug a war between the SNS and PNS which results in a balanced heart rate appropriate for the environment or situation you’re currently in. Our bodies need to be able to rapidly alternate between these two states in order to respond to environmental and psychological challenges.")
                        
                    Text("HRV is a measure of flexibility and adaptability of our heart and nervous system to adapt to environmental and internal physiological challenges throughout our day.")
                    
                    Text("References:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Link("1. HRV and Stress Research", destination: URL(string: "https://pubmed.ncbi.nlm.nih.gov/29034226/")!)
                    }
                    .foregroundColor(.blue) // Ensures links appear styled as clickable
                    .padding(.top, 5)
                    
                }
                .padding()
            )
        case .influenceOnHRV:
            return AnyView(
                
                VStack(alignment: .leading, spacing: 10) {
                
                    Text("HRV is influenced by a wide range of factors including  your genetics, school environment, personality, fitness, stress levels, and caffeine intake.")
                        
                    Text("The average range for SDNN and RMSDD for adolescent females ranges 100.60 to 132.00 and 77.00 to 119.10 respectively. For males, 82.20 to 117.75 and 77.55 to 125.05 respectively.")
                        
                    Text("As you can tell, even the average in adolescents is highly variable so there is really no point in comparing HRVs with your friends.")
                        .bold()
                        
                    Text("Different raw HRV numbers can mean different things for different people and these numbers change throughout the day and between days.")
                    
                    Text("Instead, it is more helpful to look at how your own HRV is changing over time and compare it to different lifestyle habits and events in your environment.")
                    
                    Text("References:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Link("1. HRV Value Range", destination: URL(string: "https://pubmed.ncbi.nlm.nih.gov/26557514/")!)
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 5)

                    
                }
                .padding()
            )
        case .measurementMeaning:
            return AnyView(
                
                VStack(alignment: .leading, spacing: 10) {
                
                    Text("HRV can be measured outside of a clinical context via photoplethysmography (PPG). This means a small light source can detect blood volume changes at the surface of your skin and hence determine your HRV. There are a couple of different ways to measure HRV.")
                    
                    Text("PPG can be measured using green, red, or infared light. Your wearable uses infared light which penentrates deaper into your wrist and is less affected by different skin tones. Infared is not in the visible light spectrum, so you wont be able to see it when it's on.")
                    
                    Text("Calming Response (RMSSD - Root mean squared of standard differences)")
                        .font(.headline)
                        .padding(.top)
                        
                    Text("RMSDD is a mathematic calculation of the average difference between heartbeats that are next to eachother.")
                         
                    Text("This indicates the activity of your body’s calming response.  This is called vagal tone and it represents your systems ability to counterbalance stress activity and “rest and digest.”")
                    
                    Text("Return to Balance (SDNN - Standard deviation of peak-to-peak intervals)")
                        .font(.headline)
                        .padding(.top)
                        
                    Text("SDNN is a similar calculation of the average difference of all the heartbeats, but instead of only looking at how this changes for adjacent beats, it looks at the overall spread of beats within a recording time.")
                         
                    Text("This indicates the overall balance between your “fight or flight” and “rest and digest” response. Both healthy stress and relaxation are necessary for our bodies to respond to our environments, these just need to be in equilibrium. SDNN is a measure of this balance.")
                    
                    Text("These are the two metrics focused on in this app, but there are many different ways to measure HRV!")
                        .bold()
                        .padding(.top)
                    
                    Text("References:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Link("1. HRV Metric Explanations", destination: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5624990/")!)
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 5)
                    
                }
                .padding()
            )

        case .breathworkInfluence:
            return AnyView(
                VStack(alignment: .leading, spacing: 10) {
                    Text("Breathwork has a significant impact on HRV by directly influencing the parasympathetic nervous system (PNS), which helps to promote relaxation and recovery.")
                    Text("Practices such as slow, deep breathing increase HRV by activating the PNS, leading to a decrease in heart rate and an increase in heart rate variability. This is often seen as the heart's ability to shift gears efficiently, reflecting better stress management and resilience.")
                    Text("Breathwork can be used as a powerful tool for calming the mind and body, particularly before stressful events or as a regular practice to enhance overall well-being.")
                    Text("Regular engagement in breathwork exercises can lead to long-term improvements in HRV, indicating a robust and responsive nervous system.")
                    
                    Text("References:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Link("1. The impact of resonance breathing", destination: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5575449/")!)
                        Link("1. Cognitive boost of resonance breathing", destination: URL(string: "https://pubmed.ncbi.nlm.nih.gov/35308668/")!)
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 5)
                }
                .padding()
            )

        case .differentBreathingExercises:
            return AnyView(
                VStack(alignment: .leading, spacing: 10) {
                    Text("Different breathing exercises can have varying effects on HRV, as they engage the nervous system in different ways.")
                    Text("For example, rhythmic breathing such as the 4-7-8 technique, where you inhale for 4 seconds, hold for 7 seconds, and exhale for 8 seconds, can significantly increase HRV by promoting relaxation.")
                    Text("Conversely, quick breathing techniques, often used in stress response training, might decrease HRV temporarily but are used to train the body's ability to handle stress more effectively.")
                    Text("Choosing the right breathing exercise depends on your goals, whether you aim to calm down quickly, enhance focus, or improve your overall heart health and stress resilience.")
                }
                .padding()
            )

        }
    }
}
