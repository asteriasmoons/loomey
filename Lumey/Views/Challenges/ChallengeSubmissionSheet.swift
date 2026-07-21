//
//  ChallengeSubmissionSheet.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ChallengeSubmissionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var appState: AppState

    let challenge: ReadingChallenge
    let entry: ChallengeEntry

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var allBooks: [Book]

    @Query(sort: \ReadingSession.date, order: .reverse)
    private var allSessions: [ReadingSession]

    @Query(sort: \BookReview.dateCreated, order: .reverse)
    private var allReviews: [BookReview]

    @Query(sort: \ReadingList.updatedAt, order: .reverse)
    private var allReadingLists: [ReadingList]

    @Query(sort: \ChallengeSubmission.submittedDate, order: .reverse)
    private var allSubmissions: [ChallengeSubmission]

    @State private var selectedBookIDs: [UUID] = []
    @State private var selectedSessionIDs: [UUID] = []
    @State private var selectedReviewIDs: [UUID] = []
    @State private var selectedReadingListIDs: [UUID] = []
    @State private var submissionNote = ""
    @State private var isSubmitting = false
    @State private var showResult = false
    @State private var resultSubmission: ChallengeSubmission?
    @State private var visibleSessionCount = 6

    private var currentUserID: String {
        appState.currentAppleUserId ?? ""
    }

    private var needsBooks: Bool {
        [.bookCompletion, .genre, .series, .author, .seasonalTheme, .bookLength].contains(challenge.validationType)
    }

    private var needsSessions: Bool {
        [.readingSession, .pageCount, .experience].contains(challenge.validationType)
    }

    private var needsReviews: Bool {
        challenge.validationType == .review
    }

    private var needsReadingLists: Bool {
        challenge.validationType == .collection
    }

    private var needsSubmissionNote: Bool {
        challenge.validationType == .experience || challenge.validationType == .seasonalTheme || challenge.requiresAIValidation
    }

    private var isSubmissionLocked: Bool {
        entry.status == .approved || allSubmissions.contains {
            $0.entryID == entry.id && $0.validationStatus == .approved
        }
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        challengeInfoCard

                        if isSubmissionLocked {
                            approvedLockCard
                        }

                        if !isSubmissionLocked && needsBooks {
                            bookPickerSection
                        }

                        if !isSubmissionLocked && needsSessions {
                            sessionPickerSection
                        }

                        if !isSubmissionLocked && needsReviews {
                            reviewPickerSection
                        }

                        if !isSubmissionLocked && needsReadingLists {
                            readingListPickerSection
                        }

                        if !isSubmissionLocked && (needsSubmissionNote || challenge.requiresAIValidation) {
                            submissionNoteSection
                        }

                        if !isSubmissionLocked {
                            proofSummarySection
                        }

                        submitButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }

            if isSubmitting {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                VStack(spacing: 14) {
                    ProgressView()
                        .tint(LColors.accent)
                        .scaleEffect(1.4)
                    Text("Validating...")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .adaptivePresentation(isPresented: $showResult, useFullScreenCover: horizontalSizeClass == .regular) {
            if let submission = resultSubmission {
                ChallengeSubmissionResultView(submission: submission, challenge: challenge)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
            }
        }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Submit Entry")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(challenge.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

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
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
        .safeAreaPadding(.top)
    }

    // MARK: - Challenge Info

    private var challengeInfoCard: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                Image(challenge.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(LGradients.header)

                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.requirementText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(entry.displayDaysRemaining)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                Spacer()
            }
        }
    }

    private var approvedLockCard: some View {
        GlassCard(padding: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image("checkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LColors.success)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Submission Approved")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("This challenge is locked to prevent accidental resubmission.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Book Picker

    private var bookPickerSection: some View {
        pickerSection(title: "Link Books", icon: "flatbook") {
            let eligible = allBooks.filter { !$0.isArchived }

            if selectedBookIDs.isEmpty {
                Text("Tap to select books")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            ForEach(eligible.prefix(50)) { book in
                let isSelected = selectedBookIDs.contains(book.id)
                Button {
                    toggleSelection(id: book.id, in: &selectedBookIDs)
                } label: {
                    HStack(spacing: 10) {
                        Image(isSelected ? "checkwavy" : "flatbook")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(isSelected ? LColors.success : LColors.textSecondary)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(book.displayTitle)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text("\(book.author) · \(book.totalPages)p · \(book.status.rawValue)")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Session Picker

    private var sessionPickerSection: some View {
        pickerSection(title: "Link Reading Sessions", icon: "clockfill") {
            if allSessions.isEmpty {
                Text("No reading sessions found")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            ForEach(allSessions.prefix(visibleSessionCount)) { session in
                let isSelected = selectedSessionIDs.contains(session.id)
                Button {
                    toggleSelection(id: session.id, in: &selectedSessionIDs)
                } label: {
                    HStack(spacing: 10) {
                        Image(isSelected ? "checkwavy" : "clockfill")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(isSelected ? LColors.success : LColors.textSecondary)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(session.linkedBookTitle.isEmpty ? "Reading Session" : session.linkedBookTitle)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text("\(session.durationMinutes) min · \(session.pagesRead)p · \(session.date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }

            if allSessions.count > visibleSessionCount {
                Button {
                    visibleSessionCount = min(visibleSessionCount + 6, allSessions.count)
                } label: {
                    Text("Load More Sessions")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(LColors.glassSurface2)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(LGradients.header, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Review Picker

    private var reviewPickerSection: some View {
        pickerSection(title: "Link Reviews", icon: "pagepencil") {
            if allReviews.isEmpty {
                Text("No reviews found")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            ForEach(allReviews.prefix(20)) { review in
                let isSelected = selectedReviewIDs.contains(review.id)
                Button {
                    toggleSelection(id: review.id, in: &selectedReviewIDs)
                } label: {
                    HStack(spacing: 10) {
                        Image(isSelected ? "checkwavy" : "pagepencil")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(isSelected ? LColors.success : LColors.textSecondary)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(review.title.isEmpty ? "Untitled Review" : review.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            let wordCount = review.content.split(separator: " ").count
                            Text("\(wordCount) words · \(review.dateCreated.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Reading List Picker

    private var readingListPickerSection: some View {
        pickerSection(title: "Link Reading Lists", icon: "bookstack") {
            ForEach(allReadingLists.prefix(20)) { list in
                let isSelected = selectedReadingListIDs.contains(list.id)
                Button {
                    toggleSelection(id: list.id, in: &selectedReadingListIDs)
                } label: {
                    HStack(spacing: 10) {
                        Image(isSelected ? "checkwavy" : "bookstack")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(isSelected ? LColors.success : LColors.textSecondary)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(list.displayTitle)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text("\(list.bookCount) books")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Submission Note

    private var submissionNoteSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Submission Note")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                if challenge.requiresAIValidation {
                    Text("Describe your experience — this helps us validate your submission.")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                TextEditor(text: $submissionNote)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(minHeight: 80)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LColors.glassSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(LColors.glassBorder, lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Proof Summary

    private var proofSummarySection: some View {
        ChallengeProofSummaryView(
            challenge: challenge,
            selectedBookIDs: selectedBookIDs,
            selectedSessionIDs: selectedSessionIDs,
            selectedReviewIDs: selectedReviewIDs,
            selectedReadingListIDs: selectedReadingListIDs,
            books: allBooks,
            sessions: allSessions,
            reviews: allReviews,
            readingLists: allReadingLists
        )
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            submitEntry()
        } label: {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image("playwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                Text(isSubmissionLocked ? "Already Approved" : "Submit for Validation")
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
        .disabled(isSubmitting || isSubmissionLocked)
        .opacity(isSubmitting || isSubmissionLocked ? 0.6 : 1)
    }

    // MARK: - Picker Section Builder

    private func pickerSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(LGradients.header)

                    Text(title)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Toggle Selection

    private func toggleSelection(id: UUID, in array: inout [UUID]) {
        if let index = array.firstIndex(of: id) {
            array.remove(at: index)
        } else {
            array.append(id)
        }
    }

    // MARK: - Submit

    private func submitEntry() {
        guard !isSubmissionLocked else { return }

        isSubmitting = true

        print("===== SUBMIT ENTRY START =====")
        print("Selected Book IDs:", selectedBookIDs)
        print("Selected Session IDs:", selectedSessionIDs)
        print("Selected Review IDs:", selectedReviewIDs)
        print("Selected Reading List IDs:", selectedReadingListIDs)
        print("Submission Note:", submissionNote)

        let selectedBooks = allBooks.filter { selectedBookIDs.contains($0.id) }
        let selectedSessions = allSessions.filter { selectedSessionIDs.contains($0.id) }

        let bookProofParts = selectedBooks.map {
            "\($0.title) by \($0.author)"
        }

        let sessionProofParts = selectedSessions.map { session in
            let title = session.linkedBookTitle.isEmpty ? "Reading Session" : session.linkedBookTitle
            return "\(title) • \(session.durationMinutes) min • \(session.pagesRead) pages"
        }

        let proofParts = bookProofParts + sessionProofParts
        let proofSummary = proofParts.joined(separator: "\n")

        print("Selected Books Count:", selectedBooks.count)
        print("Selected Sessions Count:", selectedSessions.count)

        for session in selectedSessions {
            print("SESSION SELECTED:")
            print("ID:", session.id)
            print("Book:", session.linkedBookTitle)
            print("Minutes:", session.durationMinutes)
            print("Pages:", session.pagesRead)
            print("Date:", session.date)
        }

        print("Proof Summary Being Saved:", proofSummary)

        let submission = ChallengeSubmission(
            challengeID: challenge.id,
            entryID: entry.id,
            userID: currentUserID,
            username: appState.currentUser?.displayName ?? "Reader",
            challengeTitle: challenge.title,
            linkedBookIDs: selectedBookIDs,
            linkedSessionIDs: selectedSessionIDs,
            linkedReviewIDs: selectedReviewIDs,
            linkedReadingListIDs: selectedReadingListIDs,
            submissionNote: submissionNote,
            proofSummary: proofSummary
        )

        print("SUBMISSION CREATED:")
        print("Submission Linked Session IDs:", submission.linkedSessionIDs)
        print("Submission Proof Summary:", submission.proofSummary)
        print("===== SUBMIT ENTRY BEFORE SAVE =====")

        modelContext.insert(submission)
        print("===== SUBMISSION SAVED =====")
        try? modelContext.save()

        let manager = ChallengeManager(modelContext: modelContext)

        Task {
            await manager.submitChallenge(
                challenge: challenge,
                entry: entry,
                submission: submission
            )

            await MainActor.run {
                isSubmitting = false
                resultSubmission = submission
                showResult = true
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
