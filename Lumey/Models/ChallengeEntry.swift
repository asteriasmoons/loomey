//
//  ChallengeEntry.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ChallengeEntry {
    var id: UUID = UUID()
    var challengeID: UUID = UUID()
    var userID: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date()
    var cycleID: String = ""
    var statusRawValue: String = ChallengeSubmissionStatus.joined.rawValue
    var submittedDate: Date?
    var approvedDate: Date?
    var earnedPoints: Int = 0
    var pointsAwarded: Bool = false

    init(
        challengeID: UUID,
        userID: String,
        startDate: Date = Date(),
        durationDays: Int = 7,
        endDate: Date? = nil,
        cycleID: String = ""
    ) {
        self.id = UUID()
        self.challengeID = challengeID
        self.userID = userID
        self.startDate = startDate
        self.endDate = endDate ?? Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
        self.cycleID = cycleID
        self.statusRawValue = ChallengeSubmissionStatus.joined.rawValue
    }
}

// MARK: - Computed Properties

extension ChallengeEntry {
    var status: ChallengeSubmissionStatus {
        get { ChallengeSubmissionStatus(rawValue: statusRawValue) ?? .joined }
        set { statusRawValue = newValue.rawValue }
    }

    var isExpired: Bool {
        Date() > endDate && status != .approved
    }

    var daysRemaining: Int {
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(remaining, 0)
    }

    var displayDaysRemaining: String {
        let days = daysRemaining
        if days == 0 { return "Ends today" }
        if days == 1 { return "1 day left" }
        return "\(days) days left"
    }

    var isActive: Bool {
        status == .joined || status == .readyToSubmit || status == .submitted || status == .validating || status == .needsMoreInfo
    }
}
