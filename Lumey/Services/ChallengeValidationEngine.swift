//
//  ChallengeValidationEngine.swift
//  Lumey
//

import Foundation
import SwiftData

// MARK: - Challenge Validation Engine

@MainActor
final class ChallengeValidationEngine {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Main entry point: validate a submission against its challenge rules.
    /// Always checks hard database rules first. Only falls through to AI when required.
    func validate(
        challenge: ReadingChallenge,
        entry: ChallengeEntry,
        submission: ChallengeSubmission
    ) -> ChallengeValidationResult {

        // Fetch linked data
        let linkedBooks = fetchBooks(ids: submission.linkedBookIDs)
        let linkedSessions = fetchSessions(ids: submission.linkedSessionIDs)
        let linkedReviews = fetchReviews(ids: submission.linkedReviewIDs)
        let linkedReadingLists = fetchReadingLists(ids: submission.linkedReadingListIDs)

        // Run validation by type
        switch challenge.validationType {
        case .readingSession:
            return validateReadingSession(challenge: challenge, entry: entry, sessions: linkedSessions)
        case .pageCount:
            return validatePageCount(challenge: challenge, entry: entry, sessions: linkedSessions, books: linkedBooks)
        case .bookCompletion:
            return validateBookCompletion(challenge: challenge, entry: entry, books: linkedBooks)
        case .genre:
            return validateGenre(challenge: challenge, entry: entry, books: linkedBooks)
        case .review:
            return validateReview(challenge: challenge, entry: entry, reviews: linkedReviews, submission: submission)
        case .rating:
            return validateRating(challenge: challenge, books: linkedBooks)
        case .series:
            return validateSeries(challenge: challenge, books: linkedBooks)
        case .author:
            return validateAuthor(challenge: challenge, books: linkedBooks)
        case .seasonalTheme:
            return validateSeasonalTheme(challenge: challenge, entry: entry, books: linkedBooks, submission: submission)
        case .bookLength:
            return validateBookLength(challenge: challenge, books: linkedBooks)
        case .collection:
            return validateCollection(challenge: challenge, books: linkedBooks, readingLists: linkedReadingLists)
        case .experience:
            return validateExperience(challenge: challenge, entry: entry, sessions: linkedSessions, submission: submission)
        }
    }

    // MARK: - Validation: Reading Session

    private func validateReadingSession(
        challenge: ReadingChallenge,
        entry: ChallengeEntry,
        sessions: [ReadingSession]
    ) -> ChallengeValidationResult {

        // Filter sessions within challenge window
        let windowSessions = sessions.filter { $0.date >= entry.startDate && $0.date <= entry.endDate }

        if let requiredCount = challenge.requiredSessionCount, windowSessions.count < requiredCount {
            return .needsMoreInfo("You've logged \(windowSessions.count) of \(requiredCount) required reading sessions during this challenge window.")
        }

        if let requiredMinutes = challenge.requiredSessionMinutes {
            let qualifying = windowSessions.filter { $0.durationMinutes >= requiredMinutes }
            if qualifying.isEmpty {
                return .needsMoreInfo("No sessions found lasting at least \(requiredMinutes) minutes. Your longest session was \(windowSessions.map(\.durationMinutes).max() ?? 0) minutes.")
            }
        }

        if let requiredStreak = challenge.requiredDaysStreak {
            let uniqueDays = Set(windowSessions.map { Calendar.current.startOfDay(for: $0.date) }).sorted()
            let streakLength = longestConsecutiveStreak(dates: uniqueDays)
            if streakLength < requiredStreak {
                return .needsMoreInfo("You've read on \(uniqueDays.count) unique days, but need a streak of \(requiredStreak) consecutive days. Your best streak was \(streakLength) days.")
            }
        }

        return .approved("Great work! Your reading sessions meet all the requirements.")
    }

    // MARK: - Validation: Page Count

    private func validatePageCount(
        challenge: ReadingChallenge,
        entry: ChallengeEntry,
        sessions: [ReadingSession],
        books: [Book]
    ) -> ChallengeValidationResult {

        let windowSessions = sessions.filter { $0.date >= entry.startDate && $0.date <= entry.endDate }
        let totalPages = windowSessions.reduce(0) { $0 + $1.pagesRead }

        guard let requiredPages = challenge.requiredPageCount else {
            return .approved("Page count validated.")
        }

        if totalPages < requiredPages {
            return .needsMoreInfo("You've read \(totalPages) of \(requiredPages) required pages during the challenge window.")
        }

        return .approved("Amazing! You've read \(totalPages) pages — well above the \(requiredPages) page goal.")
    }

    // MARK: - Validation: Book Completion

