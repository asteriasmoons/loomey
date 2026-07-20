//
//  EPUBFileAccess.swift
//  Lumey
//

import Foundation
import UIKit
import UniformTypeIdentifiers

extension UTType {
    static var epubFile: UTType {
        UTType(filenameExtension: "epub") ?? .data
    }
}

// MARK: - EPUB Metadata

struct EPUBMetadata {
    var title: String = ""
    var author: String = ""
    var coverImageData: Data?
}

enum EPUBFileAccess {

    // MARK: - Local Cache Directory

    private static var epubCacheDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("EPUBs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func cachedFileURL(for book: Book) -> URL {
        let safeName = book.id.uuidString + ".epub"
        return epubCacheDirectory.appendingPathComponent(safeName)
    }

    // MARK: - Attach

    static func attachEPUB(from url: URL, to book: Book) throws {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Read the actual file bytes
        let fileData = try Data(contentsOf: url)

        // Store the bytes in SwiftData (syncs via CloudKit)
        book.epubFileData = fileData

        // Cache locally for fast access
        let cacheURL = cachedFileURL(for: book)
        try fileData.write(to: cacheURL, options: .atomic)

        book.epubOriginalFileName = url.lastPathComponent
        book.epubBookmarkData = nil
        book.format = .ebook
        book.updatedAt = Date()
        book.lastUpdated = Date()
    }

    // MARK: - Resolve

    static func resolvedEPUBURL(for book: Book) throws -> URL? {
        let cacheURL = cachedFileURL(for: book)

        // 1. Check local cache first (fastest path)
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            return cacheURL
        }

        // 2. File data synced from another device — write to local cache
        if let fileData = book.epubFileData {
            try fileData.write(to: cacheURL, options: .atomic)
            return cacheURL
        }

        // 3. Legacy fallback — old bookmark-based import (same device only)
        if let bookmarkData = book.epubBookmarkData {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return url
        }

