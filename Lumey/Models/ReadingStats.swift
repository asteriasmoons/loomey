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
        favoriteAuthor: String = ""
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
        
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
