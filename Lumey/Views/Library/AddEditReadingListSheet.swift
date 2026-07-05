//
//  AddEditReadingListSheet.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct AddEditReadingListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let list: ReadingList?
    
    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var allBooks: [Book]
    
    @State private var title = ""
    @State private var listDescription = ""
    @State private var iconName = "books"
    @State private var status: ReadingListStatus = .active
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var selectedBookIDs: [UUID] = []
    
    @State private var showingIconPicker = false
    
    private var isEditing: Bool { list != nil }
    
    private var availableBooks: [Book] {
        allBooks.filter { !$0.isArchived }
    }
    
    private var availableSeries: [String] {
        let names = Set(allBooks.compactMap { book in
            let trimmed = book.seriesName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        })
        return names.sorted()
    }
    
    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                sheetHeader
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionCard(title: "List Details") {
                            LumeyTextField(title: "Title", text: $title)
                            LumeyTextEditor(title: "Description", text: $listDescription, minHeight: 80)
                        }
                        
                        sectionCard(title: "Display") {
                            GoalIconPickerRow(iconName: $iconName) {
                                showingIconPicker = true
                            }
                            
                            LumeyEnumPicker(title: "Status", selection: $status, options: ReadingListStatus.allCases)
                        }
                        
                        sectionCard(title: "Due Date") {
                            Toggle("Use Due Date", isOn: $hasDueDate)
                                .tint(LColors.accent)
                            
                            if hasDueDate {
                                DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                                    .tint(LColors.accent)
                            }
                        }
                        
                        booksSection
                        
                        seriesQuickAddSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 38)
                }
            }
        }
        .task(id: list?.id) { loadList() }
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: $iconName)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }
    
    // MARK: - Header
    
    private var sheetHeader: some View {
        HStack(spacing: 12) {
            Text(isEditing ? "Edit List" : "New List")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            
            Spacer()
            
            Button { saveList() } label: {
                Text("Save")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Capsule(style: .continuous).fill(LGradients.header))
            }
            .buttonStyle(.plain)
            
            Button { dismiss() } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(LColors.glassSurface2))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
        }
        .safeAreaPadding(.top)
    }
    
    // MARK: - Books Section
    
    private var booksSection: some View {
        sectionCard(title: "Books") {
            if !selectedBookIDs.isEmpty {
                VStack(spacing: 8) {
                    ForEach(selectedBookIDs, id: \.self) { bookID in
                        if let book = availableBooks.first(where: { $0.id == bookID }) {
                            HStack(spacing: 10) {
                                Image("books")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                    .foregroundStyle(LGradients.header)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(book.title)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    
                                    Text(book.author)
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button {
                                    selectedBookIDs.removeAll { $0 == bookID }
                                } label: {
                                    Image("xmarkwavy")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 12, height: 12)
                                        .foregroundStyle(LColors.textSecondary)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color.white.opacity(0.06)))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            
            let unlinked = availableBooks.filter { !selectedBookIDs.contains($0.id) }
            
            if !unlinked.isEmpty {
                Menu {
                    ForEach(unlinked) { book in
                        Button {
                            selectedBookIDs.append(book.id)
                        } label: {
                            Text("\(book.title) — \(book.author)")
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                            .foregroundStyle(LGradients.header)
                        
                        Text("Add a Book")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Image("chevdown")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(LColors.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LColors.glassSurface2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Series Quick Add
    
    @ViewBuilder
    private var seriesQuickAddSection: some View {
        if !availableSeries.isEmpty {
            sectionCard(title: "Add Entire Series") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableSeries, id: \.self) { seriesName in
                            Button {
                                addSeriesBooks(seriesName)
                            } label: {
                                Text(seriesName)
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule().fill(LColors.glassSurface2)
                                    )
                                    .overlay(
                                        Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    // MARK: - Section Card
    
    private func sectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                Text(title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                
                VStack(spacing: 12) {
                    content()
                }
            }
        }
    }
    
    // MARK: - Load / Save
    
    private func loadList() {
        guard let list else { return }
        title = list.title
        listDescription = list.listDescription
        iconName = list.iconName
        status = list.status
        
        if let due = list.dueDate {
            dueDate = due
            hasDueDate = true
        }
        
        selectedBookIDs = list.items.map { $0.bookID }
    }
    
    private func saveList() {
        let target = list ?? ReadingList()
        let wasNew = list == nil
        
        target.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        target.listDescription = listDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        target.iconName = iconName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "books" : iconName
        target.status = status
        target.dueDate = hasDueDate ? dueDate : nil
        
        // Preserve existing item state (completion, order) for books that remain
        let existingItems = target.items
        var newItems: [ReadingListItemData] = []
        
        for (index, bookID) in selectedBookIDs.enumerated() {
            if let existing = existingItems.first(where: { $0.bookID == bookID }) {
                var updated = existing
                updated.sortOrder = index
                newItems.append(updated)
            } else {
                newItems.append(ReadingListItemData(
                    bookID: bookID,
                    sortOrder: index,
                    dateAdded: Date()
                ))
            }
        }
        
        target.items = newItems
        target.updatedAt = Date()
        
        if wasNew {
            modelContext.insert(target)
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    private func addSeriesBooks(_ seriesName: String) {
        let seriesBooks = availableBooks.filter {
            $0.seriesName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == seriesName.lowercased()
        }
        
        for book in seriesBooks {
            if !selectedBookIDs.contains(book.id) {
                selectedBookIDs.append(book.id)
            }
        }
    }
}
