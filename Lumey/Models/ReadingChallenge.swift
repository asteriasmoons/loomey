//
//  ReadingChallenge.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ReadingChallenge {
    var id: UUID = UUID()
    var title: String = ""
    var challengeDescription: String = ""
    var iconName: String = "openbook"
    var categoryRawValue: String = ChallengeCategory.readingHabit.rawValue
    var points: Int = 0
    var durationDays: Int = 7
    var requirementText: String = ""
    var validationTypeRawValue: String = ChallengeValidationType.readingSession.rawValue

    // Validation requirements
    var requiredBookCount: Int?
    var requiredPageCount: Int?
    var requiredSessionCount: Int?
    var requiredReviewCount: Int?
    var requiredRating: Int?
    var requiredGenre: String?
    var requiredTagsStorage: String = "[]"
    var requiredThemesStorage: String = "[]"
    var requiresAIValidation: Bool = false

    // Additional validation params
    var requiredSessionMinutes: Int?
    var requiredWordCount: Int?
    var requiredUniqueAuthorCount: Int?
    var requiredSameAuthorCount: Int?
    var requiredMinPages: Int?
    var requiredMaxPages: Int?
    var requiredDaysStreak: Int?

    // Featured / Weekly
    var isFeatured: Bool = false
    var isWeekly: Bool = false
    var featuredStartDate: Date?
    var featuredEndDate: Date?

    // Participation counts (local cache)
    var participantCount: Int = 0
    var completedCount: Int = 0

    // Metadata
    var createdDate: Date = Date()

    init(
        title: String = "",
        challengeDescription: String = "",
        iconName: String = "openbook",
        category: ChallengeCategory = .readingHabit,
        points: Int = 0,
        durationDays: Int = 7,
        requirementText: String = "",
        validationType: ChallengeValidationType = .readingSession,
        requiredBookCount: Int? = nil,
        requiredPageCount: Int? = nil,
        requiredSessionCount: Int? = nil,
        requiredReviewCount: Int? = nil,
        requiredRating: Int? = nil,
        requiredGenre: String? = nil,
        requiredTags: [String] = [],
        requiredThemes: [String] = [],
        requiresAIValidation: Bool = false,
        requiredSessionMinutes: Int? = nil,
        requiredWordCount: Int? = nil,
        requiredUniqueAuthorCount: Int? = nil,
        requiredSameAuthorCount: Int? = nil,
        requiredMinPages: Int? = nil,
        requiredMaxPages: Int? = nil,
        requiredDaysStreak: Int? = nil,
        isFeatured: Bool = false,
        isWeekly: Bool = false,
        featuredStartDate: Date? = nil,
        featuredEndDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.challengeDescription = challengeDescription
        self.iconName = iconName
        self.categoryRawValue = category.rawValue
        self.points = points
        self.durationDays = durationDays
        self.requirementText = requirementText
        self.validationTypeRawValue = validationType.rawValue
        self.requiredBookCount = requiredBookCount
        self.requiredPageCount = requiredPageCount
        self.requiredSessionCount = requiredSessionCount
        self.requiredReviewCount = requiredReviewCount
        self.requiredRating = requiredRating
        self.requiredGenre = requiredGenre
        self.requiredTags = requiredTags
        self.requiredThemes = requiredThemes
        self.requiresAIValidation = requiresAIValidation
        self.requiredSessionMinutes = requiredSessionMinutes
        self.requiredWordCount = requiredWordCount
        self.requiredUniqueAuthorCount = requiredUniqueAuthorCount
        self.requiredSameAuthorCount = requiredSameAuthorCount
        self.requiredMinPages = requiredMinPages
        self.requiredMaxPages = requiredMaxPages
        self.requiredDaysStreak = requiredDaysStreak
        self.isFeatured = isFeatured
        self.isWeekly = isWeekly
        self.featuredStartDate = featuredStartDate
        self.featuredEndDate = featuredEndDate
        self.createdDate = Date()
    }
}

// MARK: - Computed Properties

extension ReadingChallenge {
    var category: ChallengeCategory {
        get { ChallengeCategory(rawValue: categoryRawValue) ?? .readingHabit }
        set { categoryRawValue = newValue.rawValue }
    }

    var validationType: ChallengeValidationType {
        get { ChallengeValidationType(rawValue: validationTypeRawValue) ?? .readingSession }
        set { validationTypeRawValue = newValue.rawValue }
    }

    var requiredTags: [String] {
        get { Self.decodeStringArray(from: requiredTagsStorage) }
        set { requiredTagsStorage = Self.encodeStringArray(newValue) }
    }

    var requiredThemes: [String] {
        get { Self.decodeStringArray(from: requiredThemesStorage) }
        set { requiredThemesStorage = Self.encodeStringArray(newValue) }
    }

    var displayDuration: String {
        if durationDays == 1 { return "1 Day" }
        if durationDays < 30 { return "\(durationDays) Days" }
        if durationDays == 30 { return "1 Month" }
        if durationDays == 60 { return "2 Months" }
        if durationDays == 90 { return "3 Months" }
        if durationDays == 120 { return "4 Months" }
        if durationDays == 180 { return "6 Months" }
        if durationDays == 365 { return "1 Year" }
        return "\(durationDays) Days"
    }

    var displayPoints: String {
        "\(points) pts"
    }

    // MARK: - JSON Helpers

    private static func decodeStringArray(from storage: String) -> [String] {
        guard let data = storage.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private static func encodeStringArray(_ values: [String]) -> String {
        guard let data = try? JSONEncoder().encode(values),
              let string = String(data: data, encoding: .utf8)
        else { return "[]" }
        return string
    }
}
