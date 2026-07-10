//
//  ReadingHomeView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ReadingHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var appState: AppState
    
    @State private var showingSignInSheet = false

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @Query
    private var stats: [ReadingStats]

    @Query(sort: \ReadingGoals.updatedAt, order: .reverse)
    private var goals: [ReadingGoals]

    @Query(sort: \ReadingSession.date, order: .reverse)
    private var sessions: [ReadingSession]

    @Query
    private var authUsers: [AuthUser]

    @Query
    private var allNotes: [BookNote]

    @Query
    private var allQuotes: [BookQuote]

    @Query
    private var allReviews: [BookReview]

    private var readingStats: ReadingStats? {
        stats.first
    }

    private var savedAuthUser: AuthUser? {
        authUsers.first
    }

    private var isSignedIn: Bool {
        appState.currentUser != nil || savedAuthUser != nil
    }

    private var activeReadingGoals: [ReadingGoals] {
        goals.filter { $0.status == .active && !$0.isArchived }
    }

    private var currentlyReadingBooks: [Book] {
        books.filter { $0.status == .reading && !$0.isArchived }
    }

    private var activeBooks: [Book] {
        books.filter { !$0.isArchived }
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let readingDays = Set(
            sessions.map {
                calendar.startOfDay(for: $0.date)
            }
        )

        guard !readingDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        let anchorDay: Date

        if readingDays.contains(today) {
            anchorDay = today
        } else if readingDays.contains(yesterday) {
            anchorDay = yesterday
        } else {
            return 0
        }

        var streak = 0
        var day = anchorDay

        while readingDays.contains(day) {
            streak += 1

            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else {
                break
            }

            day = previousDay
        }

        return streak
    }

    private var bestStreak: Int {
        let calendar = Calendar.current
        let sortedDays = Array(
            Set(
                sessions.map {
                    calendar.startOfDay(for: $0.date)
                }
            )
        )
        .sorted()

        guard !sortedDays.isEmpty else { return 0 }

        var best = 1
        var current = 1

        for index in 1..<sortedDays.count {
            let previous = sortedDays[index - 1]
            let currentDay = sortedDays[index]

            if calendar.isDate(
                currentDay,
                inSameDayAs: calendar.date(byAdding: .day, value: 1, to: previous) ?? previous
            ) {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }

        return best
    }

    private var todaysSessions: [ReadingSession] {
        sessions.filter {
            Calendar.current.isDateInToday($0.date)
        }
    }

    private var pagesReadToday: Int {
        todaysSessions.reduce(0) { $0 + $1.pagesRead }
    }

    private var minutesReadToday: Int {
        todaysSessions.reduce(0) { $0 + $1.durationMinutes }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        currentlyReadingSection
                        libraryPulseSection
                        writingStatsSection
                        readingMomentumSection
                        goalsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 90)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                ensureReadingModelsExist()

                restoreSavedUserIfNeeded()
                showingSignInSheet = !isSignedIn
            }
            .adaptivePresentation(isPresented: $showingSignInSheet, useFullScreenCover: horizontalSizeClass == .regular) {
                SignInView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
                    .preferredColorScheme(.dark)
            }
            .onChange(of: authUsers.count) { _, _ in
                restoreSavedUserIfNeeded()
                if isSignedIn {
                    showingSignInSheet = false
                }
            }
        }
    }
}

// MARK: - Header

private extension ReadingHomeView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Lumey")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                if !isSignedIn {
                    Button {
                        showingSignInSheet = true
                    } label: {
                        Text("Sign In")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(LGradients.header)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Your cozy reading space")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Currently Reading

private extension ReadingHomeView {
    var currentlyReadingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Currently Reading")

            if currentlyReadingBooks.isEmpty {
                emptyCard(
                    title: "No active books yet",
                    message: "Add a book and mark it as Reading to see it here."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(currentlyReadingBooks.prefix(3)) { book in
                        HomeCurrentReadingCard(book: book)
                    }
                }
            }
        }
    }
}

// MARK: - Library Pulse

private extension ReadingHomeView {
    var libraryPulseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Library Pulse")

