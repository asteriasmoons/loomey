//
//  ChallengesView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ChallengesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var appState: AppState

    @Query(sort: \ReadingChallenge.createdDate)
    private var allChallenges: [ReadingChallenge]

    @Query(sort: \ChallengeEntry.startDate, order: .reverse)
    private var allEntries: [ChallengeEntry]

    @Query(sort: \ChallengeSubmission.submittedDate, order: .reverse)
    private var allSubmissions: [ChallengeSubmission]

    @Query(sort: \ChallengeUserProfile.username)
    private var allProfiles: [ChallengeUserProfile]

    @State private var selectedCategory: ChallengeCategory?
    @State private var selectedChallenge: ReadingChallenge?
    @State private var searchText = ""
    @State private var showingProfile = false
    @State private var showingLeaderboard = false
    @State private var showingFeedRoute = false
    @State private var showingCreateFeedPost = false

    private var currentUserID: String {
        appState.currentAppleUserId ?? "local-user"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
                        headerSection

                        if let featured = featuredChallenge {
                            featuredSection(featured)
                        }

                        if !weeklyChallenges.isEmpty {
                            weeklySection
                        }

                        if !activeChallenges.isEmpty {
                            activeSection
                        }

                        categorySection

                        allChallengesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 140)
                }
            }
            .task {
                seedIfNeeded()
                backfillChallengeCycles()
                backfillSubmissionChallengeTitles()
            }
            .adaptivePresentation(item: $selectedChallenge, useFullScreenCover: horizontalSizeClass == .regular) { challenge in
                ChallengeDetailView(challenge: challenge)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .adaptivePresentation(isPresented: $showingProfile, useFullScreenCover: horizontalSizeClass == .regular) {
                ProfileView(
                    challengeProfile: currentChallengeProfile,
                    recentChallengeSubmissions: allSubmissions.filter {
                        $0.userID == currentChallengeProfile.userID
                    },
                    showsCloseButton: true
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            .adaptivePresentation(isPresented: $showingLeaderboard, useFullScreenCover: horizontalSizeClass == .regular) {
                ChallengeLeaderboardView(
                    challenge: nil,
                    submissions: allSubmissions,
                    profiles: allProfiles
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            .navigationDestination(isPresented: $showingFeedRoute) {
                ChallengesFeedView()
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    private var currentChallengeProfile: ChallengeUserProfile {
        if let existing = allProfiles.first(where: { $0.userID == currentUserID }) {
            return existing
        }

        let profile = ChallengeUserProfile(
            userID: currentUserID,
            username: "Reader",
            avatarName: nil,
            bio: nil,
            favoriteGenre: nil
        )

        modelContext.insert(profile)
        try? modelContext.save()

        return profile
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack(alignment: .top) {

            VStack(alignment: .leading, spacing: 6) {
                Text("Challenges")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Join reading events and earn points")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            Button {
                showingProfile = true
            } label: {
                UserAvatarView(
                    avatarURL: currentChallengeProfile.avatarURL,
                    avatarName: currentChallengeProfile.avatarName,
                    size: 42,
                    iconSize: 20
                )
                .background(
                    Circle()
                        .fill(LColors.bg)
                        .overlay(
                            Circle()
                                .strokeBorder(LGradients.header, lineWidth: 1.2)
                        )
                        .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 12, y: 6)
                )
            }
            .buttonStyle(.plain)

            Button {
                showingFeedRoute = true
            } label: {
                Image("socialchat")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(LGradients.header, lineWidth: 1.2)
                            )
                            .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 12, y: 6)
                    )
            }
            .buttonStyle(.plain)

            Button {
                showingLeaderboard = true
            } label: {
                Image("baraward")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(LGradients.header, lineWidth: 1.2)
                            )
                            .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 12, y: 6)
                    )
            }
            .buttonStyle(.plain)

        }
    }

    private func featuredSection(_ challenge: ReadingChallenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Featured Challenge")

            Button {
                selectedChallenge = challenge
            } label: {
                GlassCard {
                    HStack(spacing: 14) {
                        Image(challenge.iconName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundStyle(LGradients.header)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(challenge.title)
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)

                                featuredBadge
                            }

                            Text(challenge.challengeDescription)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .lineLimit(2)

                            HStack(spacing: 12) {
                                pointsBadge(challenge.points)
                                durationBadge(challenge.displayDuration)
                            }
                            .padding(.top, 4)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Weekly Challenges")

            ForEach(weeklyChallenges) { challenge in
                Button {
                    selectedChallenge = challenge
                } label: {
                    ChallengeCardView(
                        challenge: challenge,
                        entry: entryFor(challenge),
                        badgeType: .weekly
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Your Active Challenges")

            ForEach(activeChallenges) { entry in
                if let challenge = challenge(for: entry.challengeID) {
                    Button {
                        selectedChallenge = challenge
                    } label: {
                        ChallengeCardView(
                            challenge: challenge,
                            entry: entry,
                            badgeType: .active
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Categories")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ChallengeCategory.allCases) { category in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(category.iconName)
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)

                                Text(category.displayName)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(selectedCategory == category ? .white : LColors.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(selectedCategory == category ? AnyShapeStyle(LGradients.header) : AnyShapeStyle(LColors.glassSurface2))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .strokeBorder(
                                        selectedCategory == category
                                            ? AnyShapeStyle(Color.clear)
                                            : AnyShapeStyle(LColors.glassBorder),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var allChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let selectedCategory {
                categoryHeader(
                    category: selectedCategory,
                    count: filteredChallenges.count
                )

                challengeList(filteredChallenges)
            } else {
                ForEach(groupedChallenges, id: \.category.id) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        categoryHeader(
                            category: group.category,
                            count: group.challenges.count
                        )

                        challengeList(group.challenges)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var featuredChallenge: ReadingChallenge? {
        allChallenges.first(where: { $0.isFeatured })
    }

    private var weeklyChallenges: [ReadingChallenge] {
        allChallenges.filter { $0.isWeekly }
    }

    private var activeChallenges: [ChallengeEntry] {
        allEntries.filter { entry in
            guard entry.userID == currentUserID,
                  entry.isActive,
                  let challenge = challenge(for: entry.challengeID)
            else { return false }

            guard challenge.isRecurring else { return true }
            return entryIsInCurrentCycle(entry, challenge: challenge)
        }
    }

    private var filteredChallenges: [ReadingChallenge] {
        if let category = selectedCategory {
            return allChallenges.filter { $0.category == category }
        }
        return allChallenges
    }

    private var groupedChallenges: [(category: ChallengeCategory, challenges: [ReadingChallenge])] {
        ChallengeCategory.allCases.compactMap { category in
            let challenges = allChallenges
                .filter { $0.category == category }
                .sorted { lhs, rhs in
                    if lhs.isFeatured != rhs.isFeatured {
                        return lhs.isFeatured && !rhs.isFeatured
                    }

                    if lhs.isWeekly != rhs.isWeekly {
                        return lhs.isWeekly && !rhs.isWeekly
                    }

                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }

            guard !challenges.isEmpty else { return nil }
            return (category, challenges)
        }
    }

    private func entryFor(_ challenge: ReadingChallenge) -> ChallengeEntry? {
        let entries = allEntries.filter {
            $0.challengeID == challenge.id && $0.userID == currentUserID
        }

        guard challenge.isRecurring else {
            return entries.first
        }

        return entries.first {
            entryIsInCurrentCycle($0, challenge: challenge)
        }
    }

    private func challenge(for id: UUID) -> ReadingChallenge? {
        allChallenges.first(where: { $0.id == id })
    }

    private func seedIfNeeded() {
        let manager = ChallengeManager(modelContext: modelContext)
        manager.seedChallengesIfNeeded()
    }

    private func backfillChallengeCycles() {
        let manager = ChallengeManager(modelContext: modelContext)
        manager.backfillCycleMetadata()
    }

    private func backfillSubmissionChallengeTitles() {
        var didChange = false

        for submission in allSubmissions {
            guard let challenge = challenge(for: submission.challengeID) else { continue }
            let currentTitle = submission.challengeTitle.trimmingCharacters(in: .whitespacesAndNewlines)

            if currentTitle != challenge.title {
                submission.challengeTitle = challenge.title
                didChange = true
            }
        }

        if didChange {
            try? modelContext.save()
        }
    }

    private func entryIsInCurrentCycle(_ entry: ChallengeEntry, challenge: ReadingChallenge) -> Bool {
        let cycle = challenge.cycle()
        return entry.cycleID == cycle.id || (
            Calendar.current.isDate(entry.startDate, inSameDayAs: cycle.startDate) &&
            Calendar.current.isDate(entry.endDate, inSameDayAs: cycle.endDate)
        )
    }

    // MARK: - Reusable Components

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(.white)
    }

    private func categoryHeader(
        category: ChallengeCategory,
        count: Int
    ) -> some View {
        HStack(spacing: 9) {
            Image(category.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(LGradients.header)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(LColors.glassSurface)
                        .overlay(
                            Circle()
                                .strokeBorder(LGradients.header, lineWidth: 1)
                        )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(count) challenge\(count == 1 ? "" : "s")")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()
        }
    }

    private func challengeList(_ challenges: [ReadingChallenge]) -> some View {
        VStack(spacing: 10) {
            ForEach(challenges) { challenge in
                Button {
                    selectedChallenge = challenge
                } label: {
                    ChallengeCardView(
                        challenge: challenge,
                        entry: entryFor(challenge),
                        badgeType: nil
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var featuredBadge: some View {
        Text("FEATURED")
            .font(.system(size: 9, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(LGradients.header)
            )
    }

    private func pointsBadge(_ points: Int) -> some View {
        HStack(spacing: 4) {
            Image("starwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 10, height: 10)
            Text("\(points) pts")
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(LColors.gradientYellow)
    }

    private func durationBadge(_ text: String) -> some View {
        HStack(spacing: 4) {
            Image("clockfill")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 10, height: 10)
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(LColors.textSecondary)
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

    @ViewBuilder
    func adaptivePresentation<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        useFullScreenCover: Bool,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        if useFullScreenCover {
            self.fullScreenCover(item: item, content: content)
        } else {
            self.sheet(item: item, content: content)
        }
    }
}
