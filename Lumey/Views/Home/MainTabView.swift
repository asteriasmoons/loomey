//
//  MainTabView.swift
//  Lumey
//

import SwiftUI

enum LumeyTab: CaseIterable {
    case home
    case library
    case stats
    case goals
    case sprints
    case buddies
    case profile
    case challenges
    case epubLibrary
    case settings

    static let primaryTabs: [LumeyTab] = [
        .home,
        .library,
        .stats,
        .goals
    ]

    static let overflowTabs: [LumeyTab] = [
        .epubLibrary,
        .sprints,
        .buddies,
        .profile,
        .challenges,
        .settings
    ]

    var icon: String {
        switch self {
        case .home:
            return "houseoutline"
        case .library:
            return "books"
        case .stats:
            return "levelup"
        case .goals:
            return "achievement"
        case .epubLibrary:
            return "bookstack"
        case .sprints:
            return "sparkbolt"
        case .buddies:
            return "groupfill"
        case .profile:
            return "profilewavy"
        case .challenges:
            return "starwavy"
        case .settings:
            return "togglesettings"
        }
    }

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .library:
            return "Books"
        case .stats:
            return "Stats"
        case .goals:
            return "Goals"
        case .epubLibrary:
            return "Library"
        case .sprints:
            return "Sprints"
        case .buddies:
            return "Buddies"
        case .profile:
            return "Profile"
        case .challenges:
            return "Challenges"
        case .settings:
            return "Settings"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: LumeyTab = .home
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LumeyBackground()
                .ignoresSafeArea()

            selectedTabView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: appState.hideTabBar ? 0 : 120)
                }

            if !appState.hideTabBar {
                LumeyTabBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    private var selectedTabView: some View {
        switch selectedTab {
        case .home:
            ReadingHomeView()
        case .library:
            ReadingLibraryView()
        case .stats:
            ReadingStatsView()
        case .goals:
            ReadingGoalsView()
        case .sprints:
            SprintRoomView()
        case .buddies:
            BuddyReadingView()
        case .profile:
            ProfileView()
        case .challenges:
            ChallengesView()
        case .epubLibrary:
            EPUBLibraryView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Floating Tab Bar

struct LumeyTabBar: View {
    @Binding var selectedTab: LumeyTab

    @State private var showMoreTabs = false

    private var primaryTabs: [LumeyTab] {
        LumeyTab.primaryTabs
    }

    private var overflowTabs: [LumeyTab] {
        LumeyTab.overflowTabs
    }

    private var leadingTabs: [LumeyTab] {
        Array(primaryTabs.prefix(2))
    }

    private var trailingTabs: [LumeyTab] {
        Array(primaryTabs.dropFirst(2))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if showMoreTabs && !overflowTabs.isEmpty {
                moreTabsMenu
                    .frame(maxWidth: 280)
                    .padding(.bottom, 116)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }

            HStack(spacing: 10) {
                ForEach(leadingTabs, id: \.self) { tab in
                    tabButton(tab)
                }

                centerAddButton

                ForEach(trailingTabs, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(LColors.bg.opacity(0.88))

                    GlassCard(cornerRadius: 999, padding: 0) {
                        Color.clear
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 42)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: showMoreTabs)
    }

    private func tabButton(_ tab: LumeyTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                selectedTab = tab
                showMoreTabs = false
            }
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(LGradients.header.opacity(0.22))
                        .frame(width: 34, height: 34)
                }

                Image(tab.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(
                        isSelected
                        ? AnyShapeStyle(LGradients.header)
                        : AnyShapeStyle(Color.white.opacity(0.4))
                    )
            }
            .frame(width: 42, height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var centerAddButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                showMoreTabs.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(LGradients.header)
                    .frame(width: 44, height: 44)
                    .shadow(color: LColors.gradientBlue.opacity(0.35), radius: 10, x: 0, y: 5)

                Image("addwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(LColors.bg)
                    .rotationEffect(.degrees(showMoreTabs ? 45 : 0))
            }
            .frame(width: 54, height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(overflowTabs.isEmpty)
        .opacity(overflowTabs.isEmpty ? 0.45 : 1)
    }

    private var moreTabsMenu: some View {
        VStack(spacing: 6) {
            ForEach(overflowTabs, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                        selectedTab = tab
                        showMoreTabs = false
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(tab.icon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(
                                selectedTab == tab
                                ? AnyShapeStyle(LGradients.header)
                                : AnyShapeStyle(LColors.textSecondary)
                            )
                            .frame(width: 34, height: 34)
                            .background(
                                selectedTab == tab ? LColors.glassSurface2 : LColors.glassSurface,
                                in: Circle()
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(LColors.glassBorder, lineWidth: 1)
                            )

                        Text(tab.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textPrimary)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        selectedTab == tab ? LColors.glassSurface2.opacity(0.75) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LColors.bg.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    LColors.gradientBlue.opacity(0.10),
                                    LColors.gradientPurple.opacity(0.08),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    LColors.gradientBlue.opacity(0.75),
                                    LColors.gradientPurple.opacity(0.55),
                                    Color.white.opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.4
                        )
                )
        }
        .shadow(color: .black.opacity(0.24), radius: 22, x: 0, y: 12)
    }
}

// MARK: - Placeholder Tab View

struct PlaceholderTabView: View {
    let icon: String
    let title: String
    var isSF: Bool = false
    
    var body: some View {
        ZStack {
            LumeyBackground()
            
            VStack(spacing: 16) {
                if isSF {
                    Image(systemName: icon)
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    LColors.gradientBlue,
                                    LColors.gradientPurple
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                } else {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    LColors.gradientBlue,
                                    LColors.gradientPurple
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Coming soon")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }
}
