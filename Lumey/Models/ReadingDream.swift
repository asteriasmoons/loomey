//
//  ReadingDream.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ReadingDream {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var iconName: String = "sparkles"
    var isCompleted: Bool = false
    var completedDate: Date? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isArchived: Bool = false

    init(
        id: UUID = UUID(),
        title: String = "",
        notes: String = "",
        iconName: String = "sparklybook",
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.iconName = iconName
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
}
