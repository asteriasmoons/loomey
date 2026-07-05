//
//  BookReview.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class BookReview {
    var id: UUID = UUID()
    var title: String = ""
    var content: String = ""
    var rating: Double = 0
    var dateCreated: Date = Date()
    var lastUpdated: Date = Date()

    var book: Book?

    init(title: String = "", content: String = "", rating: Double = 0, book: Book? = nil) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.rating = rating
        self.book = book
        self.dateCreated = Date()
        self.lastUpdated = Date()
    }
}
