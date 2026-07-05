//
//  ReadingStatsView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ReadingStatsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ReadingSession.date, order: .reverse)
    private var sessions: [ReadingSession]

    @Query
    private var statsRecords: [ReadingStats]

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @Query
    private var allNotes: [BookNote]

    @Query
    private var allQuotes: [BookQuote]

    @Query
    private var allReviews: [BookReview]

    private var stats: ReadingStats? { statsRecords.first }

    // MARK: - Derived aggregates

    private var totalPoints: Int {
        sessions.reduce(0) { $0 + $1.pointsEarned }
    }

    private var totalMinutes: Int {
        sessions.reduce(0) { $0 + $1.durationMinutes }
    }

    private var totalPages: Int {
        sessions.reduce(0) { $0 + $1.pagesRead }
    }

    private var totalSessions: Int {
        sessions.count
    }
    
    private var totalBooksFinished: Int {
        books.filter {
            !$0.isArchived &&
            (
                $0.status == .finished ||
                $0.dateFinished != nil
            )
        }.count
    }

    private var averageSessionMinutes: Int {
        guard totalSessions > 0 else { return 0 }
        return totalMinutes / totalSessions
    }

    private var longestSession: ReadingSession? {
        sessions.max(by: { $0.durationMinutes < $1.durationMinutes })
    }

    private var recentSessions: [ReadingSession] {
        Array(sessions.prefix(20))
    }

    private var heatmapDays: [ReadingHeatmapDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sessionsByDay = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.date)
        }

        return (0..<84).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let daySessions = sessionsByDay[date] ?? []
            let pages = daySessions.reduce(0) { $0 + $1.pagesRead }
            let minutes = daySessions.reduce(0) { $0 + $1.durationMinutes }

            return ReadingHeatmapDay(
                date: date,
                sessions: daySessions.count,
                pages: pages,
                minutes: minutes
            )
        }
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

    private var readingMilestones: [ReadingMilestone] {
        [
            ReadingMilestone(
                title: "First Book Finished",
                subtitle: "Finish your first book in Lumey.",
                isUnlocked: totalBooksFinished >= 1
            ),
            ReadingMilestone(
                title: "First Review Written",
                subtitle: "Write your first book review.",
                isUnlocked: !allReviews.isEmpty
            ),
            ReadingMilestone(
                title: "100 Pages Read",
                subtitle: "Read 100 tracked pages.",
                isUnlocked: totalPages >= 100
            ),
            ReadingMilestone(
                title: "1,000 Pages Read",
                subtitle: "Read 1,000 tracked pages.",
                isUnlocked: totalPages >= 1_000
            ),
            ReadingMilestone(
                title: "10 Books Finished",
                subtitle: "Finish 10 books total.",
                isUnlocked: totalBooksFinished >= 10
            )
        ]
    }

    private var activeBooks: [Book] {
        books.filter { !$0.isArchived }
    }

    private var mostReadAuthor: String {
        mostCommonValue(
            activeBooks
                .map { $0.displayAuthor.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
    }

    private var favoriteGenre: String {
        mostCommonValue(activeBooks.flatMap { $0.genres })
    }

    private var favoriteMood: String {
        mostCommonValue(activeBooks.flatMap { $0.moods })
    }

    private var favoriteTrope: String {
        mostCommonValue(activeBooks.flatMap { $0.tropes })
    }

    private var mostCommonTag: String {
        mostCommonValue(activeBooks.flatMap { $0.tags })
    }

    private func mostCommonValue(_ values: [String]) -> String {
        let cleanedValues = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanedValues.isEmpty else { return "Not enough data yet" }

        let grouped = Dictionary(grouping: cleanedValues) { $0.lowercased() }

        let bestGroup = grouped.max { lhs, rhs in
            if lhs.value.count == rhs.value.count {
                return lhs.value.first ?? lhs.key > rhs.value.first ?? rhs.key
            }
            return lhs.value.count < rhs.value.count
        }

        return bestGroup?.value.first ?? "Not enough data yet"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        personalityCard

                        pointsHeroCard

                        readingMilestonesSection

                        favoriteThingsSection

                        readingHeatmapSection

                        streakSection

                        recentSessionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 140)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct ReadingMilestone: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let isUnlocked: Bool
}

struct ReadingHeatmapDay: Identifiable {
    let id = UUID()
    let date: Date
    let sessions: Int
    let pages: Int
    let minutes: Int

    var intensity: Int {
        if pages >= 75 || minutes >= 90 { return 4 }
        if pages >= 40 || minutes >= 45 { return 3 }
        if pages >= 15 || minutes >= 20 { return 2 }
        if sessions > 0 { return 1 }
        return 0
    }
}

// MARK: - Header

private extension ReadingStatsView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stats")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Your reading sessions, points, and momentum at a glance.")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Reading Personality

enum ReadingPersonality: String {
    case fantasyExplorer = "Fantasy Explorer"
    case nightReader = "Night Reader"
    case quoteCollector = "Quote Collector"
    case reviewWriter = "Review Writer"
    case seriesBinger = "Series Binger"
    case moodReader = "Mood Reader"
    case steadyReader = "Steady Reader"

