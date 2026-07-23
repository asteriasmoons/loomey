//
//  LumeyRecommendationCollectionContextBuilder.swift
//  Lumey
//

import Foundation

@MainActor
enum LumeyRecommendationCollectionContextBuilder {

    static func makeReaderContext(
        books: [Book],
        sessions: [ReadingSession],
        goals: [ReadingGoals],
        readingStats: ReadingStats?,
        challengeEntries: [ChallengeEntry],
        challengeSubmissions: [ChallengeSubmission],
        excludeBookKeys: [String]
    ) -> LumeyRecommendationCollectionReaderContext {
        let activeBooks = books.filter { !$0.isArchived }
        let finishedBooks = activeBooks.filter { $0.status == .finished || $0.dateFinished != nil }
        let currentlyReadingBooks = activeBooks.filter { $0.status == .reading }
        let lovedBooks = activeBooks.filter { $0.isFavorite || $0.rating >= 4 }
        let recentBooks = activeBooks
            .sorted { $0.lastUpdated > $1.lastUpdated }
            .prefix(20)
            .map { recommendationKey(title: $0.title, author: $0.author) }
        let recentSessions = sessions.prefix(40).map { session in
            LumeyRecommendationCollectionReadingSession(
                bookKey: readingSessionBookKey(session, books: books),
                lastReadAt: isoFormatter.string(from: session.date),
                pagesRead: session.pagesRead > 0 ? session.pagesRead : nil,
                minutesRead: session.durationMinutes > 0 ? session.durationMinutes : nil
            )
        }

        return LumeyRecommendationCollectionReaderContext(
            libraryBookKeys: activeBooks.map { recommendationKey(title: $0.title, author: $0.author) },
            finishedBookKeys: finishedBooks.map { recommendationKey(title: $0.title, author: $0.author) },
            currentlyReadingBookKeys: currentlyReadingBooks.map { recommendationKey(title: $0.title, author: $0.author) },
            ratings: activeBooks
                .filter { $0.rating > 0 }
                .sorted { $0.rating > $1.rating }
                .prefix(80)
                .map { LumeyRecommendationCollectionRating(title: $0.title, author: $0.author, rating: $0.rating) },
            highestRatedBooks: lovedBooks
                .sorted {
                    if $0.rating == $1.rating {
                        return $0.lastUpdated > $1.lastUpdated
                    }

                    return $0.rating > $1.rating
                }
                .prefix(12)
                .map(bookSignal),
            readingSessions: Array(recentSessions),
            pagePreferences: pagePreferences(from: finishedBooks),
            favoriteGenres: topValues(lovedBooks.flatMap(\.genres), limit: 8),
            favoriteSubgenres: topValues(activeGoals(goals).flatMap(\.linkedSubgenres), limit: 6),
            favoriteTropes: topValues(lovedBooks.flatMap(\.tropes), limit: 8),
            favoriteMoods: topValues(lovedBooks.flatMap(\.moods), limit: 8),
            favoriteThemes: topValues(lovedBooks.flatMap(\.topics), limit: 8),
            favoriteAuthors: topValues(lovedBooks.map(\.author), limit: 8),
            favoriteTags: topValues(lovedBooks.flatMap(\.tags), limit: 10),
            recentBookKeys: Array(recentBooks),
            alreadyRecommendedBookKeys: excludeBookKeys,
            readingGoals: activeGoals(goals)
                .prefix(12)
                .map(goalSignal),
            readingStats: statsSignal(readingStats, sessions: sessions),
            challengeParticipation: challengeSignal(
                entries: challengeEntries,
                submissions: challengeSubmissions
            )
        )
    }

    static func recommendationKey(title: String, author: String) -> String {
        let rawKey = "\(title)|\(author)"
        let lowercasedKey = rawKey.lowercased()
        return lowercasedKey.replacingOccurrences(
            of: "[^a-z0-9|]",
            with: "",
            options: .regularExpression
        )
    }

    static func topValues(_ values: [String], limit: Int) -> [String] {
        let grouped = Dictionary(grouping: values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }) {
            $0.lowercased()
        }

