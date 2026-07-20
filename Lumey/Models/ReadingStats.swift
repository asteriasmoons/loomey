//
//  ReadingStats.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ReadingStats {
    var id: UUID = UUID()
    
    // Streaks
    var currentReadingStreak: Int = 0
    var bestReadingStreak: Int = 0
    var lastReadingDate: Date?
    
    // Daily Tracking
    var pagesReadToday: Int = 0
    var minutesReadToday: Int = 0
    
    // Lifetime Totals
    var totalPagesRead: Int = 0
    var totalBooksFinished: Int = 0
    var totalMinutesRead: Int = 0
    
    // Monthly Stats
    var booksFinishedThisMonth: Int = 0
    var pagesReadThisMonth: Int = 0
    var minutesReadThisMonth: Int = 0
    
    // Yearly Stats
    var booksFinishedThisYear: Int = 0
    var pagesReadThisYear: Int = 0
    
    // Sessions
    var totalReadingSessions: Int = 0
    var longestReadingSessionMinutes: Int = 0
    
    // Favorites
    var favoriteGenre: String = ""
    var favoriteAuthor: String = ""
    
    // Reading Break
    var readingBreakStartDate: Date?
    var readingBreakStreakValue: Int = 0
    var totalReadingBreakDays: Int = 0
    var breakPeriodsStorage: String = "[]"

    // Dates
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(
        currentReadingStreak: Int = 0,
        bestReadingStreak: Int = 0,
        lastReadingDate: Date? = nil,
        pagesReadToday: Int = 0,
        minutesReadToday: Int = 0,
        totalPagesRead: Int = 0,
        totalBooksFinished: Int = 0,
        totalMinutesRead: Int = 0,
        booksFinishedThisMonth: Int = 0,
        pagesReadThisMonth: Int = 0,
        minutesReadThisMonth: Int = 0,
        booksFinishedThisYear: Int = 0,
        pagesReadThisYear: Int = 0,
        totalReadingSessions: Int = 0,
        longestReadingSessionMinutes: Int = 0,
        favoriteGenre: String = "",
        favoriteAuthor: String = "",
        readingBreakStartDate: Date? = nil,
        readingBreakStreakValue: Int = 0,
        totalReadingBreakDays: Int = 0,
        breakPeriodsStorage: String = "[]"
    ) {
        self.id = UUID()

        self.currentReadingStreak = currentReadingStreak
        self.bestReadingStreak = bestReadingStreak
        self.lastReadingDate = lastReadingDate

        self.pagesReadToday = pagesReadToday
        self.minutesReadToday = minutesReadToday

        self.totalPagesRead = totalPagesRead
        self.totalBooksFinished = totalBooksFinished
        self.totalMinutesRead = totalMinutesRead

        self.booksFinishedThisMonth = booksFinishedThisMonth
        self.pagesReadThisMonth = pagesReadThisMonth
        self.minutesReadThisMonth = minutesReadThisMonth

        self.booksFinishedThisYear = booksFinishedThisYear
        self.pagesReadThisYear = pagesReadThisYear

        self.totalReadingSessions = totalReadingSessions
        self.longestReadingSessionMinutes = longestReadingSessionMinutes

        self.favoriteGenre = favoriteGenre
        self.favoriteAuthor = favoriteAuthor

        self.readingBreakStartDate = readingBreakStartDate
        self.readingBreakStreakValue = readingBreakStreakValue
        self.totalReadingBreakDays = totalReadingBreakDays
        self.breakPeriodsStorage = breakPeriodsStorage

        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Reading Break Period

struct ReadingBreakPeriod: Codable, Identifiable {
    var id: UUID = UUID()
    let startDate: Date
    let endDate: Date
}

// MARK: - Reading Break Helpers

extension ReadingStats {
    static let maxBreakDays: Int = 14

    static func preferredRecord(from records: [ReadingStats]) -> ReadingStats? {
        records.max { lhs, rhs in
            let lhsActiveBreak = lhs.isOnReadingBreak && lhs.currentBreakDays <= Self.maxBreakDays
            let rhsActiveBreak = rhs.isOnReadingBreak && rhs.currentBreakDays <= Self.maxBreakDays

            if lhsActiveBreak != rhsActiveBreak {
                return !lhsActiveBreak && rhsActiveBreak
            }

            return lhs.updatedAt < rhs.updatedAt
        }
    }

    static func fetchOrCreate(in modelContext: ModelContext) -> ReadingStats {
        let records = (try? modelContext.fetch(FetchDescriptor<ReadingStats>())) ?? []

        if let preferred = preferredRecord(from: records) {
            return preferred
        }

        let stats = ReadingStats()
        modelContext.insert(stats)
        return stats
    }

    var isOnReadingBreak: Bool {
        readingBreakStartDate != nil
    }

    var currentBreakDays: Int {
        guard let start = readingBreakStartDate else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: start), to: Calendar.current.startOfDay(for: Date())).day ?? 0)
    }

    var breakPeriods: [ReadingBreakPeriod] {
        get {
            guard let data = breakPeriodsStorage.data(using: .utf8),
                  let periods = try? JSONDecoder().decode([ReadingBreakPeriod].self, from: data) else {
                return []
            }
            return periods
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let string = String(data: data, encoding: .utf8) else {
                breakPeriodsStorage = "[]"
                return
            }
            breakPeriodsStorage = string
        }
    }

    func startBreak(currentStreak: Int) {
        guard !isOnReadingBreak else { return }
        readingBreakStartDate = Date()
        readingBreakStreakValue = currentStreak
        updatedAt = Date()
    }

    func endBreak() {
        guard let start = readingBreakStartDate else { return }
        let now = Date()
        let days = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: start), to: Calendar.current.startOfDay(for: now)).day ?? 0)

        var periods = breakPeriods
        periods.append(ReadingBreakPeriod(startDate: start, endDate: now))
        breakPeriods = periods

        totalReadingBreakDays += days
        readingBreakStartDate = nil
        updatedAt = Date()
    }

    /// Auto-expire the break if it exceeded the maximum duration.
    func checkAndExpireBreak() {
        guard isOnReadingBreak, currentBreakDays > Self.maxBreakDays else { return }
        endBreak()
        // Streak resets after an expired break since the user didn't resume in time
        readingBreakStreakValue = 0
        updatedAt = Date()
    }

    /// Returns `true` when the gap between two dates is fully covered by completed break periods.
    func shouldBridgeStreakGap(from lastDate: Date, to currentDate: Date) -> Bool {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: lastDate)
        let endDay = calendar.startOfDay(for: currentDate)
        guard startDay < endDay else { return false }

        var day = calendar.date(byAdding: .day, value: 1, to: startDay) ?? startDay
        let periods = breakPeriods

        while day < endDay {
            if !Self.isDateInBreakPeriod(day, periods: periods) {
                return false
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { return false }
            day = next
        }
        return true
    }

    static func isDateInBreakPeriod(_ date: Date, periods: [ReadingBreakPeriod]) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        for period in periods {
            let periodStart = calendar.startOfDay(for: period.startDate)
            let periodEnd = calendar.startOfDay(for: period.endDate)
            if dayStart >= periodStart && dayStart <= periodEnd {
                return true
            }
        }
        return false
    }
}