            GlassCard {
                HStack(spacing: 16) {
                    VStack(spacing: 12) {
                        frostedStatBox(
                            value: "\(activeBooks.count)",
                            label: "Total Books"
                        )

                        frostedStatBox(
                            value: "\(currentlyReadingBooks.count)",
                            label: "Currently Reading"
                        )
                    }

                    Spacer()

                    DottedProgressRing(
                        progress: activeBooks.isEmpty ? 0 : Double(currentlyReadingBooks.count) / Double(activeBooks.count),
                        size: 120,
                        dotCount: 24,
                        dotSize: 6
                    )
                }
            }
        }
    }

    func frostedStatBox(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(LGradients.header)

            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - Writing Stats

private extension ReadingHomeView {
    var writingStatsSection: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Your Writing")

            LazyVGrid(columns: columns, spacing: 12) {
                writingStatCard(icon: "lovedocument", title: "Notes", count: allNotes.count)
                writingStatCard(icon: "starmark", title: "Quotes", count: allQuotes.count)
                writingStatCard(icon: "starcircle", title: "Reviews", count: allReviews.count)
            }
        }
    }

    func writingStatCard(icon: String, title: String, count: Int) -> some View {
        GlassCard(cornerRadius: 18, padding: 14) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    LColors.gradientBlue.opacity(0.18),
                                    LColors.gradientPurple.opacity(0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(LGradients.blue, lineWidth: 1)
                        )
                        .frame(width: 40, height: 40)

                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(LGradients.blue)
                }

                Text("\(count)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(LGradients.header)

                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Reading Momentum

private extension ReadingHomeView {
    var readingMomentumSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Reading Momentum")

            GlassCard {
                VStack(spacing: 16) {
                    // Streak row
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image("flame")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                                    .foregroundStyle(LGradients.header)

                                Text("\(currentStreak)")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .foregroundStyle(LGradients.header)
                            }

                            Text("day streak")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(bestStreak)")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(.white)

                            Text("best streak")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                    }

                    // 7-day activity strip
                    weekActivityStrip

                    // Today's stats pills
                    HStack(spacing: 10) {
                        todayPill(
                            icon: "openbook",
                            value: "\(pagesReadToday)",
                            label: "pages today"
                        )

                        todayPill(
                            icon: "clockfill",
                            value: "\(minutesReadToday)",
                            label: "min today"
                        )
                    }
                }
            }
        }
    }

    var weekActivityStrip: some View {
        let calendar = Calendar.current
        let today = Date()
        let weekdaySymbols = ["M", "T", "W", "T", "F", "S", "S"]

        // Build last 7 days
        let days: [(label: String, isActive: Bool)] = (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let weekdayIndex = (calendar.component(.weekday, from: date) + 5) % 7 // Mon=0
            let label = weekdaySymbols[weekdayIndex]

            let isActive = sessions.contains { session in
                calendar.isDate(session.date, inSameDayAs: date)
            }

            return (label, isActive)
        }

        return HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 6) {
                    Text(day.label)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    Circle()
                        .fill(
                            day.isActive
                            ? AnyShapeStyle(LGradients.blue)
                            : AnyShapeStyle(Color.white.opacity(0.08))
                        )
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    day.isActive
                                    ? AnyShapeStyle(Color.clear)
                                    : AnyShapeStyle(Color.white.opacity(0.12)),
                                    lineWidth: 1
                                )
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    func todayPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(LGradients.blue)

            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - Goals

private extension ReadingHomeView {
    var goalsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Reading Goals")

