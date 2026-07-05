//
//  ReadingAchievement.swift
//  Lumey
//

import Foundation
import SwiftData

enum AchievementType: String, Codable, CaseIterable, Identifiable {
    case pagesRead = "Pages Read"
    case booksFinished = "Books Finished"
    case reviewsWritten = "Reviews Written"
    case quotesSaved = "Quotes Saved"
    case notesWritten = "Notes Written"
    case readingStreak = "Reading Streak"
    case seriesFinished = "Series Finished"

    var id: String { rawValue }
}

@Model
final class ReadingAchievement {
    var id: UUID = UUID()
    var title: String = ""
    var achievementDescription: String = ""
    var type: AchievementType = AchievementType.booksFinished
    var targetValue: Int = 0
    var currentValue: Int = 0
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    var iconName: String = "achievement"
    var sortOrder: Int = 0

    init(
        id: UUID = UUID(),
        title: String,
        achievementDescription: String,
        type: AchievementType,
        targetValue: Int,
        currentValue: Int = 0,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil,
        iconName: String = "startrophy",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.achievementDescription = achievementDescription
        self.type = type
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.iconName = iconName
        self.sortOrder = sortOrder
    }
}
