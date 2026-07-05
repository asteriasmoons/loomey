//
//  ReadingLibraryView.swift
//  Lumey
//

import SwiftUI
import SwiftData


private struct BookSheetMode: Identifiable {
    let id = UUID()
    let book: Book?
}

struct ReadingLibraryView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @Query
    private var librarySettings: [ReadingLibrarySettings]

    @State private var searchText = ""
    @State private var selectedStatus: BookStatus? = nil
    @State private var selectedSeries: String? = nil
    @State private var isSeriesFilterExpanded = false
    @State private var activeBookSheet: BookSheetMode? = nil
    @State private var showRecommendationsSheet = false
    @State private var showBookSearchSheet = false
    @State private var hasAppeared = false

    private var visibleBooks: [Book] {
        books
            .filter { !$0.isArchived }
            .filter { book in
                guard let selectedStatus else { return true }
                return book.status == selectedStatus
            }
            .filter { book in
                guard let selectedSeries else { return true }
                return book.seriesName == selectedSeries
            }
            .filter { book in
                let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedSearch.isEmpty else { return true }

                return book.displayTitle.localizedCaseInsensitiveContains(trimmedSearch)
                || book.displayAuthor.localizedCaseInsensitiveContains(trimmedSearch)
                || book.seriesName.localizedCaseInsensitiveContains(trimmedSearch)
                || book.genres.contains { $0.localizedCaseInsensitiveContains(trimmedSearch) }
                || book.moods.contains { $0.localizedCaseInsensitiveContains(trimmedSearch) }
                || book.tags.contains { $0.localizedCaseInsensitiveContains(trimmedSearch) }
                || book.tropes.contains { $0.localizedCaseInsensitiveContains(trimmedSearch) }
            }
    }

    private var activeBooksCount: Int {
        books.filter { !$0.isArchived }.count
    }

    private var readingCount: Int {
        books.filter { $0.status == .reading && !$0.isArchived }.count
    }

    private var finishedCount: Int {
        books.filter { $0.status == .finished && !$0.isArchived }.count
    }

    private var tbrCount: Int {
        books.filter { $0.status == .toBeRead && !$0.isArchived }.count
    }

    private var defaultStatus: BookStatus? {
        librarySettings.first?.defaultStatusFilter
    }

    private var availableSeries: [String] {
        Array(
            Set(
                books
                    .filter { !$0.isArchived }
                    .map { $0.seriesName.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        searchBar
                        recommendationButtonSection
                        statusFilter
                        readingListsButton
                        seriesFilter
                        libraryOverview
                        bookListSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 140)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeBookSheet) { sheetMode in
                AddEditBookSheet(book: sheetMode.book) { savedBook in
                    if sheetMode.book == nil {
                        modelContext.insert(savedBook)
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showRecommendationsSheet) {
                BookRecommendationsSheet()
            }
            .sheet(isPresented: $showBookSearchSheet) {
                BookSearchSheet()
            }
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                selectedStatus = defaultStatus
            }
        }
    }
}

// MARK: - Header

