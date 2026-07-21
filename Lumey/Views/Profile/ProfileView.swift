//
//  ProfileView.swift
//  Lumey
//

import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var appState: AppState
    @Query private var users: [AuthUser]
    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @Query(sort: \ReadingSession.date, order: .reverse)
    private var sessions: [ReadingSession]

    @Query
    private var statsRecords: [ReadingStats]

    @Query(sort: \ChallengeUserProfile.username)
    private var challengeProfiles: [ChallengeUserProfile]

    @Query(sort: \ChallengeSubmission.submittedDate, order: .reverse)
    private var challengeSubmissions: [ChallengeSubmission]

    @Query(sort: \ChallengeEntry.startDate, order: .reverse)
    private var challengeEntries: [ChallengeEntry]

    @Query(sort: \ReadingChallenge.title)
    private var challenges: [ReadingChallenge]

    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var challengeAvatarItem: PhotosPickerItem?
    @State private var profileImage: UIImage? = nil
    @State private var showingSignInSheet = false
    @State private var editedChallengeUsername = ""
    @State private var isEditingChallengeUsername = false
    @State private var isFollowingChallengeProfile = false
    @State private var selectedConversation: ConversationDTO?
    @State private var isCreatingConversation = false
    @State private var showingMessagesList = false

    let challengeProfile: ChallengeUserProfile?
    let currentChallengeTitle: String?
    let recentChallengeSubmissions: [ChallengeSubmission]?
    let onChallengeSubmissionTapped: ((ChallengeSubmission) -> Void)?
    let showsCloseButton: Bool

    init(
        challengeProfile: ChallengeUserProfile? = nil,
        currentChallengeTitle: String? = nil,
        recentChallengeSubmissions: [ChallengeSubmission]? = nil,
        onChallengeSubmissionTapped: ((ChallengeSubmission) -> Void)? = nil,
        showsCloseButton: Bool = false
    ) {
        self.challengeProfile = challengeProfile
        self.currentChallengeTitle = currentChallengeTitle
        self.recentChallengeSubmissions = recentChallengeSubmissions
        self.onChallengeSubmissionTapped = onChallengeSubmissionTapped
        self.showsCloseButton = showsCloseButton
    }

    private var user: AuthUser? {
        appState.currentUser ?? users.first
    }

    private var isSignedIn: Bool {
        appState.currentUser != nil
    }

    private var currentUserID: String {
        appState.currentAppleUserId ?? "local-user"
    }

    private var currentUsername: String {
        let challengeUsername = activeChallengeProfile?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !challengeUsername.isEmpty {
            return challengeUsername
        }

        let displayName = appState.currentUser?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return displayName.isEmpty ? "Reader" : displayName
    }

    private var activeChallengeProfile: ChallengeUserProfile? {
        if let challengeProfile {
            return challengeProfile
        }

        return challengeProfiles.first { $0.userID == currentUserID }
    }

    private var isViewingCurrentChallengeProfile: Bool {
        activeChallengeProfile?.userID == currentUserID
    }

    private var displayedChallengeSubmissions: [ChallengeSubmission] {
        if let recentChallengeSubmissions {
            return recentChallengeSubmissions
        }

        guard let activeChallengeProfile else { return [] }

        return challengeSubmissions.filter {
            $0.userID == activeChallengeProfile.userID
        }
    }

    private var displayedCurrentChallengeTitle: String? {
        let providedTitle = currentChallengeTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !providedTitle.isEmpty {
            return providedTitle
        }

        guard let activeChallengeProfile else { return nil }

        let activeEntry = challengeEntries.first {
            $0.userID == activeChallengeProfile.userID && $0.isActive
        }

        guard let challengeID = activeEntry?.challengeID else { return nil }

        return challenges.first { $0.id == challengeID }?.title
    }

    private var profileDisplayName: String {
        let trimmed = user?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Your Name" : trimmed
    }

    private var profileEmail: String {
        let trimmed = user?.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "No email connected" : trimmed
    }

    private var readingDNABooks: [Book] {
        books.filter { !$0.isArchived && $0.deletedAt == nil }
    }

    private var finishedBooks: [Book] {
        readingDNABooks.filter { $0.status == .finished }
    }

    private var mostReadGenre: String {
        mostCommonValue(readingDNABooks.flatMap { $0.genres })
    }

    private var mostReadMood: String {
        mostCommonValue(readingDNABooks.flatMap { $0.moods })
    }

    private var mostReadTrope: String {
        mostCommonValue(readingDNABooks.flatMap { $0.tropes })
    }

    private var mostReadAuthor: String {
        mostCommonValue(
            readingDNABooks
                .map { $0.displayAuthor.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0 != "Unknown Author" }
        )
    }

    private var mostCommonBookLength: String {
        let values = readingDNABooks.compactMap { book -> String? in
            guard book.totalPages > 0 else { return nil }

            switch book.totalPages {
            case 0..<250:
                return "Under 250 pages"
            case 250..<350:
                return "250–349 pages"
            case 350..<500:
                return "350–499 pages"
            case 500..<700:
                return "500–699 pages"
            default:
                return "700+ pages"
            }
        }

        return mostCommonValue(values)
    }

    private var mostCommonRating: String {
        let values = readingDNABooks.compactMap { book -> String? in
            guard book.rating > 0 else { return nil }
            let rounded = (book.rating * 2).rounded() / 2
            return "\(rounded.cleanRating) stars"
        }

        return mostCommonValue(values)
    }

    private var averageDaysToFinish: String {
        let dayCounts = finishedBooks.compactMap { book -> Int? in
            guard let started = book.dateStarted,
                  let finished = book.dateFinished
            else { return nil }

            let days = Calendar.current.dateComponents([.day], from: started, to: finished).day ?? 0
            return max(days, 1)
        }

        guard !dayCounts.isEmpty else { return "Not enough data yet" }

        let average = dayCounts.reduce(0, +) / dayCounts.count
        return "\(average) day\(average == 1 ? "" : "s")"
    }

    private var preferredFormat: String {
        mostCommonValue(
            readingDNABooks
                .map { $0.format.rawValue }
                .filter { !$0.isEmpty }
        )
    }

    private var stats: ReadingStats? {
        ReadingStats.preferredRecord(from: statsRecords)
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    private var yearlyBooks: [Book] {
        readingDNABooks.filter { book in
            guard book.status == .finished,
                  let finishedDate = book.dateFinished
            else { return false }

            return Calendar.current.component(.year, from: finishedDate) == currentYear
        }
    }

    private var yearlySessions: [ReadingSession] {
        sessions.filter {
            Calendar.current.component(.year, from: $0.date) == currentYear
        }
    }

    private var yearlyBooksRead: String {
        "\(yearlyBooks.count)"
    }

    private var yearlyPagesRead: String {
        let sessionPages = yearlySessions.reduce(0) { $0 + $1.pagesRead }
        let finishedBookPages = yearlyBooks.reduce(0) { $0 + $1.totalPages }
        let pages = max(sessionPages, finishedBookPages)
        return "\(pages)"
    }

    private var yearlyHoursRead: String {
        let minutes = yearlySessions.reduce(0) { $0 + $1.durationMinutes }
        let hours = Double(minutes) / 60.0

        if hours == 0 { return "0" }
        if hours < 1 { return "<1" }

        return String(format: "%.1f", hours)
    }

    private var yearlyLongestStreak: String {
        "\(stats?.bestReadingStreak ?? 0) days"
    }

    private var yearlyHighestRated: String {
        guard let book = yearlyBooks
            .filter({ $0.rating > 0 })
            .max(by: { $0.rating < $1.rating })
        else { return "Not enough data yet" }

        return "\(book.displayTitle) • \(book.rating.cleanRating) stars"
    }

    private var yearlyMostEmotional: String {
        guard let book = yearlyBooks
            .filter({ $0.emotionalRating > 0 })
            .max(by: { $0.emotionalRating < $1.emotionalRating })
        else { return "Not enough data yet" }

        return book.displayTitle
    }

    private var yearlyFavoriteBook: String {
        if let favorite = yearlyBooks.first(where: { $0.isFavorite }) {
            return favorite.displayTitle
        }

        guard let highestRated = yearlyBooks
            .filter({ $0.rating > 0 })
            .max(by: { $0.rating < $1.rating })
        else { return "Not enough data yet" }

        return highestRated.displayTitle
    }

    private var yearlyLongestBook: String {
        guard let book = yearlyBooks
            .filter({ $0.totalPages > 0 })
            .max(by: { $0.totalPages < $1.totalPages })
        else { return "Not enough data yet" }

        return "\(book.displayTitle) • \(book.totalPages) pages"
    }

    private var yearlyFastestFinished: String {
        let finishedWithDays = yearlyBooks.compactMap { book -> (Book, Int)? in
            guard let started = book.dateStarted,
                  let finished = book.dateFinished
            else { return nil }

            let days = Calendar.current.dateComponents([.day], from: started, to: finished).day ?? 0
            return (book, max(days, 1))
        }

        guard let fastest = finishedWithDays.min(by: { $0.1 < $1.1 }) else {
            return "Not enough data yet"
        }

        return "\(fastest.0.displayTitle) • \(fastest.1) day\(fastest.1 == 1 ? "" : "s")"
    }

    private var readingDNAObservations: [String] {
        var observations: [String] = []

        if mostCommonBookLength != "Not enough data yet" {
            observations.append("You prefer books around \(mostCommonBookLength.lowercased()).")
        }

        if mostReadTrope != "Not enough data yet" {
            let tropeCount = readingDNABooks.filter { $0.tropes.contains(where: { $0.localizedCaseInsensitiveCompare(mostReadTrope) == .orderedSame }) }.count
            if !readingDNABooks.isEmpty {
                let percent = Int((Double(tropeCount) / Double(readingDNABooks.count)) * 100)
                observations.append("\(mostReadTrope) appears in \(percent)% of your library.")
            }
        }

        if mostReadGenre != "Not enough data yet" {
            let genreBooks = readingDNABooks.filter { $0.genres.contains(where: { $0.localizedCaseInsensitiveCompare(mostReadGenre) == .orderedSame }) }
            let ratedGenreBooks = genreBooks.filter { $0.rating > 0 }
            let ratedBooks = readingDNABooks.filter { $0.rating > 0 }

            if !ratedGenreBooks.isEmpty && !ratedBooks.isEmpty {
                let genreAverage = ratedGenreBooks.reduce(0.0) { $0 + $1.rating } / Double(ratedGenreBooks.count)
                let overallAverage = ratedBooks.reduce(0.0) { $0 + $1.rating } / Double(ratedBooks.count)
                let difference = genreAverage - overallAverage

                if abs(difference) >= 0.3 {
                    let direction = difference > 0 ? "higher" : "lower"
                    observations.append("You rate \(mostReadGenre) \(String(format: "%.1f", abs(difference))) stars \(direction) than your average.")
                }
            }
        }

        return observations.isEmpty ? ["Keep adding books and Lumey will learn your reading patterns."] : Array(observations.prefix(3))
    }

    private func mostCommonValue(_ values: [String]) -> String {
        let cleanedValues = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanedValues.isEmpty else { return "Not enough data yet" }

        let grouped = Dictionary(grouping: cleanedValues) { $0.lowercased() }

        let bestGroup = grouped.max { lhs, rhs in
            if lhs.value.count == rhs.value.count {
                return (lhs.value.first ?? lhs.key) > (rhs.value.first ?? rhs.key)
            }
            return lhs.value.count < rhs.value.count
        }

        return bestGroup?.value.first ?? "Not enough data yet"
    }

    var body: some View {
        ZStack {
            LumeyBackground().ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Nav
                HStack(spacing: 12) {
                    Text("Profile")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                    Spacer()

                    if showsCloseButton {
                        Button {
                            dismiss()
                        } label: {
                            Image("xmarkwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(LGradients.header)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(LColors.bg)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(LGradients.header, lineWidth: 1.2)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {

                        // MARK: Photo + name card
                        GlassCard(padding: 24) {
                            VStack(spacing: 16) {

                                // Circle photo picker
                                PhotosPicker(selection: $pickerItem, matching: .images) {
                                    ZStack {
                                        Circle()
                                            .fill(LColors.glassSurface2)
                                            .overlay(Circle().strokeBorder(LColors.glassBorder, lineWidth: 1))
                                            .frame(width: 96, height: 96)

                                        if let img = profileImage {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 96, height: 96)
                                                .clipShape(Circle())
                                        } else {
                                            Image("profilewavy")
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 44, height: 44)
                                                .foregroundStyle(LGradients.header)
                                        }

                                        // Camera badge
                                        Circle()
                                            .fill(LColors.glassSurface)
                                            .overlay(Circle().strokeBorder(LColors.glassBorder, lineWidth: 0.75))
                                            .frame(width: 26, height: 26)
                                            .overlay(
                                                Image("addwavy")
                                                    .renderingMode(.template)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 12, height: 12)
                                                    .foregroundStyle(LGradients.header)
                                            )
                                            .offset(x: 32, y: 32)
                                    }
                                }
                                .buttonStyle(.plain)
                                .onChange(of: pickerItem) { loadPhoto() }

                                VStack(spacing: 8) {
                                    Text(profileDisplayName)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundStyle(LColors.textPrimary)
                                        .multilineTextAlignment(.center)

                                    Text(profileEmail)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(LColors.textSecondary)
                                        .multilineTextAlignment(.center)

                                    Text(isSignedIn ? "Signed in with Apple" : "Sign in to sync your Loomey profile.")
                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                        .foregroundStyle(isSignedIn ? AnyShapeStyle(LGradients.header) : AnyShapeStyle(LColors.textSecondary))
                                        .multilineTextAlignment(.center)
                                }

                                Button {
                                    if isSignedIn {
                                        appState.signOut()
                                    } else {
                                        showingSignInSheet = true
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(isSignedIn ? "xmarkwavy" : "profilewavy")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 15, height: 15)
                                            .foregroundStyle(.white)

                                        Text(isSignedIn ? "Sign Out" : "Sign In")
                                            .font(.system(size: 14, weight: .black, design: .rounded))
                                            .foregroundStyle(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(
                                        RoundedRectangle(cornerRadius: LSpacing.buttonRadius, style: .continuous)
                                            .fill(isSignedIn ? AnyShapeStyle(LColors.glassSurface2) : AnyShapeStyle(LColors.accentGradient))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: LSpacing.buttonRadius, style: .continuous)
                                            .strokeBorder(isSignedIn ? AnyShapeStyle(LColors.glassBorder) : AnyShapeStyle(LGradients.header), lineWidth: 1.5)
                                    )
                                    .shadow(color: isSignedIn ? Color.black.opacity(0.18) : LColors.gradientPurple.opacity(0.25), radius: 12, x: 0, y: 7)
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 16)

                        if let activeChallengeProfile {
                            challengeProfileSection(activeChallengeProfile)
                                .padding(.horizontal, 16)
                        }

                        readingDNASection
                            .padding(.horizontal, 16)

                        yearInBooksSection
                            .padding(.horizontal, 16)

                        Spacer(minLength: 120)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .onAppear {
            loadSavedPhoto()
            ensureCurrentChallengeProfileIfNeeded()
            syncChallengeProfileState()
        }
        .onChange(of: activeChallengeProfile?.userID) { _, _ in
            syncChallengeProfileState()
        }
        .onChange(of: challengeAvatarItem) { _, newItem in
            Task {
                await loadChallengeAvatarImage(from: newItem)
            }
        }
        .adaptivePresentation(isPresented: $showingSignInSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            SignInView()
                .environmentObject(appState)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .preferredColorScheme(.dark)
        }
        .adaptivePresentation(item: $selectedConversation, useFullScreenCover: horizontalSizeClass == .regular) { conversation in
            ConversationView(
                conversation: conversation,
                currentUserID: currentUserID,
                currentUsername: currentUsername,
                otherAvatarURL: activeChallengeProfile?.avatarURL,
                otherAvatarName: activeChallengeProfile?.avatarName
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .adaptivePresentation(isPresented: $showingMessagesList, useFullScreenCover: horizontalSizeClass == .regular) {
            MessagesListView()
                .environmentObject(appState)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Challenge Profile

    private func challengeProfileSection(_ profile: ChallengeUserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Challenge Profile")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            challengeProfileHero(profile)

            challengeStatsGrid(profile)

            if let title = displayedCurrentChallengeTitle,
               !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                currentChallengeCard(title)
            }

            if !challengeBio(for: profile).isEmpty {
                challengeBioCard(profile)
            }

            recentChallengeEntriesSection
        }
    }

    private func challengeProfileHero(_ profile: ChallengeUserProfile) -> some View {
        GlassCard {
            VStack(spacing: 16) {
                challengeAvatarView(profile)

                VStack(spacing: 10) {
                    if isEditingChallengeUsername && isViewingCurrentChallengeProfile {
                        VStack(spacing: 10) {
                            TextField("Username", text: $editedChallengeUsername)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(LColors.glassSurface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(LColors.glassBorder, lineWidth: 1)
                                        )
                                )

                            Button {
                                saveChallengeUsername(profile)
                            } label: {
                                Text("Save Username")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(LGradients.header)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    } else if isViewingCurrentChallengeProfile {
                        Button {
                            editedChallengeUsername = challengeUsername(for: profile)
                            isEditingChallengeUsername = true
                        } label: {
                            challengeUsernameLabel(profile, showsEditIcon: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        challengeUsernameLabel(profile, showsEditIcon: false)
                    }

                    if !challengeFavoriteGenre(for: profile).isEmpty {
                        HStack(spacing: 6) {
                            Image("sparklybook")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(LGradients.header)

                            Text(challengeFavoriteGenre(for: profile))
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                    }

                    challengeSocialActions(profile)
                }

                HStack(spacing: 10) {
                    socialMiniStat(title: "Followers", value: "\(profile.followersCount)")
                    socialMiniStat(title: "Following", value: "\(profile.followingCount)")
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func challengeAvatarView(_ profile: ChallengeUserProfile) -> some View {
        if isViewingCurrentChallengeProfile {
            PhotosPicker(selection: $challengeAvatarItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    challengeAvatarImage(profile)

                    Image("upload")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 13, height: 13)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(LGradients.header)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                                )
                        )
                }
            }
            .buttonStyle(.plain)
        } else {
            challengeAvatarImage(profile)
        }
    }

    private func challengeAvatarImage(_ profile: ChallengeUserProfile) -> some View {
        UserAvatarView(
            avatarURL: profile.avatarURL,
            avatarName: profile.avatarName,
            size: 104,
            iconSize: 60
        )
        .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 16, y: 8)
    }

    private func challengeUsernameLabel(
        _ profile: ChallengeUserProfile,
        showsEditIcon: Bool
    ) -> some View {
        HStack(spacing: 6) {
            Text(challengeUsername(for: profile))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            if showsEditIcon {
                Image("pencil")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .foregroundStyle(LColors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func challengeSocialActions(_ profile: ChallengeUserProfile) -> some View {
        HStack(spacing: 10) {
            if !isViewingCurrentChallengeProfile {
                Button {
                    toggleChallengeFollow(profile)
                } label: {
                    Text(isFollowingChallengeProfile ? "Following" : "Follow")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(isFollowingChallengeProfile ? AnyShapeStyle(LColors.glassSurface) : AnyShapeStyle(LGradients.header))
                                .overlay(
                                    Capsule(style: .continuous)
                                        .strokeBorder(LGradients.header, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        await startMessage(with: profile)
                    }
                } label: {
                    Image("sendbutton")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(isCreatingConversation ? AnyShapeStyle(LColors.glassSurface) : AnyShapeStyle(LGradients.header))
                                .overlay(
                                    Circle()
                                        .strokeBorder(LGradients.header, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(isCreatingConversation)
            }

            Button {
                showingMessagesList = true
            } label: {
                Image("chatlinesfill")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(LColors.glassSurface)
                            .overlay(
                                Circle()
                                    .strokeBorder(LGradients.header, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func socialMiniStat(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.045))
        )
    }

    private func challengeStatsGrid(_ profile: ChallengeUserProfile) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            challengeStatCard(
                icon: "startrophyhands",
                title: "Completed",
                value: "\(profile.challengesCompleted)",
                subtitle: "Challenges"
            )

            challengeStatCard(
                icon: "starfill",
                title: "Points",
                value: "\(profile.challengePoints)",
                subtitle: "Earned"
            )

            challengeStatCard(
                icon: "loveflame",
                title: "Streak",
                value: "\(profile.readingStreak)",
                subtitle: profile.readingStreak == 1 ? "Day" : "Days"
            )

            challengeStatCard(
                icon: "sparkle",
                title: "Entries",
                value: "\(displayedChallengeSubmissions.count)",
                subtitle: "Recent"
            )
        }
    }

    private func challengeStatCard(
        icon: String,
        title: String,
        value: String,
        subtitle: String
    ) -> some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(LColors.glassSurface)
                            .overlay(
                                Circle()
                                    .strokeBorder(LGradients.header, lineWidth: 1)
                            )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(title)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func currentChallengeCard(_ title: String) -> some View {
        GlassCard {
            HStack(spacing: 12) {
                Image("stargoal")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(LColors.glassSurface)
                            .overlay(
                                Circle()
                                    .strokeBorder(LGradients.header, lineWidth: 1)
                            )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Challenge")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }
        }
    }

    private func challengeBioCard(_ profile: ChallengeUserProfile) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                profileSectionHeader(icon: "starnote", title: "About")

                Text(challengeBio(for: profile))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var recentChallengeEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            profileSectionHeader(icon: "sparkle", title: "Recent Challenge Entries")

            if displayedChallengeSubmissions.isEmpty {
                GlassCard {
                    VStack(spacing: 10) {
                        Image("openbook")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundStyle(LGradients.header)

                        Text("No recent entries yet.")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Challenge submissions will appear here once this reader starts joining events.")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(displayedChallengeSubmissions, id: \.id) { submission in
                        Button {
                            onChallengeSubmissionTapped?(submission)
                        } label: {
                            recentChallengeSubmissionRow(submission)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func recentChallengeSubmissionRow(_ submission: ChallengeSubmission) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(statusIcon(for: submission.validationStatus))
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(LGradients.header)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(LColors.glassSurface)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(submission.validationStatus.displayName)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(submission.submittedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image("heartwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(LGradients.header)

                    Text("\(submission.likeCount)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                HStack(spacing: 4) {
                    Image("starchat")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(LColors.textSecondary)

                    Text("\(submission.commentCount)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.white.opacity(0.045))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func profileSectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 9) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(LGradients.header)

            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer()
        }
    }

    // MARK: - Reading DNA

    private var readingDNASection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reading DNA")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Lumey learns your reading habits automatically.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    ReadingDNARow(iconName: "openbook", title: "Most Read Genre", value: mostReadGenre)
                    ReadingDNARow(iconName: "xsmile", title: "Most Read Mood", value: mostReadMood)
                    ReadingDNARow(iconName: "sparkle", title: "Most Read Trope", value: mostReadTrope)
                    ReadingDNARow(iconName: "profilewavy", title: "Most Read Author", value: mostReadAuthor)
                    ReadingDNARow(iconName: "starwavy", title: "Most Common Book Length", value: mostCommonBookLength)
                    ReadingDNARow(iconName: "starfill", title: "Most Common Rating", value: mostCommonRating)
                    ReadingDNARow(iconName: "clockfill", title: "Average Days To Finish", value: averageDaysToFinish)
                    ReadingDNARow(iconName: "starmark", title: "Preferred Format", value: preferredFormat)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Observations")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    ForEach(readingDNAObservations, id: \.self) { observation in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(LGradients.header)
                                .frame(width: 9, height: 9)
                                .padding(.top, 5)

                            Text(observation)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Year In Books

    private var yearInBooksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Year In Books")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Your \(currentYear) reading wrapped into one cozy report.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)

            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        Image("startrophyfill")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(LGradients.header)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(LGradients.header, lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(currentYear) Wrapped")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(.white)

                            Text("The story your reading year tells.")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                    }

                    DottedDivider()

                    VStack(alignment: .leading, spacing: 12) {
                        ReadingDNARow(iconName: "openbook", title: "Books Read", value: yearlyBooksRead)
                        ReadingDNARow(iconName: "bulletlovenote", title: "Pages Read", value: yearlyPagesRead)
                        ReadingDNARow(iconName: "clockfill", title: "Hours Read", value: yearlyHoursRead)
                        ReadingDNARow(iconName: "flame", title: "Longest Streak", value: yearlyLongestStreak)
                        ReadingDNARow(iconName: "sparklesstarflag", title: "Highest Rated", value: yearlyHighestRated)
                        ReadingDNARow(iconName: "heartfill", title: "Most Emotional", value: yearlyMostEmotional)
                        ReadingDNARow(iconName: "loveflame", title: "Favorite Book", value: yearlyFavoriteBook)
                        ReadingDNARow(iconName: "flatbook", title: "Longest Book", value: yearlyLongestBook)
                        ReadingDNARow(iconName: "sparkbolt", title: "Fastest Finished", value: yearlyFastestFinished)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Challenge profile actions

    private func ensureCurrentChallengeProfileIfNeeded() {
        guard challengeProfile == nil else { return }
        guard challengeProfiles.first(where: { $0.userID == currentUserID }) == nil else { return }

        let username = appState.currentUser?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let profile = ChallengeUserProfile(
            userID: currentUserID,
            username: username.isEmpty ? "Reader" : username,
            avatarName: nil,
            bio: nil,
            favoriteGenre: nil
        )

        modelContext.insert(profile)
        try? modelContext.save()
    }

    private func syncChallengeProfileState() {
        guard let activeChallengeProfile else { return }

        editedChallengeUsername = challengeUsername(for: activeChallengeProfile)
        isFollowingChallengeProfile = activeChallengeProfile.isFollowing
    }

    private func challengeUsername(for profile: ChallengeUserProfile) -> String {
        let trimmed = profile.username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Reader" : trimmed
    }

    private func challengeBio(for profile: ChallengeUserProfile) -> String {
        profile.bio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func challengeFavoriteGenre(for profile: ChallengeUserProfile) -> String {
        profile.favoriteGenre?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    @MainActor
    private func startMessage(with profile: ChallengeUserProfile) async {
        guard !isCreatingConversation else { return }

        isCreatingConversation = true

        do {
            let conversation = try await ChallengeSocialService.shared.createConversation(
                senderUserID: currentUserID,
                senderUsername: currentUsername,
                recipientUserID: profile.userID,
                recipientUsername: challengeUsername(for: profile)
            )

            selectedConversation = conversation
        } catch {
            print("Failed to start conversation:", error)
        }

        isCreatingConversation = false
    }

    private func saveChallengeUsername(_ profile: ChallengeUserProfile) {
        let trimmed = editedChallengeUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        profile.username = trimmed
        isEditingChallengeUsername = false

        try? modelContext.save()

        updateRemoteChallengeProfile(profile)
    }

    private func toggleChallengeFollow(_ profile: ChallengeUserProfile) {
        isFollowingChallengeProfile.toggle()
        profile.isFollowing = isFollowingChallengeProfile

        if isFollowingChallengeProfile {
            profile.followersCount += 1
        } else {
            profile.followersCount = max(0, profile.followersCount - 1)
        }

        try? modelContext.save()

        updateRemoteChallengeProfile(profile)
    }

    @MainActor
    private func loadChallengeAvatarImage(from item: PhotosPickerItem?) async {
        guard let item,
              let activeChallengeProfile,
              isViewingCurrentChallengeProfile
        else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let avatarURL = try await ChallengeSocialService.shared.uploadProfileAvatar(
                    imageData: data
                )

                activeChallengeProfile.avatarURL = avatarURL
                try? modelContext.save()

                updateRemoteChallengeProfile(activeChallengeProfile)
            }
        } catch {
            print("Failed to upload avatar image:", error)
        }
    }

    private func updateRemoteChallengeProfile(_ profile: ChallengeUserProfile) {
        Task {
            try? await ChallengeSocialService.shared.updateProfile(
                userID: profile.userID,
                username: profile.username,
                avatarName: profile.avatarName,
                avatarURL: profile.avatarURL,
                bio: profile.bio,
                favoriteGenre: profile.favoriteGenre,
                readingStreak: profile.readingStreak,
                challengePoints: profile.challengePoints,
                challengesCompleted: profile.challengesCompleted,
                followersCount: profile.followersCount,
                followingCount: profile.followingCount
            )
        }
    }

    private func statusIcon(for status: ChallengeSubmissionStatus) -> String {
        switch status {
        case .approved:
            return "checkwavy"
        case .inProgress:
            return "clockfill"
        case .needsMoreInfo:
            return "questionwavy"
        case .rejected:
            return "xmarkwavy"
        case .validating, .submitted:
            return "sparkle"
        case .joined, .readyToSubmit:
            return "openbook"
        case .expired:
            return "clockfill"
        }
    }

    // MARK: - Photo handling

    private func loadPhoto() {
        Task {
            guard let item = pickerItem,
                  let data = try? await item.loadTransferable(type: Data.self),
                  let img = UIImage(data: data) else { return }
            await MainActor.run {
                profileImage = img
                savePhoto(img)
            }
        }
    }

    private func savePhoto(_ img: UIImage) {
        guard let data = img.jpegData(compressionQuality: 0.85) else { return }
        let url = photoURL()
        try? data.write(to: url)
        users.first?.profileImagePath = url.path
        try? modelContext.save()
    }

    private func loadSavedPhoto() {
        let url = photoURL()
        if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
            profileImage = img
        }
    }

    private func photoURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("lumey_profile_photo.jpg")
    }
}

struct ReadingDNARow: View {
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
                .frame(width: 38, height: 38)
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

private extension Double {
    var cleanRating: String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(self))"
        } else {
            return String(format: "%.1f", self)
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