    private func validateBookCompletion(
        challenge: ReadingChallenge,
        entry: ChallengeEntry,
        books: [Book]
    ) -> ChallengeValidationResult {

        let finishedBooks = books.filter { book in
            book.status == .finished &&
            book.dateFinished != nil &&
            book.dateFinished! >= entry.startDate &&
            book.dateFinished! <= entry.endDate
        }

        guard let requiredCount = challenge.requiredBookCount else {
            if finishedBooks.isEmpty {
                return .needsMoreInfo("No finished books found during the challenge window.")
            }
            return .approved("Book completion validated.")
        }

        if finishedBooks.count < requiredCount {
            return .needsMoreInfo("You've finished \(finishedBooks.count) of \(requiredCount) required books during the challenge window.")
        }

        return .approved("Incredible! You finished \(finishedBooks.count) books during this challenge.")
    }

    // MARK: - Validation: Genre

    private func validateGenre(
        challenge: ReadingChallenge,
        entry: ChallengeEntry,
        books: [Book]
    ) -> ChallengeValidationResult {

        let finishedBooks = books.filter { book in
            book.status == .finished &&
            book.dateFinished != nil &&
            book.dateFinished! >= entry.startDate &&
            book.dateFinished! <= entry.endDate
        }

        guard let requiredCount = challenge.requiredBookCount, !finishedBooks.isEmpty else {
            return .needsMoreInfo("No finished books linked to this submission.")
        }

        if finishedBooks.count < requiredCount {
            return .needsMoreInfo("You've finished \(finishedBooks.count) of \(requiredCount) required books.")
        }

        // Check specific genre if required
        if let requiredGenre = challenge.requiredGenre {
            let genreMatching = finishedBooks.filter { book in
                book.genres.contains { genre in
                    genre.localizedCaseInsensitiveContains(requiredGenre)
                }
            }
            if genreMatching.count < requiredCount {
                if challenge.requiresAIValidation {
                    return .requiresAI("Genre match needs AI review. Found \(genreMatching.count) of \(requiredCount) books matching '\(requiredGenre)'.")
                }
                return .needsMoreInfo("Only \(genreMatching.count) of your \(finishedBooks.count) finished books match the required genre '\(requiredGenre)'.")
            }
        }

        if challenge.requiresAIValidation {
            return .requiresAI("Books meet basic requirements. AI will verify genre/theme match.")
        }

        return .approved("Your genre challenge is complete!")
    }

    // MARK: - Validation: Review

    private func validateReview(
        challenge: ReadingChallenge,
        entry: ChallengeEntry,
        reviews: [BookReview],
        submission: ChallengeSubmission
    ) -> ChallengeValidationResult {

        let windowReviews = reviews.filter { $0.dateCreated >= entry.startDate && $0.dateCreated <= entry.endDate }

        guard let requiredCount = challenge.requiredReviewCount else {
            if windowReviews.isEmpty {
                return .needsMoreInfo("No reviews found during the challenge window.")
            }
            return .approved("Review validated.")
        }

        if windowReviews.count < requiredCount {
            return .needsMoreInfo("You've written \(windowReviews.count) of \(requiredCount) required reviews during the challenge window.")
        }

        // Check word count if required
        if let requiredWords = challenge.requiredWordCount {
            let qualifying = windowReviews.filter { review in
                let wordCount = review.content.split(separator: " ").count
                return wordCount >= requiredWords
            }
            if qualifying.isEmpty {
                return .needsMoreInfo("None of your reviews meet the \(requiredWords)-word minimum. Try adding more detail to your review.")
            }
        }

        // If AI validation needed (e.g. Honest Critic)
        if challenge.requiresAIValidation {
            return .requiresAI("Reviews meet the count requirement. AI will evaluate quality/themes.")
        }

        return .approved("Your reviews look great!")
    }

    // MARK: - Validation: Rating

    private func validateRating(
        challenge: ReadingChallenge,
        books: [Book]
    ) -> ChallengeValidationResult {

        let ratedBooks = books.filter { $0.rating > 0 }

        guard let requiredCount = challenge.requiredBookCount else {
            if ratedBooks.isEmpty {
                return .needsMoreInfo("No rated books found.")
            }
            return .approved("Rating validated.")
        }

        if let requiredRating = challenge.requiredRating {
            let qualifying = ratedBooks.filter { Int($0.rating) >= requiredRating }
            if qualifying.count < requiredCount {
                return .needsMoreInfo("You have \(qualifying.count) of \(requiredCount) books rated \(requiredRating) stars or higher.")
            }
            return .approved("You found \(qualifying.count) books worthy of \(requiredRating) stars!")
        }

        if ratedBooks.count < requiredCount {
            return .needsMoreInfo("You've rated \(ratedBooks.count) of \(requiredCount) required books.")
        }

        return .approved("Ratings complete!")
    }

