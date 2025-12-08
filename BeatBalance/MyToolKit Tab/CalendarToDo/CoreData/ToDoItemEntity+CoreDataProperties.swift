//
//  ToDoItemEntity+CoreDataProperties.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/31/24.
//
//

import Foundation
import CoreData


extension ToDoItemEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ToDoItemEntity> {
        return NSFetchRequest<ToDoItemEntity>(entityName: "ToDoItemEntity")
    }

    @NSManaged public var date: Date
    @NSManaged public var id: UUID
    @NSManaged public var isCompleted: Bool
    @NSManaged public var title: String

}

extension ToDoItemEntity : Identifiable {

}