        return grouped
            .map { _, values in
                (value: values[0], count: values.count)
            }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.value.localizedCaseInsensitiveCompare(rhs.value) == .orderedAscending
                }

                return lhs.count > rhs.count
            }
            .map(\.value)
            .prefix(limit)
            .map { $0 }
    }

    private static var isoFormatter: ISO8601DateFormatter {
        ISO8601DateFormatter()
    }

    private static func bookSignal(_ book: Book) -> LumeyRecommendationCollectionBookSignal {
        LumeyRecommendationCollectionBookSignal(
            title: book.title,
            author: book.author.isEmpty ? nil : book.author,
            rating: book.rating > 0 ? book.rating : nil,
            genres: book.genres,
            moods: book.moods,
            tropes: book.tropes,
            tags: book.tags,
            seriesName: book.seriesName.isEmpty ? nil : book.seriesName
        )
    }

    private static func pagePreferences(from books: [Book]) -> LumeyRecommendationCollectionPagePreferences? {
        let pageCounts = books
            .map(\.totalPages)
            .filter { $0 > 0 }
            .sorted()

        guard pageCounts.count >= 3 else { return nil }

        let lowerIndex = max(0, Int(Double(pageCounts.count - 1) * 0.20))
        let upperIndex = min(pageCounts.count - 1, Int(Double(pageCounts.count - 1) * 0.80))

        return LumeyRecommendationCollectionPagePreferences(
            preferredMinPages: pageCounts[lowerIndex],
            preferredMaxPages: pageCounts[upperIndex]
        )
    }

    private static func readingSessionBookKey(_ session: ReadingSession, books: [Book]) -> String {
        if let linkedBookID = session.linkedBookID,
           let book = books.first(where: { $0.id == linkedBookID }) {
            return recommendationKey(title: book.title, author: book.author)
        }

        return recommendationKey(title: session.linkedBookTitle, author: "")
    }

    private static func activeGoals(_ goals: [ReadingGoals]) -> [ReadingGoals] {
        goals
            .filter { $0.status == .active && !$0.isArchived }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private static func goalSignal(_ goal: ReadingGoals) -> LumeyRecommendationCollectionGoalSignal {
        LumeyRecommendationCollectionGoalSignal(
            title: goal.displayTitle,
            type: goal.type.rawValue,
            cadence: goal.cadence.rawValue,
            progressPercent: goal.progressValue,
            targetGenre: goal.targetGenre.isEmpty ? nil : goal.targetGenre,
            targetSubgenre: goal.targetSubgenre.isEmpty ? nil : goal.targetSubgenre,
            targetAuthorName: goal.targetAuthorName.isEmpty ? nil : goal.targetAuthorName,
            linkedGenres: goal.linkedGenres,
            linkedTags: goal.linkedTags
        )
    }

    private static func statsSignal(
        _ stats: ReadingStats?,
        sessions: [ReadingSession]
    ) -> LumeyRecommendationCollectionStatsSignal? {
        guard let stats else { return nil }

        let sessionsWithPages = sessions.filter { $0.pagesRead > 0 }
        let sessionsWithMinutes = sessions.filter { $0.durationMinutes > 0 }
        let averagePages = sessionsWithPages.isEmpty
            ? nil
            : Double(sessionsWithPages.reduce(0) { $0 + $1.pagesRead }) / Double(sessionsWithPages.count)
        let averageMinutes = sessionsWithMinutes.isEmpty
            ? nil
            : Double(sessionsWithMinutes.reduce(0) { $0 + $1.durationMinutes }) / Double(sessionsWithMinutes.count)

        return LumeyRecommendationCollectionStatsSignal(
            currentReadingStreak: stats.currentReadingStreak,
            bestReadingStreak: stats.bestReadingStreak,
            totalBooksFinished: stats.totalBooksFinished,
            totalPagesRead: stats.totalPagesRead,
            totalMinutesRead: stats.totalMinutesRead,
            booksFinishedThisYear: stats.booksFinishedThisYear,
            pagesReadThisYear: stats.pagesReadThisYear,
            averagePagesPerSession: averagePages,
            averageMinutesPerSession: averageMinutes,
            favoriteGenre: stats.favoriteGenre.isEmpty ? nil : stats.favoriteGenre,
            favoriteAuthor: stats.favoriteAuthor.isEmpty ? nil : stats.favoriteAuthor
        )
    }

    private static func challengeSignal(
        entries: [ChallengeEntry],
        submissions: [ChallengeSubmission]
    ) -> LumeyRecommendationCollectionChallengeSignal? {
        guard !entries.isEmpty || !submissions.isEmpty else { return nil }

        let recentTitles = topValues(
            submissions
                .sorted { $0.submittedDate > $1.submittedDate }
                .prefix(10)
                .map(\.challengeTitle),
            limit: 6
        )
        let challengeThemes = topValues(
            recentTitles.flatMap { title in
                title
                    .split { !$0.isLetter && !$0.isNumber }
                    .map(String.init)
                    .filter { $0.count > 3 }
            },
            limit: 6
        )

        return LumeyRecommendationCollectionChallengeSignal(
            activeCount: entries.filter(\.isActive).count,
            completedCount: entries.filter { $0.status == .approved }.count,
            recentChallengeTitles: recentTitles,
            preferredChallengeThemes: challengeThemes
        )
    }
}
