//
//  GoalNote.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class GoalNote {
    var id: UUID = UUID()
    
    // MARK: - Goal Reference
    
    var goalID: UUID = UUID()
    
    // MARK: - Note Content
    
    var noteText: String = ""
    
    // MARK: - Frozen Progress Snapshot
    
    var progressSnapshot: Double = 0
    var completionCountSnapshot: Int = 0
    
    // MARK: - Metadata
    
    var createdAt: Date = Date()
    
    init(
        goalID: UUID = UUID(),
        noteText: String = "",
        progressSnapshot: Double = 0,
        completionCountSnapshot: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.goalID = goalID
        self.noteText = noteText
        self.progressSnapshot = progressSnapshot
        self.completionCountSnapshot = completionCountSnapshot
        self.createdAt = createdAt
    }
}

// MARK: - Computed Properties

extension GoalNote {
    var progressPercentage: Int {
        Int((min(max(progressSnapshot, 0), 1) * 100).rounded())
    }
    
    var displayDate: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
    }
    
    var previewText: String {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 120 {
            return String(trimmed.prefix(120)) + "…"
        }
        return trimmed
    }
}
