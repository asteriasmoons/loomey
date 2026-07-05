//
//  EPUBFileAccess.swift
//  Lumey
//

import Foundation
import UniformTypeIdentifiers

extension UTType {
    static var epubFile: UTType {
        UTType(filenameExtension: "epub") ?? .data
    }
}

enum EPUBFileAccess {
    static func attachEPUB(from url: URL, to book: Book) throws {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let bookmarkData = try url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        book.epubBookmarkData = bookmarkData
        book.epubOriginalFileName = url.lastPathComponent
        book.format = .ebook
        book.updatedAt = Date()
        book.lastUpdated = Date()
    }

    static func resolvedEPUBURL(for book: Book) throws -> URL? {
        guard let bookmarkData = book.epubBookmarkData else {
            return nil
        }

        var isStale = false

        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        return url
    }
}
