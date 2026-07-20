//
//  ReadingLibraryCustomFilter.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ReadingLibraryCustomFilter {
    var id: UUID = UUID()
    var title: String = ""
    var sortIndex: Int = 0
    var createdAt: Date = Date()

    init(
        title: String,
        sortIndex: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.title = title
        self.sortIndex = sortIndex
        self.createdAt = createdAt
    }
}
