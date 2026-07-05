//
//  BookRecommendationsSheet.swift
//  Lumey
//

import SwiftData
import SwiftUI

struct BookRecommendationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @State private var genre: String = ""
    @State private var recommendations: [LumeyBookRecommendation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var addedRecommendationKeys: Set<String> = []
    @State private var expandedRecommendationKeys: Set<String> = []
    @State private var bookToEditAfterAdd: Book?
    @State private var showEditBookAfterAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        headerSection
                        searchCard

                        if isLoading {
                            VStack {
                                Spacer(minLength: 160)

                                ProgressView()

                                Spacer(minLength: 160)
                            }
                            .frame(maxWidth: .infinity)
                        } else if let errorMessage {
                            Text(errorMessage)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 20)
                        } else if recommendations.isEmpty {
                            emptyState
                        } else {
                            recommendationsList
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditBookAfterAdd) {
                if let bookToEditAfterAdd {
                    AddEditBookSheet(book: bookToEditAfterAdd) { _ in }
                        .presentationDetents([.large])
                        .presentationDragIndicator(.hidden)
                }
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Recommendations")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Search by a book title for the strongest similar-book recommendations, or try a genre or vibe for broader discovery.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 12)

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
    }

    private var searchCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                TextField("Fourth Wing, fantasy, cozy mystery...", text: $genre)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(.white.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text("Tip: book titles usually give better results than broad genres.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)

                Button {
                    Task {
                        await fetchRecommendations()
                    }
                } label: {
                    Text(isLoading ? "Finding Books..." : "Find Recommendations")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [
                                    LColors.gradientBlue,
                                    LColors.gradientPurple,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .disabled(isLoading || genre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(genre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
            }
            .padding(16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image("searchwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .foregroundStyle(.secondary)

            Text("No recommendations yet")
                .font(.headline)

            Text("For best results, search a book title you already like. Genres and vibes can work too, but title searches give Lumey more to compare.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    private var recommendationsList: some View {
        VStack(spacing: 14) {
            ForEach(recommendations) { book in
                recommendationCard(book)
            }
        }
    }

    private func recommendationCard(_ book: LumeyBookRecommendation) -> some View {
        let isExpanded = isRecommendationExpanded(book)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                coverView(book.coverUrl)

                VStack(alignment: .leading, spacing: 5) {
                    Text(book.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if !book.author.isEmpty {
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        if let releaseYear = book.releaseYear {
                            metadataPill("\(releaseYear)")
                        }

                        if let pages = book.pages {
                            metadataPill("\(pages) pages")
                        }

                        if let rating = book.rating {
                            metadataPill(String(format: "%.1f", rating))
                        }
                    }
                }

                Spacer(minLength: 0)

                Button {
                    toggleRecommendationExpanded(book)
                } label: {
                    Image(isExpanded ? "chevup" : "chevdown")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [LColors.gradientBlue, LColors.gradientPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [LColors.gradientBlue, LColors.gradientPurple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.2
                                        )
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            Text(book.summary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(isExpanded ? nil : 5)

            if let tags = book.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags.prefix(6), id: \.self) { tag in
                            metadataPill(tag)
                        }
                    }
                }
            }

            addToLibraryButton(for: book)
        }
        .padding(14)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
    }

    private func isRecommendationExpanded(_ recommendation: LumeyBookRecommendation) -> Bool {
        expandedRecommendationKeys.contains(recommendationKey(recommendation))
    }

    private func toggleRecommendationExpanded(_ recommendation: LumeyBookRecommendation) {
        let key = recommendationKey(recommendation)

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            if expandedRecommendationKeys.contains(key) {
                expandedRecommendationKeys.remove(key)
            } else {
                expandedRecommendationKeys.insert(key)
            }
        }
    }

    private func addToLibraryButton(for recommendation: LumeyBookRecommendation) -> some View {
        let alreadyAdded = isRecommendationInLibrary(recommendation)

        return Button {
            addRecommendationToLibrary(recommendation)
        } label: {
            HStack(spacing: 8) {
                Image(alreadyAdded ? "checkwavy" : "addwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)

                Text(alreadyAdded ? "Added to Library" : "Add to Library")
                    .font(.system(size: 13, weight: .black, design: .rounded))
            }
            .foregroundStyle(alreadyAdded ? LColors.textSecondary : .black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        alreadyAdded
                            ? LinearGradient(
                                colors: [
                                    Color.white.opacity(0.10),
                                    Color.white.opacity(0.06),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    LColors.gradientBlue,
                                    LColors.gradientPurple,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(alreadyAdded ? 0.14 : 0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(alreadyAdded)
    }

    private func addRecommendationToLibrary(_ recommendation: LumeyBookRecommendation) {
        guard !isRecommendationInLibrary(recommendation) else { return }

        let bookTitle = recommendation.title
        let bookAuthor = recommendation.author
        let bookSummary = recommendation.summary
        let bookRating = recommendation.rating ?? 0
        let bookTotalPages = recommendation.pages ?? 0
        let bookCoverURL = recommendation.coverUrl ?? ""
        let bookTags = recommendation.tags ?? []
        let bookGenres: [String] = bookTags.first.map { [$0] } ?? []

        let bookPublicationYear: String
        if let releaseYear = recommendation.releaseYear {
            bookPublicationYear = String(releaseYear)
        } else {
            bookPublicationYear = ""
        }

        let bookNotes: String
        if let source = recommendation.source, !source.isEmpty {
            bookNotes = "Recommended by Lumey. Source: \(source)."
        } else {
            bookNotes = "Recommended by Lumey."
        }

        let bookStatus = BookStatus.toBeRead
        let bookFormat = BookFormat.other
        let bookOwnership = BookOwnership.wishlist

        let newBook = Book(
            title: bookTitle,
            author: bookAuthor,
            publicationYear: bookPublicationYear,
            summary: bookSummary,
            rating: bookRating,
            status: bookStatus,
            format: bookFormat,
            ownership: bookOwnership,
            totalPages: bookTotalPages,
            notes: bookNotes,
            genres: bookGenres,
            tags: bookTags,
            coverURL: bookCoverURL
        )

        modelContext.insert(newBook)
        addedRecommendationKeys.insert(recommendationKey(recommendation))
        bookToEditAfterAdd = newBook

        do {
            try modelContext.save()
            showEditBookAfterAdd = true
        } catch {
            print("Failed to save recommended book:", error)
            errorMessage = "Lumey couldn't add this book to your library."
        }
    }

    private func isRecommendationInLibrary(_ recommendation: LumeyBookRecommendation) -> Bool {
        let targetKey = recommendationKey(recommendation)

        if addedRecommendationKeys.contains(targetKey) {
            return true
        }

        for existingBook in books {
            let existingTitle = existingBook.title
            let existingAuthor = existingBook.author
            let existingKey = recommendationKey(title: existingTitle, author: existingAuthor)

            if existingKey == targetKey {
                return true
            }
        }

        return false
    }

    private func recommendationKey(_ recommendation: LumeyBookRecommendation) -> String {
        recommendationKey(title: recommendation.title, author: recommendation.author)
    }

    private func recommendationKey(title: String, author: String) -> String {
        let rawKey = "\(title)|\(author)"
        let lowercasedKey = rawKey.lowercased()
        return lowercasedKey.replacingOccurrences(
            of: "[^a-z0-9|]",
            with: "",
            options: .regularExpression
        )
    }

    private func coverView(_ urlString: String?) -> some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image("bookstand")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Image("bookstand")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 62, height: 92)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func metadataPill(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.white.opacity(0.12))
            .clipShape(Capsule())
    }

    @MainActor
    private func fetchRecommendations() async {
        let trimmedGenre = genre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedGenre.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            recommendations = try await LumeyBookRecommendationService.shared.fetchRecommendations(for: trimmedGenre)

            if recommendations.isEmpty {
                errorMessage = "No recommendations found. Try a specific book title instead of a broad genre."
            }
        } catch {
            print("❌ Recommendation Error:", error)

            let nsError = error as NSError
            print("❌ Recommendation Error Domain:", nsError.domain)
            print("❌ Recommendation Error Code:", nsError.code)
            print("❌ Recommendation Error Description:", nsError.localizedDescription)

            errorMessage = nsError.localizedDescription
        }

        isLoading = false
    }
}
