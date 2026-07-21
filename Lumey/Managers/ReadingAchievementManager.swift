//
//  ReadingAchievementManager.swift
//  Lumey
//

import Foundation
import SwiftData

enum ReadingAchievementManager {

    // MARK: - Public

    static func seedAchievementsIfNeeded(modelContext: ModelContext) {
        let existing = fetchAchievements(modelContext: modelContext)

        for definition in ReadingAchievementDefinition.shipped {
            if let match = existing.first(where: {
                $0.title == definition.title &&
                $0.type == definition.type &&
                $0.targetValue == definition.targetValue
            }) {
                // Sync icon name if definition changed
                if match.iconName != definition.iconName {
                    match.iconName = definition.iconName
                }
                continue
            }

            let achievement = ReadingAchievement(
                title: definition.title,
                achievementDescription: definition.description,
                type: definition.type,
                targetValue: definition.targetValue,
                iconName: definition.iconName,
                sortOrder: definition.sortOrder
            )

            modelContext.insert(achievement)
        }

        try? modelContext.save()
    }

    static func updateAchievements(modelContext: ModelContext) {
        seedAchievementsIfNeeded(modelContext: modelContext)

        let achievements = fetchAchievements(modelContext: modelContext)
        let books = fetchBooks(modelContext: modelContext)
        let sessions = fetchSessions(modelContext: modelContext)
        let reviews = fetchReviews(modelContext: modelContext)
        let notes = fetchNotes(modelContext: modelContext)
        let quotes = fetchQuotes(modelContext: modelContext)

        let values = AchievementValues(
            pagesRead: calculatePagesRead(from: books),
            booksFinished: calculateFinishedBooks(from: books),
            reviewsWritten: reviews.filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count,
            quotesSaved: quotes.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count,
            notesWritten: notes.filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count,
            readingStreak: calculateLongestReadingStreak(from: sessions),
            seriesFinished: calculateFinishedSeries(books: books)
        )

        for achievement in achievements {
            let currentValue = values.value(for: achievement.type)

            achievement.currentValue = currentValue

            if !achievement.isUnlocked && currentValue >= achievement.targetValue {
                achievement.isUnlocked = true
                achievement.unlockedDate = Date()
            }
        }

        try? modelContext.save()
    }

    // MARK: - Fetching

    private static func fetchAchievements(modelContext: ModelContext) -> [ReadingAchievement] {
        let descriptor = FetchDescriptor<ReadingAchievement>(
            sortBy: [SortDescriptor(\ReadingAchievement.sortOrder)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private static func fetchBooks(modelContext: ModelContext) -> [Book] {
        let descriptor = FetchDescriptor<Book>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private static func fetchReviews(modelContext: ModelContext) -> [BookReview] {
        let descriptor = FetchDescriptor<BookReview>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private static func fetchSessions(modelContext: ModelContext) -> [ReadingSession] {
        let descriptor = FetchDescriptor<ReadingSession>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private static func fetchNotes(modelContext: ModelContext) -> [BookNote] {
        let descriptor = FetchDescriptor<BookNote>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private static func fetchQuotes(modelContext: ModelContext) -> [BookQuote] {
        let descriptor = FetchDescriptor<BookQuote>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Calculations

    private static func calculatePagesRead(from books: [Book]) -> Int {
        books
            .filter { !$0.isArchived }
            .reduce(0) { total, book in
                if book.status == .finished, book.totalPages > 0 {
                    return total + max(book.totalPages, book.currentPage, book.ebookTotalPages)
                }

                return total + max(book.currentPage, 0)
            }
    }

    private static func calculateFinishedBooks(from books: [Book]) -> Int {
        books
            .filter { !$0.isArchived }
            .filter { $0.status == .finished }
            .count
    }

    private static func calculateLongestReadingStreak(from sessions: [ReadingSession]) -> Int {
        let calendar = Calendar.current
        let sortedDays = Array(Set(sessions.map { calendar.startOfDay(for: $0.date) })).sorted()
        guard !sortedDays.isEmpty else { return 0 }

        var best = 1
        var current = 1

        for index in 1..<sortedDays.count {
            let previous = sortedDays[index - 1]
            let currentDay = sortedDays[index]
            let expectedNextDay = calendar.date(byAdding: .day, value: 1, to: previous) ?? previous

            if calendar.isDate(currentDay, inSameDayAs: expectedNextDay) {
                current += 1
            } else {
                current = 1
            }

            best = max(best, current)
        }

        return best
    }

    private static func calculateFinishedSeries(books: [Book]) -> Int {
        let seriesBooks = books
            .filter { !$0.isArchived }
            .filter { !$0.seriesName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        let grouped = Dictionary(grouping: seriesBooks) { book in
            book.seriesName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        return grouped.values.reduce(0) { total, booksInSeries in
            guard booksInSeries.count > 1 else { return total }

            let allTrackedBooksAreFinished = booksInSeries.allSatisfy { book in
                book.status == .finished
            }

            return allTrackedBooksAreFinished ? total + 1 : total
        }
    }
}

private struct AchievementValues {
    let pagesRead: Int
    let booksFinished: Int
    let reviewsWritten: Int
    let quotesSaved: Int
    let notesWritten: Int
    let readingStreak: Int
    let seriesFinished: Int

    func value(for type: AchievementType) -> Int {
        switch type {
        case .pagesRead:
            return pagesRead
        case .booksFinished:
            return booksFinished
        case .reviewsWritten:
            return reviewsWritten
        case .quotesSaved:
            return quotesSaved
        case .notesWritten:
            return notesWritten
        case .readingStreak:
            return readingStreak
        case .seriesFinished:
            return seriesFinished
        }
    }
}
