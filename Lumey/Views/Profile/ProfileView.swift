//
//  ProfileView.swift
//  Lumey
//

import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
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

    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var showingSignInSheet = false

    private var user: AuthUser? {
        appState.currentUser ?? users.first
    }

    private var isSignedIn: Bool {
        appState.currentUser != nil
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
        statsRecords.first
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
        .onAppear { loadSavedPhoto() }
        .adaptivePresentation(isPresented: $showingSignInSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            SignInView()
                .environmentObject(appState)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .preferredColorScheme(.dark)
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
}
