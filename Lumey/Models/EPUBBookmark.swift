//
//  EPUBBookmark.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class EPUBBookmark {
    var id: UUID = UUID()

    // Link back to Book
    var bookID: UUID?

    // Display
    var title: String = ""
    var chapterTitle: String = ""
    var note: String = ""

    // Readium locator
    var locatorJSON: String = ""
    var href: String = ""
    var progression: Double = 0

    // Page info
    var pageNumber: Int = 0
    var totalPages: Int = 0

    // Tracking
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date?

    init(
        bookID: UUID? = nil,
        title: String = "",
        chapterTitle: String = "",
        note: String = "",
        locatorJSON: String = "",
        href: String = "",
        progression: Double = 0,
        pageNumber: Int = 0,
        totalPages: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = UUID()
        self.bookID = bookID
        self.title = title
        self.chapterTitle = chapterTitle
        self.note = note
        self.locatorJSON = locatorJSON
        self.href = href
        self.progression = progression
        self.pageNumber = pageNumber
        self.totalPages = totalPages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
