//
//  EPUBHighlight.swift
//  Lumey
//

import Foundation
import UIKit
import SwiftData

enum HighlightColor: String, Codable, CaseIterable, Identifiable {
    case yellow = "Yellow"
    case pink = "Pink"
    case teal = "Teal"
    case orange = "Orange"
    case mint = "Mint"
    case purple = "Purple"

    var id: String { rawValue }

    var hex: String {
        switch self {
        case .yellow: return "#FFE066"
        case .pink:   return "#FF85A1"
        case .teal:   return "#4ECDC4"
        case .orange: return "#FFA552"
        case .mint:   return "#7DDFB0"
        case .purple: return "#B388FF"
        }
    }

    var uiColor: UIColor {
        UIColor(highlightHex: hex)
    }
}

@Model
final class EPUBHighlight {
    var id: UUID = UUID()

    var bookID: UUID?

    // Content
    var highlightedText: String = ""
    var note: String = ""

    // Location
    var chapterTitle: String = ""
    var pageNumber: Int = 0
    var totalPages: Int = 0
    var locatorJSON: String = ""
    var href: String = ""
    var progression: Double = 0

    // Styling
    var highlightColorRaw: String = HighlightColor.yellow.rawValue
    var isQuote: Bool = false

    // Tracking
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date?

    init(
        bookID: UUID? = nil,
        highlightedText: String = "",
        note: String = "",
        chapterTitle: String = "",
        pageNumber: Int = 0,
        totalPages: Int = 0,
        locatorJSON: String = "",
        href: String = "",
        progression: Double = 0,
        highlightColor: HighlightColor = .yellow,
        isQuote: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = UUID()
        self.bookID = bookID
        self.highlightedText = highlightedText
        self.note = note
        self.chapterTitle = chapterTitle
        self.pageNumber = pageNumber
        self.totalPages = totalPages
        self.locatorJSON = locatorJSON
        self.href = href
        self.progression = progression
        self.highlightColorRaw = highlightColor.rawValue
        self.isQuote = isQuote
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

extension EPUBHighlight {
    var highlightColor: HighlightColor {
        get { HighlightColor(rawValue: highlightColorRaw) ?? .yellow }
        set {
            highlightColorRaw = newValue.rawValue
            updatedAt = Date()
        }
    }
}

private extension UIColor {
    convenience init(highlightHex hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
