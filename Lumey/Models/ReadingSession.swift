//
//  ReadingSession.swift
//  Lumey
//

import Foundation
import SwiftData

// MARK: - Reading Session

@Model
final class ReadingSession {
    var id: UUID = UUID()

    // Linked book (optional)
    var linkedBookID: UUID?
    var linkedBookTitle: String = ""
    
    // Linked goal (optional)
    var linkedGoalID: UUID?
    var linkedGoalTitle: String = ""

    // Session data
    var durationMinutes: Int = 0
    var pagesRead: Int = 0
    var notes: String = ""
    var date: Date = Date()

    // Points
    var pointsEarned: Int = 0

    // Metadata
    var createdAt: Date = Date()

    init(
        linkedBookID: UUID? = nil,
        linkedBookTitle: String = "",
        linkedGoalID: UUID? = nil,
        linkedGoalTitle: String = "",
        durationMinutes: Int = 0,
        pagesRead: Int = 0,
        notes: String = "",
        date: Date = Date()
    ) {
        self.id = UUID()
        self.linkedBookID = linkedBookID
        self.linkedBookTitle = linkedBookTitle
        self.linkedGoalID = linkedGoalID
        self.linkedGoalTitle = linkedGoalTitle
        self.durationMinutes = durationMinutes
        self.pagesRead = pagesRead
        self.notes = notes
        self.date = date
        self.pointsEarned = Self.calculatePoints(minutes: durationMinutes, pages: pagesRead)
        self.createdAt = Date()
    }

    static func calculatePoints(minutes: Int, pages: Int) -> Int {
        // 1 pt per minute, 2 pts per page, minimum 5 pts for any logged session
        let raw = minutes + (pages * 2)
        return max(raw, minutes > 0 || pages > 0 ? 5 : 0)
    }
}
