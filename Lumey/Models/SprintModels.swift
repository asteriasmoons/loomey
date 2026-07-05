//
//  SprintModels.swift
//  Lumey
//

import Foundation

// MARK: - Sprint

struct SprintParticipant: Codable {
    let userId: String
    let displayName: String
    let startPage: Int
    let endPage: Int?
    let pagesRead: Int?
    let pointsAwarded: Int?
    let joinedAt: String
    let submittedAt: String?
}

struct Sprint: Codable, Identifiable {
    let id: String
    let startedByUserId: String
    let startedByDisplayName: String
    let durationMinutes: Int
    let startsAt: String
    let endsAt: String
    let status: String  // "waiting" | "active" | "submitting" | "finished"
    let participants: [SprintParticipant]
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case startedByUserId, startedByDisplayName
        case durationMinutes, startsAt, endsAt
        case status, participants, createdAt
    }

    var isWaiting: Bool    { status == "waiting" }
    var isActive: Bool     { status == "active" }
    var isSubmitting: Bool { status == "submitting" }
    var isFinished: Bool   { status == "finished" }

    var startsAtDate: Date? { ISO8601DateFormatter().date(from: startsAt) }
    var endsAtDate: Date?   { ISO8601DateFormatter().date(from: endsAt) }
}

// MARK: - Sprint message

struct SprintMessage: Codable, Identifiable {
    let id: String
    let senderUserId: String
    let senderDisplayName: String
    let type: String        // "text" | "system" | "sprint_result"
    let text: String
    let sprintId: String?
    let resultPayload: SprintResultPayload?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case senderUserId, senderDisplayName
        case type, text, sprintId, resultPayload, createdAt
    }

    var isSystem: Bool       { type == "system" }
    var isSprintResult: Bool { type == "sprint_result" }
}

// MARK: - Sprint result

struct SprintResultPayload: Codable {
    let sprintId: String
    let durationMinutes: Int
    let ranked: [SprintResultEntry]
}

struct SprintResultEntry: Codable, Identifiable {
    let rank: Int
    let userId: String
    let displayName: String
    let pagesRead: Int
    let pointsAwarded: Int

    var id: String { userId }
}

// MARK: - Leaderboard

struct SprintLeaderboardEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let totalPoints: Int
    let totalPagesRead: Int
    let sprintsParticipated: Int
    let lastSprintAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, displayName, totalPoints, totalPagesRead
        case sprintsParticipated, lastSprintAt
    }
}

// MARK: - API response wrappers

struct SprintResponse: Codable {
    let success: Bool
    let sprint: Sprint?
}

struct SprintMessagesResponse: Codable {
    let success: Bool
    let messages: [SprintMessage]?
}

struct SprintMessageResponse: Codable {
    let success: Bool
    let message: SprintMessage?
}

struct SprintLeaderboardResponse: Codable {
    let success: Bool
    let leaderboard: [SprintLeaderboardEntry]?
}

struct SprintLeaderboardEntryResponse: Codable {
    let success: Bool
    let entry: SprintLeaderboardEntry?
}

struct SprintSuccessResponse: Codable {
    let success: Bool
}
// MARK: - Request bodies

struct StartSprintBody: Encodable {
    let userId: String
    let displayName: String
    let durationMinutes: Int
    let startPage: Int
}

struct JoinSprintBody: Encodable {
    let userId: String
    let displayName: String
    let startPage: Int
}

struct SubmitEndPageBody: Encodable {
    let userId: String
    let endPage: Int
}

struct SendSprintMessageBody: Encodable {
    let senderUserId: String
    let senderDisplayName: String
    let text: String
}
