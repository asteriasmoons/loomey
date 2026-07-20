//
//  LibraryImportExportService.swift
//  Lumey
//

import Foundation
import UniformTypeIdentifiers

extension UTType {
    static var lumeyCSV: UTType {
        UTType(filenameExtension: "csv") ?? .plainText
    }
}

struct LibraryImportResult {
    let books: [Book]
    let skippedDuplicates: Int
    let skippedInvalidRows: Int

    var importedCount: Int {
        books.count
    }
}

enum LibraryImportExportError: LocalizedError {
    case unreadableFile
    case missingTitleColumn
    case emptyExport

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            return "Lumey couldn't read that file."
        case .missingTitleColumn:
            return "That CSV does not look like a Goodreads library export."
        case .emptyExport:
            return "There are no books to export yet."
        }
    }
}

enum LibraryImportExportService {
    static func importGoodreadsBooks(from url: URL, existingBooks: [Book]) throws -> LibraryImportResult {
        let csv = try readCSVString(from: url)
        let rows = parseCSV(csv)

        guard let header = rows.first else {
            throw LibraryImportExportError.unreadableFile
        }

        let headerIndex = indexHeaders(header)
        guard headerIndex["title"] != nil else {
            throw LibraryImportExportError.missingTitleColumn
        }

        var seenKeys = Set(existingBooks.map(bookIdentityKey))
        var importedBooks: [Book] = []
        var skippedDuplicates = 0
        var skippedInvalidRows = 0

        for row in rows.dropFirst() {
            guard row.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
                continue
            }

            guard let book = goodreadsBook(from: row, headerIndex: headerIndex) else {
                skippedInvalidRows += 1
                continue
            }

            let key = bookIdentityKey(book)
            guard !key.isEmpty else {
                skippedInvalidRows += 1
                continue
            }

            guard !seenKeys.contains(key) else {
                skippedDuplicates += 1
                continue
            }

            seenKeys.insert(key)
            importedBooks.append(book)
        }

