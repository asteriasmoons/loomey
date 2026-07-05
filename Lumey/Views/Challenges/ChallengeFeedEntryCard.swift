//
//  ChallengeFeedEntryCard.swift
//  Lumey
//

import SwiftUI

struct ChallengeFeedEntryCard: View {
    let submission: ChallengeSubmissionDTO

    var linkedBookTitle: String?
    var rating: Double?
    var avatarName: String?
    var avatarURL: String?
    var isLiked: Bool
    var onLikeTapped: (() -> Void)?
    var onCommentTapped: (() -> Void)?
    var onProfileTapped: (() -> Void)?
    var isCommenting: Bool = false

    init(
        submission: ChallengeSubmissionDTO,
        linkedBookTitle: String? = nil,
        rating: Double? = nil,
        avatarName: String? = nil,
        avatarURL: String? = nil,
        isLiked: Bool = false,
        onLikeTapped: (() -> Void)? = nil,
        onCommentTapped: (() -> Void)? = nil,
        onProfileTapped: (() -> Void)? = nil,
        isCommenting: Bool = false
    ) {
        self.submission = submission
        self.linkedBookTitle = linkedBookTitle
        self.rating = rating
        self.avatarName = avatarName
        self.avatarURL = avatarURL
        self.isLiked = isLiked
        self.onLikeTapped = onLikeTapped
        self.onCommentTapped = onCommentTapped
        self.onProfileTapped = onProfileTapped
        self.isCommenting = isCommenting
    }

    var body: some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                header

                if let linkedBookTitle, !linkedBookTitle.isEmpty {
                    linkedBookPill(linkedBookTitle)
                }

                if let rating, rating > 0 {
                    ratingStars(rating)
                }

                if !displayNote.isEmpty {
                    Text("“\(displayNote)”")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !submission.proofSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    proofPreview
                }

                footer
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                onProfileTapped?()
            } label: {
                avatarView
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(displayUsername)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Text((submission.submittedDate ?? .now).formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)

                    statusBadge
                }
            }

            Spacer()
        }
    }

    private var avatarView: some View {
        LumeyUserAvatarView(
            avatarURL: avatarURL,
            avatarName: avatarName,
            size: 42,
            iconSize: 24
        )
    }

    private var statusBadge: some View {
        Text(submission.validationStatus.uppercased())
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(statusBadgeColor.opacity(0.75))
            )
    }

    private var statusBadgeColor: Color {
        switch submission.validationStatus {
        case "approved":
            return LColors.gradientGreen
        case "needsMoreInfo":
            return LColors.gradientYellow
        case "rejected":
            return LColors.gradientPurple
        case "validating":
            return LColors.gradientBlue
        default:
            return LColors.textSecondary
        }
    }

    // MARK: - Content

    private func linkedBookPill(_ title: String) -> some View {
        HStack(spacing: 6) {
            Image("openbook")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 11, height: 11)
                .foregroundStyle(LGradients.header)

            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(LColors.glassSurface)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(LColors.glassBorder, lineWidth: 1)
                )
        )
    }

    private func ratingStars(_ rating: Double) -> some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                Image("starfill")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .foregroundStyle(
                        index <= Int(rating.rounded())
                        ? AnyShapeStyle(.white)
                        : AnyShapeStyle(LColors.textSecondary)
                    )
            }
        }
    }

    private var proofPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Proof")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(submission.proofSummary)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.045))
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 16) {
            Button {
                onLikeTapped?()
            } label: {
                HStack(spacing: 5) {
                    Image("heartwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(
                            isLiked
                            ? AnyShapeStyle(LColors.gradientPurple)
                            : AnyShapeStyle(LColors.textSecondary)
                        )

                    Text("\(submission.likeCount)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            Button {
                onCommentTapped?()
            } label: {
                HStack(spacing: 5) {
                    Image("starchat")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)

                    Text("\(submission.commentCount)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                }
                .foregroundStyle(
                    isCommenting
                    ? AnyShapeStyle(.white)
                    : AnyShapeStyle(LColors.textSecondary)
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.top, 2)
    }

    // MARK: - Helpers

    private var displayUsername: String {
        let trimmed = submission.username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Reader" : trimmed
    }

    private var displayNote: String {
        submission.submissionNote.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
