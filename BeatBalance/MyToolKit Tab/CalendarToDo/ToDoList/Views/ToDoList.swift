//
//  DailyToDo.swift
//  CalendarToDo
//
//  Created by Justin Laiti on 1/28/24.
//

import SwiftUI
import CoreData

struct ToDoList: View {
    @ObservedObject var toDoListManager: ToDoListManager
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var userManager: AuthManager
    @State private var newToDoTitle: String = ""
    var selectedDate: Date
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("To-do List")
                .font(.title2)
            
            // Date that was selected from the calendar
            Text(DateFormatterService.fullDateString(from: selectedDate))
                .foregroundStyle(.secondary)
            
            // Text field for new to-do item
            HStack {
                TextField("New to-do", text: $newToDoTitle)
                    .padding(.trailing, 30)
                    
                Button {
                    toDoListManager.addToDo(title: newToDoTitle, for: selectedDate)
                    newToDoTitle = "" // Clear the text field
                    toDoListManager.fetchToDos(for: selectedDate)
                    userManager.clickedOn(feature: "new todo created")
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
            .padding()
            
            // List to display to-do items
            List {
                ForEach(toDoListManager.items, id: \.self) { item in
                    HStack {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(item.isCompleted ? settings.primaryColor : .gray)
                        
                        Text(item.title)
                            .strikethrough(item.isCompleted, color: .gray)
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toDoListManager.completeToDo(item: item)
                        toDoListManager.fetchToDos(for: selectedDate)
                        userManager.clickedOn(feature: "todo completed")
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .background(.clear)
        
        }
        .padding(.horizontal)
        .onAppear {
            toDoListManager.fetchToDos(for: selectedDate)
            userManager.viewDidAppear(screen: "ToDoList")
        }
    }
    
    private func deleteItems(at offset: IndexSet) {
        offset.forEach { index in
            let item = toDoListManager.items[index]
            toDoListManager.deleteToDo(item)
        }
        toDoListManager.fetchToDos(for: selectedDate)
    }

}

//#Preview {
//    ToDoList()
//}
