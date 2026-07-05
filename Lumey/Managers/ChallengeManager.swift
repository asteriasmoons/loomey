//
//  ChallengeManager.swift
//  Lumey
//

import Foundation
import SwiftData
import Combine

// MARK: - Challenge Manager

@MainActor
final class ChallengeManager: ObservableObject {

    private let modelContext: ModelContext
    private let validationEngine: ChallengeValidationEngine
    private let aiService: ChallengeAIValidationService

    @Published var isValidating: Bool = false
    @Published var lastValidationResult: ChallengeValidationResult?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.validationEngine = ChallengeValidationEngine(modelContext: modelContext)
        self.aiService = ChallengeAIValidationService()
    }

    // MARK: - Seed Challenges

    func seedChallengesIfNeeded() {
        let descriptor = FetchDescriptor<ReadingChallenge>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        let challenges = ChallengeSeedData.allChallenges()
        for challenge in challenges {
            modelContext.insert(challenge)
        }
        try? modelContext.save()
    }

    // MARK: - Join Challenge

    func joinChallenge(_ challenge: ReadingChallenge, userID: String) -> ChallengeEntry {
        let entry = ChallengeEntry(
            challengeID: challenge.id,
            userID: userID,
            startDate: Date(),
            durationDays: challenge.durationDays
        )
        modelContext.insert(entry)
        challenge.participantCount += 1
        try? modelContext.save()
        return entry
    }

    // MARK: - Submit Challenge

    func submitChallenge(
        challenge: ReadingChallenge,
        entry: ChallengeEntry,
        submission: ChallengeSubmission
    ) async {
        isValidating = true
        defer { isValidating = false }

        submission.validationStatus = .validating
        entry.status = .submitted
        entry.submittedDate = Date()
        try? modelContext.save()

        // Step 1: Run database validation
        let result = validationEngine.validate(
            challenge: challenge,
            entry: entry,
            submission: submission
        )

        switch result {
        case .approved(let message):
            approveSubmission(submission, entry: entry, challenge: challenge, message: message)

        case .needsMoreInfo(let message):
            submission.validationStatus = .needsMoreInfo
            submission.validationMessage = message
            entry.status = .needsMoreInfo

        case .rejected(let message):
            submission.validationStatus = .rejected
            submission.validationMessage = message
            entry.status = .rejected

        case .requiresAI(let preMessage):
            // Step 2: Call AI validation
            submission.validationMessage = preMessage
            await runAIValidation(challenge: challenge, entry: entry, submission: submission)
        }

        lastValidationResult = result
        try? modelContext.save()
    }

    // MARK: - AI Validation

    private func runAIValidation(
        challenge: ReadingChallenge,
        entry: ChallengeEntry,
        submission: ChallengeSubmission
    ) async {
        // Fetch linked books for the packet
        let descriptor = FetchDescriptor<Book>()
        let allBooks = (try? modelContext.fetch(descriptor)) ?? []
        let linkedBooks = allBooks.filter { submission.linkedBookIDs.contains($0.id) }

        // Fetch review text if relevant
        var reviewText: String? = nil
        if !submission.linkedReviewIDs.isEmpty {
            let reviewDescriptor = FetchDescriptor<BookReview>()
            let allReviews = (try? modelContext.fetch(reviewDescriptor)) ?? []
            let linkedReviews = allReviews.filter { submission.linkedReviewIDs.contains($0.id) }
            reviewText = linkedReviews.map(\.content).joined(separator: "\n\n")
        }

        let packet = ChallengeAIValidationService.buildPacket(
            challenge: challenge,
            books: linkedBooks,
            submissionNote: submission.submissionNote,
            reviewText: reviewText
        )

        do {
            let aiResult = try await aiService.validate(packet: packet)

            switch aiResult {
            case .approved(let message):
                approveSubmission(submission, entry: entry, challenge: challenge, message: message)
            case .needsMoreInfo(let message):
                submission.validationStatus = .needsMoreInfo
                submission.validationMessage = message
                entry.status = .needsMoreInfo
            case .rejected(let message):
                submission.validationStatus = .rejected
                submission.validationMessage = message
                entry.status = .rejected
            case .requiresAI:
                // Shouldn't happen from AI, but handle gracefully
                submission.validationStatus = .needsMoreInfo
                submission.validationMessage = "Validation is taking longer than expected. Please try again."
                entry.status = .needsMoreInfo
            }

            lastValidationResult = aiResult
        } catch {
            submission.validationStatus = .needsMoreInfo
            submission.validationMessage = "Could not reach the validation server. Please try again later."
            entry.status = .needsMoreInfo
            lastValidationResult = .needsMoreInfo("Validation service unavailable.")
        }

        try? modelContext.save()
    }

    // MARK: - Approve Submission

    private func approveSubmission(
        _ submission: ChallengeSubmission,
        entry: ChallengeEntry,
        challenge: ReadingChallenge,
        message: String
    ) {
        guard !entry.pointsAwarded else { return } // Prevent duplicate rewards

        submission.validationStatus = .approved
        submission.validationMessage = message
        submission.approvedDate = Date()

        entry.status = .approved
        entry.approvedDate = Date()
        entry.earnedPoints = challenge.points
        entry.pointsAwarded = true

        challenge.completedCount += 1

        // Award points to user profile if it exists
        awardPoints(points: challenge.points, userID: entry.userID)

        try? modelContext.save()
    }

    // MARK: - Award Points

    private func awardPoints(points: Int, userID: String) {
        let descriptor = FetchDescriptor<ChallengeUserProfile>()
        guard let profiles = try? modelContext.fetch(descriptor),
              let profile = profiles.first(where: { $0.userID == userID })
        else { return }

        profile.challengePoints += points
        profile.challengesCompleted += 1
    }

    // MARK: - Fetch Helpers

    func fetchEntry(for challengeID: UUID, userID: String) -> ChallengeEntry? {
        let descriptor = FetchDescriptor<ChallengeEntry>()
        let entries = (try? modelContext.fetch(descriptor)) ?? []
        return entries.first(where: { $0.challengeID == challengeID && $0.userID == userID })
    }

    func fetchSubmissions(for challengeID: UUID) -> [ChallengeSubmission] {
        let descriptor = FetchDescriptor<ChallengeSubmission>(
            sortBy: [SortDescriptor(\ChallengeSubmission.submittedDate, order: .reverse)]
        )
        let submissions = (try? modelContext.fetch(descriptor)) ?? []
        return submissions.filter { $0.challengeID == challengeID }
    }

    func fetchUserSubmission(for entryID: UUID) -> ChallengeSubmission? {
        let descriptor = FetchDescriptor<ChallengeSubmission>()
        let submissions = (try? modelContext.fetch(descriptor)) ?? []
        return submissions.first(where: { $0.entryID == entryID })
    }

    func fetchAllChallenges() -> [ReadingChallenge] {
        let descriptor = FetchDescriptor<ReadingChallenge>(
            sortBy: [SortDescriptor(\ReadingChallenge.createdDate)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchFeaturedChallenge() -> ReadingChallenge? {
        let all = fetchAllChallenges()
        return all.first(where: { $0.isFeatured })
    }

    func fetchWeeklyChallenges() -> [ReadingChallenge] {
        let all = fetchAllChallenges()
        return all.filter { $0.isWeekly }
    }

    func fetchChallenges(for category: ChallengeCategory) -> [ReadingChallenge] {
        let all = fetchAllChallenges()
        return all.filter { $0.category == category }
    }
}
