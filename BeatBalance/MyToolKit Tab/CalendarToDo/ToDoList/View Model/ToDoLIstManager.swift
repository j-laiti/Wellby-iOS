//
//  ToDoListManager.swift
//  CalendarToDo
//
//  Created by Justin Laiti on 1/28/24.
//

import Foundation
import CoreData

class ToDoListManager: ObservableObject {
    
    let persistentContainer: NSPersistentContainer
    
    init() {
        // Initialize the container
        persistentContainer = NSPersistentContainer(name: "InternalData")
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("Core Data error: \(error)")
            }
        }
    }
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    @Published var items = [ToDoItemEntity]()
    @Published var taskCompletionRatios: [Date: Double?] = [:]
    
    // retrieve to do list items for a specific day
    func fetchToDos(for date: Date) {
        let request: NSFetchRequest<ToDoItemEntity> = ToDoItemEntity.fetchRequest()

        // Create a date range for the selected date
        var calendar = Calendar.current
        calendar.timeZone = NSTimeZone.local
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!

        // Set the predicate to fetch items within the date range
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)

        do {
            let results = try viewContext.fetch(request)
            DispatchQueue.main.async {
                self.items = results
            }
        } catch {
            print("Error fetching to-do items: \(error)")
        }
    }
    
    // add to do list item
    func addToDo(title: String, for date: Date) {
        let newItem = ToDoItemEntity(context: viewContext)
        newItem.id = UUID()
        newItem.title = title
        newItem.date = date
        newItem.isCompleted = false
        saveContext()
    }

    // edit to-do list item
    func completeToDo(item: ToDoItemEntity) {
        item.isCompleted.toggle()
        saveContext()
    }
    
    // delete to-do list item
    func deleteToDo(_ item: ToDoItemEntity) {
        viewContext.delete(item)
        saveContext()
    }
    
    private func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                // Handle the error appropriately
                print("Error saving context: \(error)")
            }
        }
    }
    
    func toDoCompletionRatio(for date: Date) async -> Double? {
        let request: NSFetchRequest<ToDoItemEntity> = ToDoItemEntity.fetchRequest()
        
        var calendar = Calendar.current
        calendar.timeZone = NSTimeZone.local
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        // Predicate for tasks on the specified date
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)
        request.includesSubentities = false
        
        do {
            let totalCount = try viewContext.count(for: request)
            if totalCount == 0 {
                return nil
            }
            
            // Predicate for completed tasks on the specified date
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@ AND isCompleted == true", startDate as NSDate, endDate as NSDate)
            let completedCount = try viewContext.count(for: request)
            
            return Double(completedCount) / Double(totalCount)
        } catch {
            print("Error fetching to-do completion ratio: \(error)")
            return nil
        }
    }
    
    func updateCompletionRatios(for dates: [Date]) async {
        let calculator = RatioCalculator()
        let newRatios = await calculator.calculateCompletionRatios(for: dates, using: self)
        
        DispatchQueue.main.async {
            self.taskCompletionRatios = newRatios
        }
    }
}

actor RatioCalculator {
    func calculateCompletionRatios(for dates: [Date], using manager: ToDoListManager) async -> [Date: Double?] {
        var ratios = [Date: Double?]()
        for date in dates {
            ratios[date] = await manager.toDoCompletionRatio(for: date)
        }
        return ratios
    }
}

