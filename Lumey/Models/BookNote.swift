//
//  BookNote.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class BookNote {
    var id: UUID = UUID()
    var content: String = ""
    var dateCreated: Date = Date()
    var lastUpdated: Date = Date()

    var book: Book?

    init(content: String = "", book: Book? = nil) {
        self.id = UUID()
        self.content = content
        self.book = book
        self.dateCreated = Date()
        self.lastUpdated = Date()
    }
}