    // MARK: - Validation: Series

    private func validateSeries(
        challenge: ReadingChallenge,
        books: [Book]
    ) -> ChallengeValidationResult {

        let finishedBooks = books.filter { $0.status == .finished }

        guard let requiredCount = challenge.requiredBookCount else {
            return .needsMoreInfo("No book count requirement specified.")
        }

        if finishedBooks.count < requiredCount {
            return .needsMoreInfo("You've finished \(finishedBooks.count) of \(requiredCount) required books from the series.")
        }

        // Check if books share a series name
        let seriesNames = finishedBooks.compactMap { book -> String? in
            let name = book.seriesName.trimmingCharacters(in: .whitespacesAndNewlines)
            return name.isEmpty ? nil : name
        }

        if seriesNames.isEmpty {
            return .needsMoreInfo("None of the linked books have a series name set. Make sure your books have their series information filled in.")
        }

        let seriesCounts = Dictionary(grouping: seriesNames, by: { $0 }).mapValues(\.count)
        let bestSeries = seriesCounts.max(by: { $0.value < $1.value })

        if let best = bestSeries, best.value >= requiredCount {
            return .approved("You've completed \(best.value) books from the \(best.key) series!")
        }

        return .needsMoreInfo("Your linked books span multiple series. You need \(requiredCount) finished books from the same series.")
    }

    // MARK: - Validation: Author

