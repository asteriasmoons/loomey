//
//  ChallengeEnums.swift
//  Lumey
//

import Foundation

// MARK: - Challenge Category

enum ChallengeCategory: String, Codable, CaseIterable, Identifiable {
    case readingHabit
    case pages
    case bookCompletion
    case genre
    case review
    case rating
    case series
    case author
    case seasonal
    case bookLength
    case collection
    case fun

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .readingHabit: return "Reading Habit"
        case .pages: return "Pages"
        case .bookCompletion: return "Book Completion"
        case .genre: return "Genre"
        case .review: return "Review"
        case .rating: return "Rating"
        case .series: return "Series"
        case .author: return "Author"
        case .seasonal: return "Seasonal"
        case .bookLength: return "Book Length"
        case .collection: return "Collection"
        case .fun: return "Fun"
        }
    }

    var iconName: String {
        switch self {
        case .readingHabit: return "openbook"
        case .pages: return "linedpages"
        case .bookCompletion: return "bookstack"
        case .genre: return "sparklybook"
        case .review: return "writenote"
        case .rating: return "starfill"
        case .series: return "books"
        case .author: return "pencilfill"
        case .seasonal: return "flower"
        case .bookLength: return "flatbook"
        case .collection: return "bookstand"
        case .fun: return "lovecup"
        }
    }
}

// MARK: - Challenge Validation Type

enum ChallengeValidationType: String, Codable, CaseIterable, Identifiable {
    case readingSession
    case pageCount
    case bookCompletion
    case genre
    case review
    case rating
    case series
    case author
    case seasonalTheme
    case bookLength
    case collection
    case experience

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .readingSession: return "Reading Session"
        case .pageCount: return "Page Count"
        case .bookCompletion: return "Book Completion"
        case .genre: return "Genre"
        case .review: return "Review"
        case .rating: return "Rating"
        case .series: return "Series"
        case .author: return "Author"
        case .seasonalTheme: return "Seasonal Theme"
        case .bookLength: return "Book Length"
        case .collection: return "Collection"
        case .experience: return "Experience"
        }
    }
}

// MARK: - Challenge Recurrence

enum ChallengeRecurrence: String, Codable, CaseIterable, Identifiable {
    case oneTime
    case daily
    case weekly
    case monthly
    case yearly
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneTime: return "One-Time"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .custom: return "Recurring"
        }
    }
}

// MARK: - Challenge Submission Status

enum ChallengeSubmissionStatus: String, Codable, CaseIterable, Identifiable {
    case joined
    case readyToSubmit
    case submitted
    case validating
    case inProgress
    case approved
    case needsMoreInfo
    case rejected
    case expired

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .joined: return "Joined"
        case .readyToSubmit: return "Ready to Submit"
        case .submitted: return "Submitted"
        case .validating: return "Validating"
        case .inProgress: return "In Progress"
        case .approved: return "Approved"
        case .needsMoreInfo: return "Needs More Info"
        case .rejected: return "Not Eligible"
        case .expired: return "Expired"
        }
    }

    var badgeColor: String {
        switch self {
        case .joined: return "#03dbfc"
        case .readyToSubmit: return "#f6f684"
        case .submitted: return "#a92ce8"
        case .validating: return "#a92ce8"
        case .inProgress: return "#03dbfc"
        case .approved: return "#e2ed8a"
        case .needsMoreInfo: return "#f6f684"
        case .rejected: return "#dc3beb"
        case .expired: return "#888888"
        }
    }
}

// MARK: - Challenge Validation Result

enum ChallengeValidationResult {
    case approved(String)
    case inProgress(String)
    case needsMoreInfo(String)
    case rejected(String)
    case requiresAI(String)

    var isApproved: Bool {
        if case .approved = self { return true }
        return false
    }

    var message: String {
        switch self {
        case .approved(let msg): return msg
        case .inProgress(let msg): return msg
        case .needsMoreInfo(let msg): return msg
        case .rejected(let msg): return msg
        case .requiresAI(let msg): return msg
        }
    }
}
