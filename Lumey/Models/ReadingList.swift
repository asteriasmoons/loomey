//
//  ReadingList.swift
//  Lumey
//

import Foundation
import SwiftData

// MARK: - Reading List Status

enum ReadingListStatus: String, Codable, CaseIterable, Identifiable {
    case active = "Active"
    case completed = "Completed"
    case archived = "Archived"
    
    var id: String { rawValue }
}

// MARK: - Reading List

@Model
final class ReadingList {
    var id: UUID = UUID()
    
    // Identity
    var title: String = ""
    var listDescription: String = ""
    var iconName: String = "books"
    
    // Status
    var statusRawValue: String = ReadingListStatus.active.rawValue
    
    // Dates
    var dueDate: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Optional Goal Link
    var linkedGoalID: UUID?
    
    // Items stored as JSON array of ReadingListItemData
    var itemsStorage: String = "[]"
    
    init(
        title: String = "",
        listDescription: String = "",
        iconName: String = "books",
        status: ReadingListStatus = .active,
        dueDate: Date? = nil,
        linkedGoalID: UUID? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.listDescription = listDescription
        self.iconName = iconName
        self.statusRawValue = status.rawValue
        self.dueDate = dueDate
        self.createdAt = Date()
        self.updatedAt = Date()
        self.linkedGoalID = linkedGoalID
    }
}

// MARK: - List Item Data (Codable, stored as JSON inside ReadingList)

struct ReadingListItemData: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var bookID: UUID
    var sortOrder: Int = 0
    var isCompleted: Bool = false
    var dateAdded: Date = Date()
    
    static func == (lhs: ReadingListItemData, rhs: ReadingListItemData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties

extension ReadingList {
    var status: ReadingListStatus {
        get { ReadingListStatus(rawValue: statusRawValue) ?? .active }
        set {
            statusRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    var items: [ReadingListItemData] {
        get {
            guard let data = itemsStorage.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([ReadingListItemData].self, from: data)
            else { return [] }
            return decoded.sorted { $0.sortOrder < $1.sortOrder }
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let string = String(data: data, encoding: .utf8)
            else { return }
            itemsStorage = string
            updatedAt = Date()
        }
    }
    
    var bookCount: Int {
        items.count
    }
    
    var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }
    
    var progressValue: Double {
        guard bookCount > 0 else { return 0 }
        return Double(completedCount) / Double(bookCount)
    }
    
    var progressPercentage: Int {
        Int((progressValue * 100).rounded())
    }
    
    var progressText: String {
        "\(completedCount) / \(bookCount) Read"
    }
    
    var displayTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled List" : title
    }
    
    var isActive: Bool {
        status == .active
    }
    
    var daysRemaining: Int? {
        guard let dueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day
    }
    
    // MARK: - Mutating Helpers
    
    func addBook(bookID: UUID) {
        var current = items
        guard !current.contains(where: { $0.bookID == bookID }) else { return }
        let newItem = ReadingListItemData(
            bookID: bookID,
            sortOrder: current.count,
            dateAdded: Date()
        )
        current.append(newItem)
        items = current
    }
    
    func removeBook(bookID: UUID) {
        var current = items
        current.removeAll { $0.bookID == bookID }
        for i in current.indices {
            current[i].sortOrder = i
        }
        items = current
    }
    
    func toggleBookCompleted(bookID: UUID) {
        var current = items
        if let idx = current.firstIndex(where: { $0.bookID == bookID }) {
            current[idx].isCompleted.toggle()
        }
        items = current
    }
    
    func moveBook(from source: Int, to destination: Int) {
        var current = items
        guard current.indices.contains(source) else { return }

        let item = current.remove(at: source)
        let safeDestination = min(max(destination, 0), current.count)
        current.insert(item, at: safeDestination)

        for i in current.indices {
            current[i].sortOrder = i
        }

        items = current
    }
}
