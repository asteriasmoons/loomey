//
//  ChallengeDetailView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ChallengeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var appState: AppState

    let challenge: ReadingChallenge

    @Query(sort: \ChallengeEntry.startDate, order: .reverse)
    private var allEntries: [ChallengeEntry]

    @Query(sort: \ChallengeSubmission.submittedDate, order: .reverse)
    private var allSubmissions: [ChallengeSubmission]

    @Query(sort: \ChallengeUserProfile.username)
    private var profiles: [ChallengeUserProfile]

    @State private var showingSubmissionSheet = false
    @State private var showingResultView = false
    @State private var challengeManager: ChallengeManager?

    private var currentUserID: String {
        appState.currentAppleUserId ?? ""
    }

    private var userEntry: ChallengeEntry? {
        allEntries.first(where: { $0.challengeID == challenge.id && $0.userID == currentUserID })
    }

    private var userSubmission: ChallengeSubmission? {
        guard let entry = userEntry else { return nil }
        let submissions = allSubmissions.filter { $0.entryID == entry.id }
        return submissions.first(where: { $0.validationStatus == .approved }) ?? submissions.first
    }

    private var userSubmissions: [ChallengeSubmission] {
        guard let entry = userEntry else { return [] }
        return allSubmissions.filter { $0.entryID == entry.id }
    }

    private var hasApprovedSubmission: Bool {
        userEntry?.status == .approved || userSubmissions.contains { $0.validationStatus == .approved }
    }

    private var challengeSubmissions: [ChallengeSubmission] {
        allSubmissions.filter { $0.challengeID == challenge.id }
    }

    private var isJoined: Bool {
        userEntry != nil
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        challengeInfoSection
                        requirementSection
                        statsSection
                        actionSection
                        userStatusSection
                        feedSection
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            challengeManager = ChallengeManager(modelContext: modelContext)
            Task {
                await postApprovedSubmissionsToFeedIfNeeded()
            }
        }
        .adaptivePresentation(isPresented: $showingSubmissionSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            if let entry = userEntry {
                ChallengeSubmissionSheet(challenge: challenge, entry: entry)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
        }
        .adaptivePresentation(isPresented: $showingResultView, useFullScreenCover: horizontalSizeClass == .regular) {
            if let submission = userSubmission {
                ChallengeSubmissionResultView(submission: submission, challenge: challenge)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
            }
        }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            Text("Challenge")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image("xmarkwavy")
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
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(LColors.bg.opacity(0.98))
        .safeAreaPadding(.top)
    }

    // MARK: - Challenge Info

    private var challengeInfoSection: some View {
        GlassCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    Image(challenge.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(LGradients.header)
                        .frame(width: 56, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(LColors.glassSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(LColors.glassBorder, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(challenge.title)
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(.white)

                            if challenge.isFeatured {
                                Text("FEATURED")
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(LGradients.header))
                            }

                            if challenge.isWeekly {
                                Text("WEEKLY")
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .foregroundStyle(LColors.bg)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.white))
                            }
                        }

                        Text("Hosted by Lumey")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }

                    Spacer(minLength: 0)
                }

                Text(challenge.challengeDescription)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Requirement

    private var requirementSection: some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Requirement")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(challenge.requirementText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 10) {
            statCard(icon: "starfill", value: "\(challenge.points)", label: "Points", color: LColors.gradientYellow)
            statCard(icon: "clockfill", value: challenge.displayDuration, label: "Duration", color: LColors.accent)
            statCard(icon: "groupfill", value: "\(challenge.participantCount)", label: "Joined", color: LColors.gradientPurple)
            statCard(icon: "checkwavy", value: "\(challenge.completedCount)", label: "Completed", color: LColors.success)
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        GlassCard(padding: 10) {
            VStack(spacing: 6) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Action Buttons

    private var actionSection: some View {
        VStack(spacing: 10) {
            if !isJoined {
                Button {
                    joinChallenge()
                } label: {
                    HStack(spacing: 8) {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("Join Challenge")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LGradients.header)
                    )
                    .shadow(color: LColors.gradientPurple.opacity(0.3), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
            } else if let entry = userEntry {
                if hasApprovedSubmission {
                    HStack(spacing: 8) {
                        Image("checkwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)

                        Text("Approved")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LColors.glassSurface2)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(LColors.success.opacity(0.75), lineWidth: 1)
                    )
                } else if entry.status == .joined || entry.status == .needsMoreInfo {
                    Button {
                        showingSubmissionSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image("playwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("Submit Entry")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule(style: .continuous)
                                .fill(LGradients.header)
                        )
                        .shadow(color: LColors.gradientPurple.opacity(0.3), radius: 12, y: 6)
                    }
                    .buttonStyle(.plain)
                }

                if userSubmission != nil {
                    Button {
                        showingResultView = true
                    } label: {
                        HStack(spacing: 8) {
                            Image("hearteye")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("View Submission")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(LColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule(style: .continuous)
                                .fill(LColors.glassSurface2)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(LColors.glassBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - User Status

    @ViewBuilder
    private var userStatusSection: some View {
        if let entry = userEntry {
            GlassCard(padding: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Status")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 14) {
                        statusRow(label: "Status", value: entry.status.displayName)
                        statusRow(label: "Time Left", value: entry.displayDaysRemaining)
                    }

                    HStack(spacing: 14) {
                        statusRow(label: "Started", value: entry.startDate.formatted(date: .abbreviated, time: .omitted))
                        statusRow(label: "Ends", value: entry.endDate.formatted(date: .abbreviated, time: .omitted))
                    }

                    if entry.status == .approved {
                        HStack(spacing: 6) {
                            Image("starfill")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundStyle(LColors.gradientYellow)

                            Text("+\(entry.earnedPoints) points earned")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.success)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private func statusRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Feed

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !challengeSubmissions.isEmpty {
                Text("Submissions")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                ForEach(challengeSubmissions) { submission in
                    ChallengeFeedEntryCard(
                        submission: ChallengeSubmissionDTO(
                            id: submission.id.uuidString,
                            challengeID: submission.challengeID.uuidString,
                            entryID: submission.entryID.uuidString,
                            userID: submission.userID,
                            username: submission.username,
                            linkedBookIDs: submission.linkedBookIDs.map { $0.uuidString },
                            linkedSessionIDs: submission.linkedSessionIDs.map { $0.uuidString },
                            linkedReviewIDs: submission.linkedReviewIDs.map { $0.uuidString },
                            linkedReadingListIDs: submission.linkedReadingListIDs.map { $0.uuidString },
                            submissionNote: submission.submissionNote,
                            proofSummary: submission.proofSummary,
                            validationStatus: submission.validationStatus.rawValue,
                            validationMessage: submission.validationMessage,
                            submittedDate: submission.submittedDate,
                            approvedDate: submission.approvedDate,
                            postedToFeed: submission.postedToFeed,
                            feedItemID: submission.feedItemID,
                            likeCount: submission.likeCount,
                            commentCount: submission.commentCount
                        ),
                        avatarName: profile(for: submission)?.avatarName,
                        avatarURL: profile(for: submission)?.avatarURL
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func joinChallenge() {
        guard let manager = challengeManager else { return }
        _ = manager.joinChallenge(challenge, userID: currentUserID)
    }

    @MainActor
    private func postApprovedSubmissionsToFeedIfNeeded() async {
        let manager = challengeManager ?? ChallengeManager(modelContext: modelContext)
        challengeManager = manager

        for submission in userSubmissions where submission.validationStatus == .approved {
            await manager.postApprovedSubmissionToFeedIfNeeded(submission, challenge: challenge)
        }
    }

    private func profile(for submission: ChallengeSubmission) -> ChallengeUserProfile? {
        profiles.first { $0.userID == submission.userID }
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