            if activeReadingGoals.isEmpty {
                emptyCard(
                    title: "No reading goals yet",
                    message: "Create a reading goal to track your progress here."
                )
            } else {
                GlassCard {
                    VStack(spacing: 0) {
                        ForEach(Array(activeReadingGoals.prefix(3).enumerated()), id: \.element.id) { index, goal in
                            if index > 0 {
                                Rectangle()
                                    .fill(LColors.glassBorder)
                                    .frame(height: 1)
                                    .padding(.vertical, 10)
                            }

                            CompactGoalRow(goal: goal)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Helpers

private extension ReadingHomeView {
    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(.white)
    }

    func emptyCard(title: String, message: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func ensureReadingModelsExist() {
        if stats.isEmpty {
            modelContext.insert(ReadingStats())
        }

        if goals.isEmpty {
            modelContext.insert(ReadingGoals())
        }
    }

    func restoreSavedUserIfNeeded() {
        guard appState.currentUser == nil,
              let savedAuthUser
        else { return }

        appState.setSignedIn(savedAuthUser)
    }
}

// MARK: - Dotted Progress Ring

struct DottedProgressRing: View {
    let progress: Double
    let size: CGFloat
    let dotCount: Int
    let dotSize: CGFloat

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var filledDots: Int {
        Int((clampedProgress * Double(dotCount)).rounded())
    }

    var body: some View {
        ZStack {
            ForEach(0..<dotCount, id: \.self) { index in
                let angle = (Double(index) / Double(dotCount)) * 360 - 90
                let radians = angle * .pi / 180
                let isFilled = index < filledDots
                let radius = (size - dotSize) / 2

                Circle()
                    .fill(
                        isFilled
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [LColors.gradientBlue, LColors.gradientPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        : AnyShapeStyle(Color.white.opacity(0.10))
                    )
                    .frame(width: dotSize, height: dotSize)
                    .offset(
                        x: cos(radians) * radius,
                        y: sin(radians) * radius
                    )
            }

            Text("\(Int(clampedProgress * 100))%")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(LGradients.header)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Dotted Progress Bar

struct DottedProgressBar: View {
    let value: Double
    let dotCount: Int
    let dotSize: CGFloat

    private var clampedValue: Double {
        min(max(value, 0), 1)
    }

    private var filledDots: Int {
        Int((clampedValue * Double(dotCount)).rounded())
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(
                        index < filledDots
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [LColors.gradientBlue, LColors.gradientPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        : AnyShapeStyle(Color.white.opacity(0.10))
                    )
                    .frame(width: dotSize, height: dotSize)
            }
        }
    }
}

// MARK: - Home Current Reading Card

struct HomeCurrentReadingCard: View {
    let book: Book

    private var lastReadLabel: String {
        let date = book.lastUpdated
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Read today"
        } else if calendar.isDateInYesterday(date) {
            return "Read yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            return days <= 30 ? "\(days)d ago" : date.formatted(date: .abbreviated, time: .omitted)
        }
    }

    private var percentText: String {
        "\(Int(book.calculatedProgress * 100))%"
    }

    private var pagesLeftText: String {
        if book.totalPages > 0 {
            let left = max(book.totalPages - book.currentPage, 0)
            return "\(left) pages left"
        } else if book.totalChapters > 0 {
            let left = max(book.totalChapters - book.currentChapter, 0)
            return "\(left) chapters left"
        } else {
            return "\(Int(100 - book.progressPercent))% remaining"
        }
    }

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Image("openbook")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                Circle()
                                    .strokeBorder(LGradients.header, lineWidth: 1)
                            )
                    )

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(book.displayTitle)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text(book.displayAuthor)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 7) {
                        DottedProgressBar(value: book.calculatedProgress, dotCount: 12, dotSize: 6)

                        Text(percentText)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                    }
                    .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(book.progressText)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text(lastReadLabel)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Compact Goal Row

struct CompactGoalRow: View {
    let goal: ReadingGoals

    private var isCompletedToday: Bool {
        guard let date = goal.lastCompletedDate else { return false }
        return Calendar.current.isDateInToday(date) && goal.progressValue >= 1
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(goal.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(LGradients.header)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.06))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(goal.displayTitle)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if isCompletedToday {
                    HStack(spacing: 5) {
                        Image("checkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(LGradients.header)

                        Text("Done today")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                } else {
                    DottedProgressBar(value: goal.progressValue, dotCount: 12, dotSize: 5)
                }
            }

            Spacer(minLength: 0)

            if goal.type == .streak && goal.currentStreak > 0 {
                HStack(spacing: 3) {
                    Image("flame")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(LGradients.header)

                    Text("\(goal.currentStreak)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                }
            } else {
                Text("\(goal.progressPercentage)%")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LGradients.header)
            }
        }
    }
}

// MARK: - Book Cover Thumbnail

struct BookCoverThumbnail: View {
    let book: Book
    var width: CGFloat = 58
    var height: CGFloat = 84

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            LColors.gradientBlue.opacity(0.55),
                            LColors.gradientPurple.opacity(0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let data = book.coverImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Text(book.displayTitle.prefix(1).uppercased())
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
        )
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Text(value)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LGradients.header)

                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Recent Book Row

struct RecentBookRow: View {
    let book: Book

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                BookCoverThumbnail(book: book, width: 46, height: 66)

                VStack(alignment: .leading, spacing: 5) {
                    Text(book.displayTitle)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(book.displayAuthor)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(1)

                    Text(book.status.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(LGradients.header)
                }

                Spacer()

                if book.rating > 0 {
                    Text(String(format: "%.1f", book.rating))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(LColors.glassSurface2, in: Capsule())
                }
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func adaptivePresentation<Content: View>(
        isPresented: Binding<Bool>,
        useFullScreenCover: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if useFullScreenCover {
            self.fullScreenCover(isPresented: isPresented, content: content)
        } else {
            self.sheet(isPresented: isPresented, content: content)
        }
    }
}

// MARK: - Preview

#Preview {
    ReadingHomeView()
        .modelContainer(for: [
            Book.self,
            BookNote.self,
            BookQuote.self,
            BookReview.self,
            ReadingStats.self,
            ReadingGoals.self,
            ReadingSession.self
        ], inMemory: true)
}
