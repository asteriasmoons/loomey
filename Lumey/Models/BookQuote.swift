//
//  BookQuote.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class BookQuote {
    var id: UUID = UUID()
    var text: String = ""
    var pageNumber: String = ""
    var dateCreated: Date = Date()
    var lastUpdated: Date = Date()

    var book: Book?

    init(text: String = "", pageNumber: String = "", book: Book? = nil) {
        self.id = UUID()
        self.text = text
        self.pageNumber = pageNumber
        self.book = book
        self.dateCreated = Date()
        self.lastUpdated = Date()
    }
}