private extension ReadingLibraryView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Library")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                addBookButton
            }

            Text("Browse, search, and organize your books")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var addBookButton: some View {
        Button {
            activeBookSheet = BookSheetMode(book: nil)
        } label: {
            Image("addwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(
                    LinearGradient(
                        colors: [LColors.gradientBlue, LColors.gradientPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 46, height: 46)
                .background(
                    Circle()
                        .fill(LColors.bg)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [LColors.gradientBlue, LColors.gradientPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.35
                                )
                        )
                        .shadow(color: LColors.gradientBlue.opacity(0.20), radius: 14, y: 7)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search

private extension ReadingLibraryView {
    var searchBar: some View {
        HStack(spacing: 10) {
            Image("searchwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(LColors.textSecondary)

            TextField("Search books, authors, series, tags...", text: $searchText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .tint(LColors.accent)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image("xmarkwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(LColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            LColors.gradientBlue.opacity(0.08),
                            LColors.gradientPurple.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            LColors.gradientBlue.opacity(0.65),
                            LColors.gradientPurple.opacity(0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Reading Lists Button

private extension ReadingLibraryView {
    var readingListsButton: some View {
        NavigationLink {
            ReadingListsPage()
        } label: {
            HStack(spacing: 10) {
                Image("openbook")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.black)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Reading Lists")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.black)

                    Text("Curated collections and TBR plans")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.75))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LGradients.header)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Filter

private extension ReadingLibraryView {
    var recommendationButtonSection: some View {
        HStack(spacing: 12) {
            libraryActionButton(
                title: "Recommend",
                iconName: "sparkle"
            ) {
                showRecommendationsSheet = true
            }

            libraryActionButton(
                title: "Look Up",
                iconName: "searchwavy"
            ) {
                showBookSearchSheet = true
            }
        }
    }

    func libraryActionButton(
        title: String,
        iconName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)

                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, minHeight: 46, alignment: .center)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [LColors.gradientBlue, LColors.gradientPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    var statusFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                statusFilterChip(title: "All", status: nil)

                ForEach(BookStatus.allCases) { status in
                    statusFilterChip(title: status.rawValue, status: status)
                }
            }
            .padding(.vertical, 2)
        }
    }

    var seriesFilter: some View {
        Group {
            if !availableSeries.isEmpty {
                LibrarySeriesFilterDropdown(
                    availableSeries: availableSeries,
                    selectedSeries: $selectedSeries,
                    isExpanded: $isSeriesFilterExpanded
                )
            }
        }
    }

    func setDefaultStatusFilter(_ status: BookStatus?) {
        let rawValue = status?.rawValue ?? "All"

        if let settings = librarySettings.first {
            settings.defaultStatusFilterRawValue = rawValue
        } else {
            let settings = ReadingLibrarySettings(defaultStatusFilterRawValue: rawValue)
            modelContext.insert(settings)
        }

        if librarySettings.count > 1 {
            for i in 1..<librarySettings.count {
                modelContext.delete(librarySettings[i])
            }
        }

        try? modelContext.save()

        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            selectedStatus = status
        }
    }

    func isDefaultStatusFilter(_ status: BookStatus?) -> Bool {
        defaultStatus == status
    }

    func statusFilterChip(title: String, status: BookStatus?) -> some View {
        let isSelected = selectedStatus == status

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                selectedStatus = status
            }
        } label: {
            HStack(spacing: 6) {
                if isDefaultStatusFilter(status) {
                    Image("starfill")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                }

                Text(title)
            }
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(isSelected ? .white : LColors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [
                                LColors.gradientBlue.opacity(0.36),
                                LColors.gradientPurple.opacity(0.36)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isSelected
                            ? [LColors.gradientBlue, LColors.gradientPurple]
                            : [Color.white.opacity(0.14), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                setDefaultStatusFilter(status)
            } label: {
                Label {
                    Text("Set as Default")
                } icon: {
                    Image("starfill")
                }
            }
        }
    }


}

// MARK: - Overview

private extension ReadingLibraryView {
    var libraryOverview: some View {
        HStack(spacing: 12) {
            LibraryMiniStatCard(title: "Total", value: "\(activeBooksCount)")
            LibraryMiniStatCard(title: "Reading", value: "\(readingCount)")
            LibraryMiniStatCard(title: "TBR", value: "\(tbrCount)")
            LibraryMiniStatCard(title: "Finished", value: "\(finishedCount)")
        }
    }
}

// MARK: - Book List

private extension ReadingLibraryView {
    var bookListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Books")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(visibleBooks.count)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LColors.glassSurface2)
                    )
            }

            if visibleBooks.isEmpty {
                emptyLibraryCard
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(visibleBooks) { book in
                        LibraryBookRow(book: book) {
                            activeBookSheet = BookSheetMode(book: book)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteBook(book)
                            } label: {
                                Label {
                                    Text("Delete Book")
                                } icon: {
                                    Image("trash")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    var emptyLibraryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("No books found")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(searchText.isEmpty ? "Your saved books will appear here." : "Try a different search or filter.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func deleteBook(_ book: Book) {
        modelContext.delete(book)
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    ReadingLibraryView()
}

struct LibrarySeriesFilterDropdown: View {
    let availableSeries: [String]
    @Binding var selectedSeries: String?
    @Binding var isExpanded: Bool
    
    private var selectedTitle: String {
        selectedSeries ?? "All Series"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Series")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
                .padding(.horizontal, 2)
            
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image("books")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(LGradients.header)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(LGradients.header, lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Filter Library")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                        
                        Text(selectedTitle)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Text("\(availableSeries.count)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                    
                    Image(isExpanded ? "chevup" : "chevdown")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(LGradients.header)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(dropdownBackground)
                .overlay(dropdownBorder)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    dropdownOption(title: "All Series", seriesName: nil)
                    
                    ForEach(availableSeries, id: \.self) { series in
                        dropdownOption(title: series, seriesName: series)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    LColors.gradientBlue.opacity(0.08),
                                    LColors.gradientPurple.opacity(0.08),
                                    Color.white.opacity(0.035)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    LColors.gradientBlue.opacity(0.55),
                                    LColors.gradientPurple.opacity(0.55),
                                    Color.white.opacity(0.16)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private var dropdownBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        LColors.gradientBlue.opacity(0.10),
                        LColors.gradientPurple.opacity(0.13),
                        Color.white.opacity(0.035)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    private var dropdownBorder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        LColors.gradientBlue.opacity(0.72),
                        LColors.gradientPurple.opacity(0.72),
                        Color.white.opacity(0.22)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    private func dropdownOption(title: String, seriesName: String?) -> some View {
        let isSelected = selectedSeries == seriesName
        
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                selectedSeries = seriesName
                isExpanded = false
            }
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(isSelected ? LGradients.header : LinearGradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.07)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.22) : Color.clear)
                            .frame(width: 4, height: 4)
                    )
                
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? .white : LColors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 0)
                
                if isSelected {
                    Image("checkwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(LGradients.header)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.065) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