        return nil
    }

    // MARK: - Metadata Extraction

    /// Parses an EPUB ZIP archive to extract title, author, and cover image.
    static func extractMetadata(from url: URL) -> EPUBMetadata {
        var metadata = EPUBMetadata()

        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        guard let archive = try? EPUBZipReader(url: url) else { return metadata }

        // 1. Find OPF path from META-INF/container.xml
        guard let containerData = archive.readEntry("META-INF/container.xml"),
              let containerXML = String(data: containerData, encoding: .utf8),
              let opfPath = parseRootfilePath(from: containerXML) else {
            return metadata
        }

        // 2. Parse OPF for metadata + cover reference
        guard let opfData = archive.readEntry(opfPath),
              let opfXML = String(data: opfData, encoding: .utf8) else {
            return metadata
        }

        let opfDir = (opfPath as NSString).deletingLastPathComponent

        metadata.title = parseOPFValue(opfXML, tag: "dc:title")
            ?? parseOPFValue(opfXML, tag: "title")
            ?? ""
        metadata.author = parseOPFValue(opfXML, tag: "dc:creator")
            ?? parseOPFValue(opfXML, tag: "creator")
            ?? ""

        // 3. Find cover image
        if let coverHref = parseCoverHref(from: opfXML) {
            let coverPath = opfDir.isEmpty ? coverHref : opfDir + "/" + coverHref
            // Normalize path (remove ./ prefixes, resolve relative components)
            let normalizedPath = (coverPath as NSString).standardizingPath
                .replacingOccurrences(of: "^\\./", with: "", options: .regularExpression)

            if let imageData = archive.readEntry(normalizedPath) ?? archive.readEntry(coverHref) {
                // Compress to JPEG to save storage
                if let uiImage = UIImage(data: imageData),
                   let jpegData = uiImage.jpegData(compressionQuality: 0.82) {
                    metadata.coverImageData = jpegData
                } else {
                    metadata.coverImageData = imageData
                }
            }
        }

        return metadata
    }

    // MARK: - XML Helpers (lightweight, no external dependency)

    private static func parseRootfilePath(from xml: String) -> String? {
        // <rootfile full-path="OEBPS/content.opf" .../>
        guard let range = xml.range(of: "full-path=\"", options: .caseInsensitive) else { return nil }
        let after = xml[range.upperBound...]
        guard let end = after.firstIndex(of: "\"") else { return nil }
        return String(after[..<end])
    }

    private static func parseOPFValue(_ xml: String, tag: String) -> String? {
        // Find <tag...>value</tag> — handles attributes on the opening tag
        let openPattern = "<" + tag
        guard let openStart = xml.range(of: openPattern, options: .caseInsensitive) else { return nil }
        let afterOpen = xml[openStart.upperBound...]
        guard let gtIndex = afterOpen.firstIndex(of: ">") else { return nil }
        let contentStart = afterOpen.index(after: gtIndex)
        let closeTag = "</" + tag
        guard let closeRange = xml.range(of: closeTag, options: .caseInsensitive, range: contentStart..<xml.endIndex) else { return nil }
        let value = String(xml[contentStart..<closeRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private static func parseCoverHref(from opfXML: String) -> String? {
        // Strategy 1: <meta name="cover" content="cover-id"/> → find manifest item with that id
        if let coverId = parseCoverMetaContent(from: opfXML),
           let href = findManifestItemHref(id: coverId, in: opfXML) {
            return href
        }

        // Strategy 2: manifest item with properties="cover-image"
        if let href = findManifestCoverImageProperty(in: opfXML) {
            return href
        }

        // Strategy 3: manifest item whose id contains "cover" and has an image media-type
        if let href = findManifestCoverByIdHeuristic(in: opfXML) {
            return href
        }

        return nil
    }

    private static func parseCoverMetaContent(from xml: String) -> String? {
        // <meta name="cover" content="cover-image-id"/>
        guard let metaRange = xml.range(of: "name=\"cover\"", options: .caseInsensitive) else { return nil }
        // Look in the surrounding <meta .../> tag for the content attribute
        // Search backwards for < and forwards for >
        let lineStart = xml[..<metaRange.lowerBound].lastIndex(of: "<") ?? xml.startIndex
        let lineEnd = xml[metaRange.upperBound...].firstIndex(of: ">") ?? xml.endIndex
        let metaTag = String(xml[lineStart...lineEnd])

        guard let contentRange = metaTag.range(of: "content=\"", options: .caseInsensitive) else { return nil }
        let after = metaTag[contentRange.upperBound...]
        guard let end = after.firstIndex(of: "\"") else { return nil }
        let value = String(after[..<end])
        return value.isEmpty ? nil : value
    }

    private static func findManifestItemHref(id: String, in xml: String) -> String? {
        // Find <item id="<id>" ... href="..."/>
        let searchID = "id=\"\(id)\""
        guard let idRange = xml.range(of: searchID, options: .caseInsensitive) else { return nil }
        let lineStart = xml[..<idRange.lowerBound].lastIndex(of: "<") ?? xml.startIndex
        let lineEnd = xml[idRange.upperBound...].firstIndex(of: ">") ?? xml.endIndex
        let itemTag = String(xml[lineStart...lineEnd])

        guard let hrefRange = itemTag.range(of: "href=\"", options: .caseInsensitive) else { return nil }
        let after = itemTag[hrefRange.upperBound...]
        guard let end = after.firstIndex(of: "\"") else { return nil }
        let value = String(after[..<end])
        return value.isEmpty ? nil : value
    }

    private static func findManifestCoverImageProperty(in xml: String) -> String? {
        // <item ... properties="cover-image" ... href="..."/>
        guard let propRange = xml.range(of: "properties=\"cover-image\"", options: .caseInsensitive) else { return nil }
        let lineStart = xml[..<propRange.lowerBound].lastIndex(of: "<") ?? xml.startIndex
        let lineEnd = xml[propRange.upperBound...].firstIndex(of: ">") ?? xml.endIndex
        let itemTag = String(xml[lineStart...lineEnd])

        guard let hrefRange = itemTag.range(of: "href=\"", options: .caseInsensitive) else { return nil }
        let after = itemTag[hrefRange.upperBound...]
        guard let end = after.firstIndex(of: "\"") else { return nil }
        return String(after[..<end])
    }

    private static func findManifestCoverByIdHeuristic(in xml: String) -> String? {
        // Scan all <item> tags for one whose id contains "cover" and media-type starts with "image/"
        var searchStart = xml.startIndex
        while let itemRange = xml.range(of: "<item ", options: .caseInsensitive, range: searchStart..<xml.endIndex) {
            let tagEnd = xml[itemRange.upperBound...].firstIndex(of: ">") ?? xml.endIndex
            let itemTag = String(xml[itemRange.lowerBound...tagEnd]).lowercased()
            searchStart = xml.index(after: tagEnd)

            guard itemTag.contains("image/") else { continue }

            // Check if id contains "cover"
            if let idRange = itemTag.range(of: "id=\"") {
                let after = itemTag[idRange.upperBound...]
                if let end = after.firstIndex(of: "\"") {
                    let idValue = String(after[..<end])
                    if idValue.contains("cover") {
                        // Extract href
                        if let hrefRange = itemTag.range(of: "href=\"") {
                            let hAfter = itemTag[hrefRange.upperBound...]
                            if let hEnd = hAfter.firstIndex(of: "\"") {
                                return String(hAfter[..<hEnd])
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - Minimal ZIP Reader for EPUB

/// Reads individual entries from a ZIP archive (EPUB) without extracting the whole file.
/// Uses Apple's built-in compression framework via FileHandle + local file headers.
private final class EPUBZipReader {
    private let fileHandle: FileHandle
    private var entries: [String: (offset: UInt64, compressedSize: UInt64, uncompressedSize: UInt64, method: UInt16)] = [:]

    init?(url: URL) {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        self.fileHandle = handle
        parseEntries()
    }

    deinit {
        try? fileHandle.close()
    }

    func readEntry(_ path: String) -> Data? {
        // Try exact path first, then URL-decoded, then case-insensitive
        let normalized = path.removingPercentEncoding ?? path
        let key = entries.keys.first(where: { $0 == normalized })
            ?? entries.keys.first(where: { $0 == path })
            ?? entries.keys.first(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame })

        guard let key, let entry = entries[key] else { return nil }

        fileHandle.seek(toFileOffset: entry.offset)

        // Re-read local file header to get actual header size (name + extra field lengths may differ)
        let localHeader = fileHandle.readData(ofLength: 30)
        guard localHeader.count == 30 else { return nil }

        let nameLen = UInt16(localHeader[26]) | (UInt16(localHeader[27]) << 8)
        let extraLen = UInt16(localHeader[28]) | (UInt16(localHeader[29]) << 8)
        let dataOffset = entry.offset + 30 + UInt64(nameLen) + UInt64(extraLen)

        fileHandle.seek(toFileOffset: dataOffset)
        let compressedData = fileHandle.readData(ofLength: Int(entry.compressedSize))

        if entry.method == 0 {
            // Stored (no compression)
            return compressedData
        } else if entry.method == 8 {
            // Deflate — use built-in decompression
            return decompressDeflate(compressedData, uncompressedSize: Int(entry.uncompressedSize))
        }
        return nil
    }

    private func parseEntries() {
        // Find end-of-central-directory record
        fileHandle.seekToEndOfFile()
        let fileSize = fileHandle.offsetInFile
        guard fileSize > 22 else { return }

        // Search backwards for EOCD signature 0x06054b50
        let searchLen = min(fileSize, 65557)
        let searchOffset = fileSize - searchLen
        fileHandle.seek(toFileOffset: searchOffset)
        let tailData = fileHandle.readData(ofLength: Int(searchLen))

        var eocdOffset: Int?
        let sig: [UInt8] = [0x50, 0x4B, 0x05, 0x06]
        for i in stride(from: tailData.count - 4, through: 0, by: -1) {
            if tailData[i] == sig[0] && tailData[i+1] == sig[1] && tailData[i+2] == sig[2] && tailData[i+3] == sig[3] {
                eocdOffset = i
                break
            }
        }

        guard let eocdOff = eocdOffset else { return }

        let cdOffset = UInt32(tailData[eocdOff + 16])
            | (UInt32(tailData[eocdOff + 17]) << 8)
            | (UInt32(tailData[eocdOff + 18]) << 16)
            | (UInt32(tailData[eocdOff + 19]) << 24)

        let cdSize = UInt32(tailData[eocdOff + 12])
            | (UInt32(tailData[eocdOff + 13]) << 8)
            | (UInt32(tailData[eocdOff + 14]) << 16)
            | (UInt32(tailData[eocdOff + 15]) << 24)

        fileHandle.seek(toFileOffset: UInt64(cdOffset))
        let cdData = fileHandle.readData(ofLength: Int(cdSize))

        var pos = 0
        while pos + 46 <= cdData.count {
            // Central directory header signature: 0x02014b50
            guard cdData[pos] == 0x50, cdData[pos+1] == 0x4B, cdData[pos+2] == 0x01, cdData[pos+3] == 0x02 else { break }

            let method = UInt16(cdData[pos + 10]) | (UInt16(cdData[pos + 11]) << 8)
            let compSize = UInt32(cdData[pos + 20]) | (UInt32(cdData[pos + 21]) << 8) | (UInt32(cdData[pos + 22]) << 16) | (UInt32(cdData[pos + 23]) << 24)
            let uncompSize = UInt32(cdData[pos + 24]) | (UInt32(cdData[pos + 25]) << 8) | (UInt32(cdData[pos + 26]) << 16) | (UInt32(cdData[pos + 27]) << 24)
            let nameLen = Int(UInt16(cdData[pos + 28]) | (UInt16(cdData[pos + 29]) << 8))
            let extraLen = Int(UInt16(cdData[pos + 30]) | (UInt16(cdData[pos + 31]) << 8))
            let commentLen = Int(UInt16(cdData[pos + 32]) | (UInt16(cdData[pos + 33]) << 8))
            let localOffset = UInt32(cdData[pos + 42]) | (UInt32(cdData[pos + 43]) << 8) | (UInt32(cdData[pos + 44]) << 16) | (UInt32(cdData[pos + 45]) << 24)

            if pos + 46 + nameLen <= cdData.count {
                let nameData = cdData[(pos + 46)..<(pos + 46 + nameLen)]
                if let name = String(data: Data(nameData), encoding: .utf8) {
                    entries[name] = (
                        offset: UInt64(localOffset),
                        compressedSize: UInt64(compSize),
                        uncompressedSize: UInt64(uncompSize),
                        method: method
                    )
                }
            }

            pos += 46 + nameLen + extraLen + commentLen
        }
    }

    private func decompressDeflate(_ data: Data, uncompressedSize: Int) -> Data? {
        // Use NSData's built-in decompression (available since iOS 13)
        let nsData = data as NSData
        // Raw deflate: add zlib header (0x78, 0x9C) so NSData can decompress
        var zlibData = Data([0x78, 0x9C])
        zlibData.append(data)

        if let decompressed = try? (zlibData as NSData).decompressed(using: .zlib) as Data {
            return decompressed
        }

        // Fallback: try without header
        if let decompressed = try? nsData.decompressed(using: .zlib) as Data {
            return decompressed
        }

        return nil
    }
}