    var description: String {
        switch self {
        case .fantasyExplorer:
            return "You keep reaching for magic, danger, romance, and impossible worlds."
        case .nightReader:
            return "Your reading rhythm comes alive later in the day."
        case .quoteCollector:
            return "You notice lines worth keeping and build meaning through saved passages."
        case .reviewWriter:
            return "You turn finished books into opinions, reflections, and reader insight."
        case .seriesBinger:
            return "You like staying inside one world long enough to watch it unfold."
        case .moodReader:
            return "You seem drawn to books by atmosphere, emotion, and feeling."
        case .steadyReader:
            return "You\u{2019}re building a consistent reading life one session at a time."
        }
    }

    var iconName: String {
        switch self {
        case .fantasyExplorer: return "sparkle"
        case .nightReader:    return "moonzs"
        case .quoteCollector: return "starmark"
        case .reviewWriter:   return "starcircle"
        case .seriesBinger:   return "bookstack"
        case .moodReader:     return "xsmile"
        case .steadyReader:   return "achievement"
        }
    }

    static func calculate(
        books: [Book],
        sessions: [ReadingSession],
        quotes: [BookQuote],
        reviews: [BookReview]
    ) -> ReadingPersonality {
        let activeBooks = books.filter { !$0.isArchived }

        // Quote collector
        if quotes.count >= 10 {
            return .quoteCollector
        }

        // Review writer
        if reviews.count >= 5 {
            return .reviewWriter
        }

        // Night reader
        let nightSessions = sessions.filter {
            Calendar.current.component(.hour, from: $0.date) >= 20
        }.count
        if nightSessions >= 5 {
            return .nightReader
        }

        // Series binger
        let seriesCounts = Dictionary(
            grouping: activeBooks.filter { !$0.seriesName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            by: { $0.seriesName }
        )
        let maxSeriesCount = seriesCounts.values.map(\.count).max() ?? 0
        if maxSeriesCount >= 3 {
            return .seriesBinger
        }

        // Fantasy explorer
        let fantasyCount = activeBooks.filter {
            $0.genres.contains { $0.localizedCaseInsensitiveContains("fantasy") }
        }.count
        if fantasyCount >= max(2, activeBooks.count / 2) {
            return .fantasyExplorer
        }

        // Mood reader
        let totalMoods = activeBooks.reduce(0) { $0 + $1.moods.count }
        if totalMoods >= 8 {
            return .moodReader
        }

        return .steadyReader
    }
}

// MARK: - Personality Card

private extension ReadingStatsView {
    var personality: ReadingPersonality {
        ReadingPersonality.calculate(
            books: books,
            sessions: sessions,
            quotes: allQuotes,
            reviews: allReviews
        )
    }

    var personalityCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                Image(personality.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(LGradients.blue)
                    .frame(width: 56, height: 56)
                    .background(
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
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text("Reading Personality")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    Text(personality.rawValue)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)

                    Text(personality.description)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Points Hero

private extension ReadingStatsView {
    var pointsHeroCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    Image("levelup")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(LGradients.header)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(LGradients.header, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reading Points")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Your reading momentum, collected.")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                }

                Text("\(totalPoints)")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(LGradients.header)

                Text("total points")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                DottedDivider()

                HStack(spacing: 10) {
                    statCapsule(title: "Sessions", value: "\(totalSessions)")
                    statCapsule(title: "Minutes", value: "\(totalMinutes)")
                    statCapsule(title: "Pages", value: "\(totalPages)")
                }
            }
        }
    }

    func miniStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
    }

    func statCapsule(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}


// MARK: - Reading Milestones