    private func validateAuthor(
        challenge: ReadingChallenge,
        books: [Book]
    ) -> ChallengeValidationResult {

        let finishedBooks = books.filter { $0.status == .finished }

        guard let requiredCount = challenge.requiredBookCount, !finishedBooks.isEmpty else {
            return .needsMoreInfo("No finished books linked to this submission.")
        }

        if finishedBooks.count < requiredCount {
            return .needsMoreInfo("You've finished \(finishedBooks.count) of \(requiredCount) required books.")
        }

        // Same author check
        if let requiredSame = challenge.requiredSameAuthorCount {
            let authorCounts = Dictionary(grouping: finishedBooks, by: { $0.author.lowercased() }).mapValues(\.count)
            let bestAuthor = authorCounts.max(by: { $0.value < $1.value })
            if let best = bestAuthor, best.value >= requiredSame {
                return .approved("You've read \(best.value) books by \(finishedBooks.first(where: { $0.author.lowercased() == best.key })?.author ?? best.key)!")
            }
            return .needsMoreInfo("You need \(requiredSame) books by the same author.")
        }

        // Unique author check
        if let requiredUnique = challenge.requiredUniqueAuthorCount {
            let uniqueAuthors = Set(finishedBooks.map { $0.author.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
            if uniqueAuthors.count < requiredUnique {
                return .needsMoreInfo("You've read books by \(uniqueAuthors.count) unique authors, but need \(requiredUnique).")
            }
            return .approved("You've explored \(uniqueAuthors.count) different authors!")
        }

        return .approved("Author challenge validated!")
    }

    // MARK: - Validation: Seasonal Theme

    private func validateSeasonalTheme(
        challenge: ReadingChallenge,
        entry: ChallengeEntry,
        books: [Book],
        submission: ChallengeSubmission
    ) -> ChallengeValidationResult {

        let finishedBooks = books.filter { book in
            book.status == .finished &&
            book.dateFinished != nil &&
            book.dateFinished! >= entry.startDate &&
            book.dateFinished! <= entry.endDate
        }

        guard let requiredCount = challenge.requiredBookCount else {
            return .needsMoreInfo("No book count requirement specified.")
        }

        if finishedBooks.count < requiredCount {
            return .needsMoreInfo("You've finished \(finishedBooks.count) of \(requiredCount) required books during the challenge window.")
        }

        // Always defer to AI for theme validation
        return .requiresAI("You've finished enough books. AI will verify they match the seasonal theme.")
    }

    // MARK: - Validation: Book Length

    private func validateBookLength(
        challenge: ReadingChallenge,
        books: [Book]
    ) -> ChallengeValidationResult {

        let finishedBooks = books.filter { $0.status == .finished }

        guard let requiredCount = challenge.requiredBookCount, !finishedBooks.isEmpty else {
            return .needsMoreInfo("No finished books linked to this submission.")
        }

        var qualifying = finishedBooks

        // Filter by min pages
        if let minPages = challenge.requiredMinPages {
            qualifying = qualifying.filter { $0.totalPages >= minPages }
        }

        // Filter by max pages
        if let maxPages = challenge.requiredMaxPages {
            qualifying = qualifying.filter { $0.totalPages <= maxPages || $0.totalPages == 0 }
            // Exclude books with 0 pages from max-only filters
            if challenge.requiredMinPages == nil {
                qualifying = qualifying.filter { $0.totalPages > 0 && $0.totalPages <= maxPages }
            }
        }

        if qualifying.count < requiredCount {
            let pageRange: String
            if let min = challenge.requiredMinPages, let max = challenge.requiredMaxPages {
                pageRange = "\(min)–\(max) pages"
            } else if let min = challenge.requiredMinPages {
                pageRange = "\(min)+ pages"
            } else if let max = challenge.requiredMaxPages {
                pageRange = "under \(max) pages"
            } else {
                pageRange = "the required length"
            }
            return .needsMoreInfo("Only \(qualifying.count) of your finished books are \(pageRange).")
        }

        let bookTitle = qualifying.first?.title ?? "your book"
        let pages = qualifying.first?.totalPages ?? 0
        return .approved("\(bookTitle) at \(pages) pages meets the requirement!")
    }

    // MARK: - Validation: Collection

    private func validateCollection(
        challenge: ReadingChallenge,
        books: [Book],
        readingLists: [ReadingList]
    ) -> ChallengeValidationResult {

        guard let requiredCount = challenge.requiredBookCount else {
            return .needsMoreInfo("No count requirement specified.")
        }

        // For reading list challenges
        if challenge.title.contains("Curated") || challenge.title.contains("Reading Lists") {
            if readingLists.count < requiredCount {
                return .needsMoreInfo("You have \(readingLists.count) of \(requiredCount) required reading lists.")
            }
            return .approved("You've curated \(readingLists.count) reading lists!")
        }

        // For book count collection challenges
        if books.count < requiredCount {
            return .needsMoreInfo("You've added \(books.count) of \(requiredCount) required books.")
        }

        return .approved("Your collection of \(books.count) books meets the requirement!")
    }

    // MARK: - Validation: Experience

    private func validateExperience(
        challenge: ReadingChallenge,
        entry: ChallengeEntry,
        sessions: [ReadingSession],
        submission: ChallengeSubmission
    ) -> ChallengeValidationResult {

        let windowSessions = sessions.filter { $0.date >= entry.startDate && $0.date <= entry.endDate }

        if let requiredCount = challenge.requiredSessionCount, windowSessions.count < requiredCount {
            return .needsMoreInfo("You've logged \(windowSessions.count) of \(requiredCount) required reading sessions.")
        }

        if challenge.requiresAIValidation {
            if submission.submissionNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .needsMoreInfo("This challenge requires a submission note describing your experience.")
            }
            return .requiresAI("Sessions verified. AI will evaluate your experience description.")
        }

        return .approved("Your reading experience is validated!")
    }

    // MARK: - Data Fetching Helpers

    private func fetchBooks(ids: [UUID]) -> [Book] {
        guard !ids.isEmpty else { return [] }
        let descriptor = FetchDescriptor<Book>()
        let allBooks = (try? modelContext.fetch(descriptor)) ?? []
        return allBooks.filter { ids.contains($0.id) }
    }

    private func fetchSessions(ids: [UUID]) -> [ReadingSession] {
        guard !ids.isEmpty else { return [] }
        let descriptor = FetchDescriptor<ReadingSession>()
        let allSessions = (try? modelContext.fetch(descriptor)) ?? []
        return allSessions.filter { ids.contains($0.id) }
    }

    private func fetchReviews(ids: [UUID]) -> [BookReview] {
        guard !ids.isEmpty else { return [] }
        let descriptor = FetchDescriptor<BookReview>()
        let allReviews = (try? modelContext.fetch(descriptor)) ?? []
        return allReviews.filter { ids.contains($0.id) }
    }

    private func fetchReadingLists(ids: [UUID]) -> [ReadingList] {
        guard !ids.isEmpty else { return [] }
        let descriptor = FetchDescriptor<ReadingList>()
        let allLists = (try? modelContext.fetch(descriptor)) ?? []
        return allLists.filter { ids.contains($0.id) }
    }

    // MARK: - Streak Helper

    private func longestConsecutiveStreak(dates: [Date]) -> Int {
        guard dates.count > 1 else { return dates.count }
        let sorted = dates.sorted()
        var maxStreak = 1
        var currentStreak = 1

        for i in 1..<sorted.count {
            let prev = Calendar.current.startOfDay(for: sorted[i - 1])
            let curr = Calendar.current.startOfDay(for: sorted[i])
            let daysDiff = Calendar.current.dateComponents([.day], from: prev, to: curr).day ?? 0

            if daysDiff == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else if daysDiff > 1 {
                currentStreak = 1
            }
        }
        return maxStreak
    }
}
