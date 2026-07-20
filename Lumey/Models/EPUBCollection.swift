//
//  EPUBCollection.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class EPUBCollection {
    var id: UUID = UUID()
    var name: String = ""
    var bookIDsStorage: String = "[]"
    var sortIndex: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(name: String, sortIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.sortIndex = sortIndex
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension EPUBCollection {
    var bookIDs: [UUID] {
        get {
            guard let data = bookIDsStorage.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let string = String(data: data, encoding: .utf8) {
                bookIDsStorage = string
            } else {
                bookIDsStorage = "[]"
            }
            updatedAt = Date()
        }
    }

    func contains(_ bookID: UUID) -> Bool {
        bookIDs.contains(bookID)
    }

    func addBook(_ bookID: UUID) {
        guard !contains(bookID) else { return }
        var ids = bookIDs
        ids.append(bookID)
        bookIDs = ids
    }

    func removeBook(_ bookID: UUID) {
        var ids = bookIDs
        ids.removeAll { $0 == bookID }
        bookIDs = ids
    }
}