private extension ReadingStatsView {
    var readingMilestonesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Reading Milestones")

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(readingMilestones) { milestone in
                        ReadingMilestoneRow(milestone: milestone)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct ReadingMilestoneRow: View {
    let milestone: ReadingMilestone

    var body: some View {
        HStack(spacing: 12) {
            Image("startrophy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(
                    milestone.isUnlocked
                    ? LGradients.header
                    : LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.white.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(
                            milestone.isUnlocked
                            ? Color.white.opacity(0.07)
                            : Color.white.opacity(0.035)
                        )
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            milestone.isUnlocked
                            ? LGradients.header
                            : LinearGradient(
                                colors: [Color.white.opacity(0.10), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(milestone.title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(milestone.isUnlocked ? .white : LColors.textSecondary)

                Text(milestone.subtitle)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary.opacity(milestone.isUnlocked ? 0.9 : 0.62))
            }

            Spacer(minLength: 0)

            Text(milestone.isUnlocked ? "Unlocked" : "Locked")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(milestone.isUnlocked ? .white : LColors.textSecondary.opacity(0.7))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            milestone.isUnlocked
                            ? LinearGradient(
                                colors: [
                                    LColors.gradientPurple.opacity(0.34),
                                    LColors.gradientBlue.opacity(0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        }
    }
}

// MARK: - Favorite Things

private extension ReadingStatsView {
    var favoriteThingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Favorite Things")

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    FavoriteThingRow(iconName: "openbook", title: "Most Read Author", value: mostReadAuthor)
                    FavoriteThingRow(iconName: "loveflame", title: "Favorite Genre", value: favoriteGenre)
                    FavoriteThingRow(iconName: "xsmile", title: "Favorite Mood", value: favoriteMood)
                    FavoriteThingRow(iconName: "starmark", title: "Favorite Trope", value: favoriteTrope)
                    FavoriteThingRow(iconName: "tagsparkle", title: "Most Common Tag", value: mostCommonTag)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct FavoriteThingRow: View {
    let iconName: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(LGradients.header)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    Circle()
                        .strokeBorder(LGradients.header, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Text(value)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
    }
}


// MARK: - Reading Heatmap

private extension ReadingStatsView {
    var readingHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Reading Heatmap")

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Last 12 weeks")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Tiny calendar of your reading days.")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }

                        Spacer(minLength: 0)

                        HStack(spacing: 4) {
                            Text("Less")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.textSecondary.opacity(0.75))

                            ForEach(0..<5, id: \.self) { intensity in
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(heatmapColor(for: intensity))
                                    .frame(width: 9, height: 9)
                            }

                            Text("More")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.textSecondary.opacity(0.75))
                        }
                    }

                    HStack(alignment: .top, spacing: 5) {
                        ForEach(0..<12, id: \.self) { week in
                            VStack(spacing: 5) {
                                ForEach(0..<7, id: \.self) { day in
                                    let index = (week * 7) + day
                                    if heatmapDays.indices.contains(index) {
                                        ReadingHeatmapCell(day: heatmapDays[index])
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    func heatmapColor(for intensity: Int) -> LinearGradient {
        switch intensity {
        case 4:
            return LinearGradient(
                colors: [LColors.gradientBlue, LColors.gradientPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 3:
            return LinearGradient(
                colors: [LColors.gradientPurple.opacity(0.86), LColors.gradientBlue.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 2:
            return LinearGradient(
                colors: [LColors.gradientPurple.opacity(0.52), LColors.gradientBlue.opacity(0.38)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 1:
            return LinearGradient(
                colors: [LColors.gradientPurple.opacity(0.26), LColors.gradientBlue.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color.white.opacity(0.055), Color.white.opacity(0.035)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct ReadingHeatmapCell: View {
    let day: ReadingHeatmapDay

    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(cellGradient)
            .frame(width: 17, height: 17)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color.white.opacity(day.intensity == 0 ? 0.045 : 0.12), lineWidth: 0.7)
            )
            .accessibilityLabel(accessibilityText)
    }

    private var cellGradient: LinearGradient {
        switch day.intensity {
        case 4:
            return LinearGradient(colors: [LColors.gradientBlue, LColors.gradientPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 3:
            return LinearGradient(colors: [LColors.gradientPurple.opacity(0.86), LColors.gradientBlue.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2:
            return LinearGradient(colors: [LColors.gradientPurple.opacity(0.52), LColors.gradientBlue.opacity(0.38)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1:
            return LinearGradient(colors: [LColors.gradientPurple.opacity(0.26), LColors.gradientBlue.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Color.white.opacity(0.055), Color.white.opacity(0.035)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var accessibilityText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: day.date)): \(day.sessions) sessions, \(day.pages) pages, \(day.minutes) minutes"
    }
}

struct DottedDivider: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<28, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 3, height: 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 2)
    }
}


private extension ReadingStatsView {
    var streakSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Streaks")

            HStack(spacing: 12) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                        Text("\(currentStreak)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                        Text("day streak")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Best")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                        Text("\(bestStreak)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)
                        Text("day streak")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Recent Sessions

private extension ReadingStatsView {
    var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("Recent Sessions")
                Spacer()
                Text("\(totalSessions)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(LColors.glassSurface2))
            }

            GlassCard {
                if recentSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No sessions yet")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Log a reading session from the Goals tab to start earning points.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(recentSessions.prefix(8).enumerated()), id: \.element.id) { index, session in
                            CompactReadingSessionRow(session: session)

                            if index < min(recentSessions.count, 8) - 1 {
                                DottedDivider()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Session Row

struct CompactReadingSessionRow: View {
    let session: ReadingSession

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("clockfill")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 17, height: 17)
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

            VStack(alignment: .leading, spacing: 7) {
                Text(session.linkedBookTitle.isEmpty ? "Reading Session" : session.linkedBookTitle)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 7) {
                    if session.durationMinutes > 0 {
                        ReadingGoalPill(text: "\(session.durationMinutes) min")
                    }
                    if session.pagesRead > 0 {
                        ReadingGoalPill(text: "\(session.pagesRead) pages")
                    }
                    ReadingGoalPill(text: "+\(session.pointsEarned) pts", usePurpleStyle: true)
                }

                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(2)
                }

                Text(formattedDate)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary.opacity(0.7))
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Helpers

private extension ReadingStatsView {
    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(.white)
    }
}

// MARK: - Preview

#Preview {
    ReadingStatsView()
}
