//
//  ToDoItem.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/31/24.
//

import Foundation

struct ToDoItem: Identifiable {
    var id: String
    var title: String
    var isCompleted: Bool
    var date: Date
}
