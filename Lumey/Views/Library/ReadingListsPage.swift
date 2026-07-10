//
//  ReadingListsPage.swift
//  Lumey
//

import SwiftUI
import SwiftData

struct ReadingListsPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Query(sort: \ReadingList.updatedAt, order: .reverse)
    private var allLists: [ReadingList]
    
    @Query(sort: \Book.lastUpdated, order: .reverse)
    private var allBooks: [Book]
    
    @State private var showingAddSheet = false
    @State private var selectedList: ReadingList?
    @State private var editingList: ReadingList?
    
    private var activeLists: [ReadingList] {
        allLists.filter { $0.status != .archived }
    }
    
    private var archivedLists: [ReadingList] {
        allLists.filter { $0.status == .archived }
    }
    
    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    topBar
                    
                    if activeLists.isEmpty && archivedLists.isEmpty {
                        emptyState
                    } else {
                        if !activeLists.isEmpty {
                            activeSection
                        }
                        
                        if !archivedLists.isEmpty {
                            archivedSection
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .adaptivePresentation(isPresented: $showingAddSheet, useFullScreenCover: horizontalSizeClass == .regular) {
            AddEditReadingListSheet(list: nil)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .adaptivePresentation(item: $selectedList, useFullScreenCover: horizontalSizeClass == .regular) { list in
            ReadingListDetailSheet(list: list)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .adaptivePresentation(item: $editingList, useFullScreenCover: horizontalSizeClass == .regular) { list in
            AddEditReadingListSheet(list: list)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(alignment: .top) {
            Text("Reading Lists")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 10) {
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

                Button {
                    showingAddSheet = true
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
            }
        }
    }
    
    // MARK: - Active Section
    
    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Active")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("\(activeLists.count)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(LColors.glassSurface2))
            }
            
            LazyVStack(spacing: 12) {
                ForEach(activeLists) { list in
                    ReadingListCard(list: list, allBooks: allBooks) {
                        selectedList = list
                    }
                }
            }
        }
    }
    
    // MARK: - Archived Section
    
    private var archivedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Archived")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
            
            LazyVStack(spacing: 12) {
                ForEach(archivedLists) { list in
                    ReadingListCard(list: list, allBooks: allBooks) {
                        selectedList = list
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 14) {
                Image("books")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(LGradients.header)
                
                Text("No reading lists yet")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Create curated collections like Summer TBR, Cozy Reads, or Books to Reread.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button {
                    showingAddSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image("addwavy")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        
                        Text("Create a List")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule(style: .continuous).fill(LGradients.header))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
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

// MARK: - Reading List Card

struct ReadingListCard: View {
    let list: ReadingList
    let allBooks: [Book]
    let onTap: () -> Void
    
    private var effectiveCompletedCount: Int {
        let listBookIDs = Set(list.items.map { $0.bookID })

        let manuallyCompletedIDs = Set(
            list.items
                .filter { $0.isCompleted }
                .map { $0.bookID }
        )

        let finishedBookIDs = Set(
            allBooks
                .filter { $0.status == .finished }
                .map { $0.id }
        )

        return listBookIDs.filter { bookID in
            manuallyCompletedIDs.contains(bookID) || finishedBookIDs.contains(bookID)
        }.count
    }

    private var effectiveProgressValue: Double {
        guard list.bookCount > 0 else { return 0 }
        return Double(effectiveCompletedCount) / Double(list.bookCount)
    }

    private var effectiveProgressText: String {
        "\(effectiveCompletedCount) of \(list.bookCount) read"
    }
    
    var body: some View {
        Button(action: onTap) {
            GlassCard {
                HStack(spacing: 14) {
                    Image(list.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(LGradients.header)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                        .overlay(Circle().strokeBorder(LGradients.header, lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(list.displayTitle)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        if !list.listDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(list.listDescription)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                                .lineLimit(2)
                        }

                        HStack(spacing: 8) {
                            Text(effectiveProgressText)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                            
                            if let days = list.daysRemaining {
                                Text("•")
                                    .font(.system(size: 12))
                                    .foregroundStyle(LColors.textSecondary)
                                
                                Text(days >= 0 ? "\(days)d left" : "Overdue")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(days >= 0 ? LColors.textSecondary : LColors.danger)
                            }
                        }
                        
                        if list.bookCount > 0 {
                            DottedGoalProgressBar(value: effectiveProgressValue)
                                .frame(height: 8)
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    Image("chevright")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
