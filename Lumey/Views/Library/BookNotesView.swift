//
//  BookNotesView.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct BookNotesView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showAddSheet = false
    @State private var editingNote: BookNote? = nil
    @State private var selectedNote: BookNote? = nil
    @State private var noteToDelete: BookNote? = nil
    @State private var showDeleteAlert = false

    private var notes: [BookNote] {
        (book.bookNotes ?? []).sorted { $0.dateCreated > $1.dateCreated }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    noteGrid
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddSheet) {
            BookNoteEditorSheet(book: book, note: nil)
        }
        .sheet(item: $editingNote) { note in
            BookNoteEditorSheet(book: book, note: note)
        }
        .sheet(item: $selectedNote) { note in
            BookNoteDetailSheet(note: note)
        }
        .lumeyAlertConfirm(
            isPresented: $showDeleteAlert,
            title: "Delete Note",
            message: "Are you sure you want to delete this note?"
        ) {
            if let note = noteToDelete {
                modelContext.delete(note)
                noteToDelete = nil
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("Notes")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button {
                showAddSheet = true
            } label: {
                Image("addwavy")
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
    }

    private var noteGrid: some View {
        Group {
            if notes.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(notes, id: \.id) { note in
                        noteCard(note)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image("lovedocument")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(LGradients.blue)

                Text("No notes yet")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                Text("Tap + to add your first note")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    private func noteCard(_ note: BookNote) -> some View {
        GlassCard(cornerRadius: 18, padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text(note.content)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineLimit(5)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(note.dateCreated.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)

                HStack {
                    Spacer()

                    Button {
                        editingNote = note
                    } label: {
                        Image("pencil")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(LGradients.blue)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.06))
                                    .overlay(
                                        Circle()
                                            .strokeBorder(LGradients.blue, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        noteToDelete = note
                        showDeleteAlert = true
                    } label: {
                        Image("trash")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(LGradients.blue)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.06))
                                    .overlay(
                                        Circle()
                                            .strokeBorder(LGradients.blue, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onTapGesture {
            selectedNote = note
        }
    }
}

// MARK: - Note Detail Sheet

struct BookNoteDetailSheet: View {
    let note: BookNote
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("Note")
                            .font(.system(size: 22, weight: .black, design: .rounded))
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
                                .foregroundStyle(LGradients.blue)
                                .frame(width: 42, height: 42)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.06))
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(note.content)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.90))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(note.dateCreated.formatted(date: .long, time: .shortened))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Note Editor Sheet

struct BookNoteEditorSheet: View {
    let book: Book
    let note: BookNote?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var content = ""

    private var isEditing: Bool { note != nil }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text(isEditing ? "Edit Note" : "New Note")
                            .font(.system(size: 22, weight: .black, design: .rounded))
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
                                .foregroundStyle(LGradients.blue)
                                .frame(width: 42, height: 42)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.06))
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Note")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)

                            TextEditor(text: $content)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 150)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.04))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(LColors.glassBorder, lineWidth: 1)
                                        )
                                )
                        }
                    }

                    Button {
                        save()
                    } label: {
                        Text(isEditing ? "Save Changes" : "Add Note")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LGradients.blue)
                            )
                    }
                    .buttonStyle(.plain)
                    .opacity(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            if let note {
                content = note.content
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let note {
            note.content = trimmed
            note.lastUpdated = Date()
        } else {
            let newNote = BookNote(content: trimmed, book: book)
            modelContext.insert(newNote)
        }

        dismiss()
    }
}
