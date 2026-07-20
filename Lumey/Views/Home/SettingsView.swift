//
//  SettingsView.swift
//  Lumey
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct LumeyLibraryExportDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.lumeyCSV]
    }

    var csv: String

    init(csv: String = "") {
        self.csv = csv
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let csv = String(data: data, encoding: .utf8) {
            self.csv = csv
        } else {
            self.csv = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(csv.utf8))
    }
}

private struct SettingsNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var books: [Book]

    @State private var showGoodreadsImporter = false
    @State private var showLumeyExporter = false
    @State private var exportDocument = LumeyLibraryExportDocument()
    @State private var notice: SettingsNotice?

    private var syncedBooks: [Book] {
        books.filter { $0.deletedAt == nil }
    }

    private var activeBooks: [Book] {
        syncedBooks.filter { !$0.isArchived }
    }

    private var finishedBooks: [Book] {
        activeBooks.filter { $0.status == .finished }
    }

    private var readingBooks: [Book] {
        activeBooks.filter { $0.status == .reading }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LumeyBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        commandCenter
                        libraryPulse
                        dataVault
                        cloudKitCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 140)
                }
            }
            .navigationBarHidden(true)
            .fileImporter(
                isPresented: $showGoodreadsImporter,
                allowedContentTypes: [.lumeyCSV, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleGoodreadsImport(result)
            }
            .fileExporter(
                isPresented: $showLumeyExporter,
                document: exportDocument,
                contentType: .lumeyCSV,
                defaultFilename: exportFilename
            ) { result in
                handleExportResult(result)
            }
            .alert(item: $notice) { notice in
                Alert(
                    title: Text(notice.title),
                    message: Text(notice.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

// MARK: - Sections

private extension SettingsView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Your Lumey control room")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var commandCenter: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    Image("settingswavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundStyle(.black)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(LGradients.header))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Library Ops")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("\(activeBooks.count) active books moving through iCloud")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    SettingsSignalPill(title: "Reading", value: "\(readingBooks.count)")
                    SettingsSignalPill(title: "Finished", value: "\(finishedBooks.count)")
                    SettingsSignalPill(title: "Saved", value: "\(syncedBooks.count)")
                }
            }
        }
    }

    var libraryPulse: some View {
        HStack(spacing: 12) {
            SettingsMetricCard(
                title: "Active",
                value: "\(activeBooks.count)",
                iconName: "books"
            )

            SettingsMetricCard(
                title: "Archive",
                value: "\(syncedBooks.count - activeBooks.count)",
                iconName: "folderfill"
            )
        }
    }

    var dataVault: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Data Vault")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            SettingsActionCard(
                title: "Import Goodreads",
                subtitle: "Create Lumey book cards from a Goodreads CSV export",
                iconName: "upload",
                gradientColors: [LColors.gradientBlue, LColors.gradientPurple]
            ) {
                showGoodreadsImporter = true
            }

            SettingsActionCard(
                title: "Export Lumey",
                subtitle: "Save your Lumey library as a clean CSV file",
                iconName: "exportfill",
                gradientColors: [LColors.gradientYellow, LColors.gradientBlue]
            ) {
                prepareLumeyExport()
            }
        }
    }

    var cloudKitCard: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 14) {
                Image("cloudmind")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().strokeBorder(LColors.glassBorder, lineWidth: 1))

                VStack(alignment: .leading, spacing: 5) {
                    Text("CloudKit Library")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Imported books are saved as normal Lumey library entries, so they use the app's existing private iCloud sync.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Actions

private extension SettingsView {
    var exportFilename: String {
        "Lumey-Library-\(Self.filenameDateFormatter.string(from: Date()))"
    }

    func handleGoodreadsImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let importResult = try LibraryImportExportService.importGoodreadsBooks(
                from: url,
                existingBooks: books
            )

            for book in importResult.books {
                modelContext.insert(book)
            }

            try modelContext.save()

            notice = SettingsNotice(
                title: "Goodreads Imported",
                message: "Created \(importResult.importedCount) Lumey book cards. Skipped \(importResult.skippedDuplicates) duplicates and \(importResult.skippedInvalidRows) rows without enough book data."
            )
        } catch {
            notice = SettingsNotice(
                title: "Import Failed",
                message: error.localizedDescription
            )
        }
    }

    func prepareLumeyExport() {
        do {
            let csv = try LibraryImportExportService.lumeyExportCSV(from: books)
            exportDocument = LumeyLibraryExportDocument(csv: csv)
            showLumeyExporter = true
        } catch {
            notice = SettingsNotice(
                title: "Export Failed",
                message: error.localizedDescription
            )
        }
    }

    func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            notice = SettingsNotice(
                title: "Lumey Exported",
                message: "Your library CSV is ready."
            )
        case .failure(let error):
            notice = SettingsNotice(
                title: "Export Failed",
                message: error.localizedDescription
            )
        }
    }

    static var filenameDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}

// MARK: - Components

private struct SettingsSignalPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct SettingsMetricCard: View {
    let title: String
    let value: String
    let iconName: String

    var body: some View {
        GlassCard(cornerRadius: 20, padding: 16) {
            HStack(spacing: 12) {
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.06)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(value)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(title)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

private struct SettingsActionCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let gradientColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.black)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image("chevright")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .foregroundStyle(LColors.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LColors.glassSurface2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                LColors.gradientBlue.opacity(0.72),
                                LColors.gradientPurple.opacity(0.72),
                                Color.white.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