        return LibraryImportResult(
            books: importedBooks,
            skippedDuplicates: skippedDuplicates,
            skippedInvalidRows: skippedInvalidRows
        )
    }

    static func lumeyExportCSV(from books: [Book]) throws -> String {
        let exportBooks = books
            .filter { $0.deletedAt == nil }
            .sorted {
                $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
            }

        guard !exportBooks.isEmpty else {
            throw LibraryImportExportError.emptyExport
        }

        let headers = [
            "Title",
            "Author",
            "Subtitle",
            "Series Name",
            "Series Number",
            "Publisher",
            "Publication Year",
            "ISBN",
            "Rating",
            "Status",
            "Format",
            "Ownership",
            "Current Page",
            "Total Pages",
            "Current Chapter",
            "Total Chapters",
            "Progress Percent",
            "Genres",
            "Moods",
            "Topics",
            "Tags",
            "Tropes",
            "Review",
            "Favorite Quote",
            "Notes",
            "Cover URL",
            "Date Added",
            "Date Started",
            "Date Finished",
            "Is Favorite",
            "Is Archived",
            "Is DNF",
            "Is Reread"
        ]

        var lines = [csvLine(headers)]

        for book in exportBooks {
            lines.append(csvLine([
                book.title,
                book.author,
                book.subtitle,
                book.seriesName,
                book.seriesNumber,
                book.publisher,
                book.publicationYear,
                book.isbn,
                decimalString(book.rating),
                book.status.rawValue,
                book.format.rawValue,
                book.ownership.rawValue,
                String(book.currentPage),
                String(book.totalPages),
                String(book.currentChapter),
                String(book.totalChapters),
                decimalString(book.progressPercent),
                book.genres.joined(separator: ", "),
                book.moods.joined(separator: ", "),
                book.topics.joined(separator: ", "),
                book.tags.joined(separator: ", "),
                book.tropes.joined(separator: ", "),
                book.review,
                book.favoriteQuote,
                book.notes,
                book.coverURL,
                exportDateFormatter.string(from: book.dateAdded),
                book.dateStarted.map(exportDateFormatter.string(from:)) ?? "",
                book.dateFinished.map(exportDateFormatter.string(from:)) ?? "",
                book.isFavorite ? "true" : "false",
                book.isArchived ? "true" : "false",
                book.isDNF ? "true" : "false",
                book.isReread ? "true" : "false"
            ]))
        }

        return lines.joined(separator: "\n")
    }

    private static func readCSVString(from url: URL) throws -> String {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)

        if let string = String(data: data, encoding: .utf8) {
            return string
        }

        if let string = String(data: data, encoding: .isoLatin1) {
            return string
        }

        throw LibraryImportExportError.unreadableFile
    }

    private static func goodreadsBook(from row: [String], headerIndex: [String: Int]) -> Book? {
        let title = value(["title"], in: row, headerIndex: headerIndex)
        guard !title.isEmpty else { return nil }

        let author = value(["author", "author l f"], in: row, headerIndex: headerIndex)
        let isbn13 = cleanedISBN(value(["isbn13"], in: row, headerIndex: headerIndex))
        let isbn = isbn13.isEmpty ? cleanedISBN(value(["isbn"], in: row, headerIndex: headerIndex)) : isbn13
        let exclusiveShelf = value(["exclusive shelf"], in: row, headerIndex: headerIndex)
        let shelves = shelfValues(from: value(["bookshelves"], in: row, headerIndex: headerIndex))
        let status = statusFromGoodreadsShelf(exclusiveShelf)
        let totalPages = intValue(value(["number of pages"], in: row, headerIndex: headerIndex))
        let dateRead = dateValue(value(["date read"], in: row, headerIndex: headerIndex))
        let dateAdded = dateValue(value(["date added"], in: row, headerIndex: headerIndex)) ?? Date()
        let myReview = value(["my review"], in: row, headerIndex: headerIndex)
        let privateNotes = value(["private notes"], in: row, headerIndex: headerIndex)
        let notes = importNotes(privateNotes: privateNotes)
        let readCount = intValue(value(["read count"], in: row, headerIndex: headerIndex))
        let tags = shelves.filter { !isStatusShelf($0) }

        return Book(
            title: title,
            author: author,
            publisher: value(["publisher"], in: row, headerIndex: headerIndex),
            publicationYear: value(["year published", "original publication year"], in: row, headerIndex: headerIndex),
            isbn: isbn,
            rating: ratingValue(value(["my rating"], in: row, headerIndex: headerIndex)),
            status: status,
            format: formatFromBinding(value(["binding"], in: row, headerIndex: headerIndex)),
            ownership: .unknown,
            totalPages: totalPages,
            review: myReview,
            notes: notes,
            tags: tags,
            dateAdded: dateAdded,
            dateFinished: status == .finished ? dateRead : nil,
            isFavorite: tags.contains { $0.localizedCaseInsensitiveContains("favorite") },
            isReread: readCount > 1
        )
    }

    private static func indexHeaders(_ header: [String]) -> [String: Int] {
        var index: [String: Int] = [:]

        for (offset, rawHeader) in header.enumerated() {
            let key = normalizedHeader(rawHeader)
            if !key.isEmpty {
                index[key] = offset
            }
        }

        return index
    }

    private static func normalizedHeader(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\u{feff}", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private static func value(_ keys: [String], in row: [String], headerIndex: [String: Int]) -> String {
        for key in keys {
            guard let index = headerIndex[normalizedHeader(key)], index < row.count else { continue }
            let value = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty {
                return value
            }
        }

        return ""
    }

    private static func parseCSV(_ csv: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false

        let characters = Array(csv)
        var index = 0

        while index < characters.count {
            let character = characters[index]

            if character == "\"" {
                if inQuotes, index + 1 < characters.count, characters[index + 1] == "\"" {
                    field.append("\"")
                    index += 1
                } else {
                    inQuotes.toggle()
                }
            } else if character == ",", !inQuotes {
                row.append(field)
                field = ""
            } else if (character == "\n" || character == "\r"), !inQuotes {
                if character == "\r", index + 1 < characters.count, characters[index + 1] == "\n" {
                    index += 1
                }

                row.append(field)
                rows.append(row)
                row = []
                field = ""
            } else {
                field.append(character)
            }

            index += 1
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }

        return rows
    }

    private static func cleanedISBN(_ value: String) -> String {
        value.filter { $0.isNumber || $0 == "X" || $0 == "x" }
    }

    private static func shelfValues(from value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func isStatusShelf(_ value: String) -> Bool {
        let shelf = value.lowercased()
        return shelf == "read" || shelf == "currently-reading" || shelf == "currently reading" || shelf == "to-read" || shelf == "to read"
    }

    private static func statusFromGoodreadsShelf(_ value: String) -> BookStatus {
        let shelf = value.lowercased()

        if shelf == "read" {
            return .finished
        }

        if shelf == "currently-reading" || shelf == "currently reading" {
            return .reading
        }

        return .toBeRead
    }

    private static func formatFromBinding(_ value: String) -> BookFormat {
        let binding = value.lowercased()

        if binding.contains("kindle") || binding.contains("ebook") || binding.contains("nook") {
            return .ebook
        }

        if binding.contains("audio") {
            return .audiobook
        }

        if binding.contains("library") {
            return .library
        }

        if binding.contains("hardcover") || binding.contains("paperback") || binding.contains("mass market") {
            return .physical
        }

        return .other
    }

    private static func intValue(_ value: String) -> Int {
        Int(value.filter { $0.isNumber }) ?? 0
    }

    private static func ratingValue(_ value: String) -> Double {
        guard let rating = Double(value.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return 0
        }

        return min(max(rating, 0), 5)
    }

    private static func dateValue(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        for formatter in importDateFormatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        return nil
    }

    private static func importNotes(privateNotes: String) -> String {
        let trimmedNotes = privateNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedNotes.isEmpty {
            return "Imported from Goodreads."
        }

        return "Imported from Goodreads.\n\nGoodreads private notes:\n\(trimmedNotes)"
    }

    private static func bookIdentityKey(_ book: Book) -> String {
        let isbn = cleanedISBN(book.isbn)

        if !isbn.isEmpty {
            return "isbn:\(isbn.lowercased())"
        }

        let title = book.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let author = book.author.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !title.isEmpty else { return "" }
        return "book:\(title)|\(author)"
    }

    private static func csvLine(_ fields: [String]) -> String {
        fields.map(csvEscape).joined(separator: ",")
    }

    private static func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")

        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") || escaped.contains("\r") {
            return "\"\(escaped)\""
        }

        return escaped
    }

    private static func decimalString(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private static var importDateFormatters: [DateFormatter] {
        [
            dateFormatter("yyyy/MM/dd"),
            dateFormatter("yyyy-MM-dd"),
            dateFormatter("MM/dd/yyyy"),
            dateFormatter("M/d/yyyy"),
            dateFormatter("MMM d, yyyy"),
            dateFormatter("MMMM d, yyyy")
        ]
    }

    private static var exportDateFormatter: DateFormatter {
        dateFormatter("yyyy-MM-dd")
    }

    private static func dateFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }
}
