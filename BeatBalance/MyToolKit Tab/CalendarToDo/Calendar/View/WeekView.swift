//
//  Calendar.swift
//  CalendarToDo
//
//  Created by Justin Laiti on 1/14/24.
//

import SwiftUI
import CoreData

struct WeekView: View {
    @StateObject var weekStore = WeekStore()
    @StateObject var toDoListManager = ToDoListManager()
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var userManager: AuthManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
            if let currentWeek = weekStore.currentWeek {
                VStack(alignment: .leading) {
                    
                    HStack {
                        Button {
                            weekStore.adjustWeek(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .padding(.leading)
                        
                        Spacer()
                        
                        // Display the month
                        if let monthAtDayOne = currentWeek.dates.first {
                            Text(DateFormatterService.monthString(from: monthAtDayOne))
                                .font(.title3)
                                .padding(10)
                        }
                        
                        Spacer()
                        
                        Button {
                                weekStore.adjustWeek(by: 1)
                        } label: {
                                Image(systemName: "chevron.right")
                        }
                        .padding(.trailing)
                    }
                    
                    // Display the week
                    HStack {
//                        Spacer()
                        ForEach(currentWeek.dates, id: \.self) { date in
                            NavigationLink {
                                ToDoList(toDoListManager: toDoListManager, selectedDate: date)
                            } label: {
                                VStack {
                                    Text(DateFormatterService.dayOfWeekLetter(from: date))
                                        .bold()
                                    
                                    ZStack {
                                        
                                        if let ratio = toDoListManager.taskCompletionRatios[date] {
                                            TaskCircle(ratioOfCompletedTasks: ratio)
                                        } else {
                                            Circle()
                                                .stroke(lineWidth: 5)
                                                .opacity(0)
                                        }
                                        
                                        Text(DateFormatterService.dayOfMonthString(from: date))
                                            .bold(isToday(date: date))

                                    }
                                    .frame(maxWidth: .infinity)
                                    .onAppear {
                                        if let currentWeek = weekStore.currentWeek {
                                            Task {
                                                await toDoListManager.updateCompletionRatios(for: currentWeek.dates)
                                            }
                                        }
                                    }
                                    
                                }
                                .foregroundStyle(isToday(date: date) ? settings.primaryColor : .primary)
                            }
//                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(10)
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
                .edgesIgnoringSafeArea(.all)
                
            } else {
                Text("No data available")
            }
    }

    func isToday(date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
}



#Preview {
    WeekView(weekStore: WeekStore(), toDoListManager: ToDoListManager())
}
