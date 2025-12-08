//
//  HRVInfoScreen.swift
//  BLEStreaming
//
//  Created by Justin Laiti on 4/11/24.
//

import SwiftUI

struct HRVInfoScreen: View {
    @State private var selectedQuestion: HRVQuestion = .whatIsHRV
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var userManager: AuthManager
    
    var body: some View {
        VStack {
            //Top section with Q bubble and person
            
            HStack {
                Spacer()
                
                VStack {
                    Picker("Select a question", selection: $selectedQuestion) {
                                    ForEach(HRVQuestion.allCases) { question in
                                        Text(question.rawValue).tag(question)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding()
                                .padding(.vertical,10)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                .shadow(radius: 2)
                    
                    Spacer()
                }
                
                Spacer()
                
                VStack {
                    Spacer()
                    
                    Image(systemName: "figure.wave")
                        .font(.system(size: 65))
                }
                
                Spacer()
                
            }
            .frame(height: 125)
            .padding()
            .background(settings.secondaryColor.opacity(0.3))
            .onAppear {
                userManager.viewDidAppear(screen: "HRV info")
            }
            
            
            ScrollView {
                HRVAnswerProvider.answerView(for: selectedQuestion)
            }
            
            
        }
    }
}

#Preview {
    HRVInfoScreen()
}
