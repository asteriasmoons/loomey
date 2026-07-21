//
//  ChallengeSubmissionResultView.swift
//  Lumey
//

import SwiftUI

struct ChallengeSubmissionResultView: View {
    @Environment(\.dismiss) private var dismiss

    let submission: ChallengeSubmission
    let challenge: ReadingChallenge

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        resultHeroCard

                        messageCard

                        if submission.validationStatus == .approved {
                            pointsCard
                        }

                        proofCard

                        actionButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 34)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text("Submission Result")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

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

    // MARK: - Hero

    private var resultHeroCard: some View {
        GlassCard {
            VStack(alignment: .center, spacing: 14) {
                Image(statusIcon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 76, height: 76)
                    .background(
                        Circle()
                            .fill(LColors.glassSurface)
                            .overlay(
                                Circle()
                                    .strokeBorder(LGradients.header, lineWidth: 1.3)
                            )
                            .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 14, y: 7)
                    )

                VStack(spacing: 6) {
                    Text(statusTitle)
                        .font(.system(size: 23, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(challenge.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                statusBadge
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var statusBadge: some View {
        Text(submission.validationStatus.displayName.uppercased())
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(lumeyHex: submission.validationStatus.badgeColor).opacity(0.25))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(Color(lumeyHex: submission.validationStatus.badgeColor).opacity(0.75), lineWidth: 1)
                    )
            )
    }

    // MARK: - Message

    private var messageCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(icon: "sparkle", title: "Validation Message")

                Text(resultMessage)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Points

    private var pointsCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image("achievement")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 46, height: 46)
                    .background(
                        Circle()
                            .fill(LColors.glassSurface)
                            .overlay(
                                Circle()
                                    .strokeBorder(LGradients.header, lineWidth: 1)
                            )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Points Awarded")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("\(challenge.points) points earned")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Proof

    private var proofCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(icon: "checkwavy", title: "Submitted Proof")

                if displayProofSummary.isEmpty {
                    Text("No proof summary was saved for this submission.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                } else {
                    Text(displayProofSummary)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !submission.submissionNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Divider()
                        .background(Color.white.opacity(0.12))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Note")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text(submission.submissionNote)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: - Action

    private var actionButton: some View {
        Button {
            dismiss()
        } label: {
            Text(buttonTitle)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LGradients.header)
                        .shadow(color: LColors.gradientBlue.opacity(0.22), radius: 14, y: 7)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Small Pieces

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 9) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(LGradients.header)

            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer()
        }
    }

    // MARK: - Computed Text

    private var statusIcon: String {
        switch submission.validationStatus {
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
            return "clockwavy"
        }
    }

    private var statusTitle: String {
        switch submission.validationStatus {
        case .approved:
            return "Challenge Approved"
        case .inProgress:
            return "In Progress"
        case .needsMoreInfo:
            return "Needs More Info"
        case .rejected:
            return "Not Eligible Yet"
        case .validating:
            return "Validating Submission"
        case .submitted:
            return "Submission Received"
        case .joined:
            return "Challenge Joined"
        case .readyToSubmit:
            return "Ready to Submit"
        case .expired:
            return "Challenge Expired"
        }
    }

    private var resultMessage: String {
        if let message = submission.validationMessage,
           !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return message
        }

        switch submission.validationStatus {
        case .approved:
            return "Your submission was approved and your points have been awarded."
        case .inProgress:
            return "Your challenge progress has been saved. Keep going until you meet the full requirement."
        case .needsMoreInfo:
            return "This submission needs a little more information before it can be approved."
        case .rejected:
            return "This submission does not meet the challenge requirements yet."
        case .validating:
            return "Lumey is checking your linked proof and validation details."
        case .submitted:
            return "Your submission has been received and is ready for validation."
        case .joined:
            return "You joined this challenge. Submit an entry when your proof is ready."
        case .readyToSubmit:
            return "Your challenge looks ready for an entry."
        case .expired:
            return "This challenge entry expired before approval."
        }
    }

    private var buttonTitle: String {
        switch submission.validationStatus {
        case .approved:
            return "Done"
        case .inProgress:
            return "Close"
        case .needsMoreInfo:
            return "Review Submission"
        case .rejected:
            return "Close"
        case .validating, .submitted:
            return "Close"
        case .joined, .readyToSubmit:
            return "Close"
        case .expired:
            return "Close"
        }
    }

    private var displayProofSummary: String {
        let trimmed = submission.proofSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        guard !trimmed.contains("\n") else { return trimmed }

        return trimmed.replacingOccurrences(of: ", ", with: "\n")
    }
}
