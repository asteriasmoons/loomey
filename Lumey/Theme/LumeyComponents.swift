//
//  LumeyComponents.swift
//  Lumey
//

import SwiftUI

// MARK: - Alternative Lumey Background

struct LumeyBackgroundAlt: View {
    var body: some View {
        ZStack {
            LColors.bgSoft
                .ignoresSafeArea()
            
            LGradients.bgPurple
                .blendMode(.screen)
                .ignoresSafeArea()
            
            LGradients.bgCyan
                .blendMode(.screen)
                .ignoresSafeArea()
            
            LGradients.bgYellow
                .blendMode(.screen)
                .ignoresSafeArea()
            
            LinearGradient(
                colors: [
                    Color.black.opacity(0.22),
                    Color.clear,
                    Color.black.opacity(0.34)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            Rectangle()
                .fill(Color.white.opacity(0.015))
                .blendMode(.softLight)
                .ignoresSafeArea()
        }
    }
}

// MARK: - DELETE CONFIRMATION DIALOGUE

struct LumeyAlertConfirm: ViewModifier {
    @Binding var isPresented: Bool

    let title: String
    let message: String
    let confirmTitle: String
    let confirmRole: ButtonRole?
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button(confirmTitle, role: confirmRole) {
                    onConfirm()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(message)
            }
    }
}

extension View {
    func lumeyAlertConfirm(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String = "Delete",
        confirmRole: ButtonRole? = .destructive,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.modifier(
            LumeyAlertConfirm(
                isPresented: isPresented,
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                confirmRole: confirmRole,
                onConfirm: onConfirm
            )
        )
    }
}

// MARK: - Gradient Title

struct GradientTitle: View {
    let text: String
    var size: CGFloat = 28
    var fontName: String = "LilyScriptOne-Regular"

    var body: some View {
        Text(text)
            .font(.custom(fontName, size: size))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        LColors.gradientBlue,
                        LColors.gradientPurple
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(
                color: LColors.gradientPurple.opacity(0.18),
                radius: 8,
                y: 4
            )
    }
}

// MARK: - Lumey Popup (Reusable)

struct LumeyPopup<Header: View, Content: View, Footer: View>: View {
    let onClose: () -> Void
    let width: CGFloat
    let heightRatio: CGFloat
    
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.62)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            onClose()
                        }
                    }

                VStack(alignment: .leading, spacing: 18) {
                    header()

                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 14) {
                            content()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .scrollBounceBehavior(.basedOnSize)

                    footer()
                }
                .padding(22)
                .frame(
                    width: max(
                        0,
                        min(
                            proxy.size.width.isFinite
                            ? proxy.size.width - 40
                            : width,
                            width
                        )
                    ),
                    alignment: .topLeading
                )
                .frame(
                    maxHeight: proxy.size.height * heightRatio,
                    alignment: .topLeading
                )
                .background(
                    ZStack {
                        LumeyBackground()

                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.black.opacity(0.28))

                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        LColors.gradientPurple.opacity(0.10),
                                        LColors.gradientBlue.opacity(0.06)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    LColors.gradientBlue,
                                    LColors.gradientPurple
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.25
                        )
                )
                .shadow(
                    color: LColors.gradientPurple.opacity(0.18),
                    radius: 18,
                    y: 8
                )
                .shadow(
                    color: .black.opacity(0.35),
                    radius: 24,
                    y: 12
                )
                .transition(
                    .opacity.combined(with: .scale(scale: 0.96))
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - Lumey Background

struct LumeyBackground: View {
    var body: some View {
        LColors.bg
            .ignoresSafeArea()
    }
}

// MARK: - Gradient Time Drum Picker

struct LumeyGradientTimeDrumPicker: View {
    @Binding var hour: Int
    @Binding var minute: Int
    
    @State private var displayHour: Int = 9
    @State private var meridiem: String = "AM"
    @State private var isSyncingFromStoredHour = false
    
    private let meridiems = ["AM", "PM"]
    
    private var formattedPreview: String {
        String(format: "%d:%02d %@", displayHour, minute, meridiem)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(LGradients.header)
                
                Text(formattedPreview)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(LColors.glassSurface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [LColors.gradientBlue, LColors.gradientPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LColors.glassSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        LColors.gradientBlue.opacity(0.10),
                                        LColors.gradientPurple.opacity(0.14),
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
                                    colors: [LColors.gradientBlue, LColors.gradientPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                VStack(spacing: 0) {
                    Spacer()
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    LColors.gradientBlue.opacity(0.20),
                                    LColors.gradientPurple.opacity(0.20)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            LColors.gradientBlue.opacity(0.55),
                                            LColors.gradientPurple.opacity(0.55)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    Spacer()
                }
                .padding(.horizontal, 12)
                
                HStack(spacing: 6) {
                    Picker("Hour", selection: $displayHour) {
                        ForEach(1...12, id: \.self) { value in
                            Text("\(value)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()
                    
                    Text(":")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                    
                    Picker("Minute", selection: $minute) {
                        ForEach(0..<60, id: \.self) { value in
                            Text(String(format: "%02d", value))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()
                    
                    Picker("AM PM", selection: $meridiem) {
                        ForEach(meridiems, id: \.self) { value in
                            Text(value)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 138)
        }
        .onAppear { syncDisplayValuesFromStoredHour() }
        .onChange(of: displayHour) { syncStoredHour() }
        .onChange(of: meridiem) { syncStoredHour() }
        .onChange(of: hour) { syncDisplayValuesFromStoredHour() }
    }
    
    private func syncDisplayValuesFromStoredHour() {
        isSyncingFromStoredHour = true
        let normalizedHour = max(0, min(23, hour))
        if normalizedHour == 0 {
            displayHour = 12; meridiem = "AM"
        } else if normalizedHour < 12 {
            displayHour = normalizedHour; meridiem = "AM"
        } else if normalizedHour == 12 {
            displayHour = 12; meridiem = "PM"
        } else {
            displayHour = normalizedHour - 12; meridiem = "PM"
        }
        isSyncingFromStoredHour = false
    }
    
    private func syncStoredHour() {
        guard !isSyncingFromStoredHour else { return }
        if meridiem == "AM" {
            hour = displayHour == 12 ? 0 : displayHour
        } else {
            hour = displayHour == 12 ? 12 : displayHour + 12
        }
    }
}

// MARK: - Dotted Gradient Spinner

struct LumeyDottedGradientSpinner: View {
    var size: CGFloat = 58
    var dotCount: Int = 14

    @State private var rotation = 0.0

    private var dotSize: CGFloat {
        max(5, size * 0.12)
    }

    private var radius: CGFloat {
        (size - dotSize) / 2
    }

    var body: some View {
        ZStack {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(LGradients.header)
                    .frame(width: dotSize, height: dotSize)
                    .opacity(dotOpacity(for: index))
                    .shadow(color: LColors.gradientBlue.opacity(0.22), radius: 5)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(index) / Double(dotCount) * 360))
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            rotation = 0

            withAnimation(.linear(duration: 0.95).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        .accessibilityLabel("Loading")
    }

    private func dotOpacity(for index: Int) -> Double {
        let progress = Double(index) / Double(max(dotCount - 1, 1))
        return 0.28 + (progress * 0.72)
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = LSpacing.cardPadding
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LColors.glassSurface2)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        LColors.gradientBlue.opacity(0.18),
                                        LColors.gradientPurple.opacity(0.22),
                                        Color.white.opacity(0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        LColors.gradientBlue.opacity(0.92),
                                        LColors.gradientPurple.opacity(0.92),
                                        Color.white.opacity(0.38)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.05
                            )
                    }
            }
            .shadow(color: LColors.gradientBlue.opacity(0.18), radius: 16, y: 8)
            .shadow(color: LColors.gradientPurple.opacity(0.14), radius: 18, y: 10)
    }
}

// MARK: - Completion Banner

struct LumeyCompletionBanner: View {
    let message: String
    var isShowing: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image("checkwavy")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(.white)

            Text(message)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(LGradients.header)
                .shadow(color: LColors.gradientPurple.opacity(0.4), radius: 16, y: 6)
        )
        .opacity(isShowing ? 1 : 0)
        .offset(y: isShowing ? 0 : -20)
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: isShowing)
    }
}

extension View {
    func completionBanner(isShowing: Bool, message: String = "Done!") -> some View {
        self.overlay(alignment: .top) {
            LumeyCompletionBanner(message: message, isShowing: isShowing)
                .padding(.top, 16)
                .zIndex(999)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LumeyBackground()

        GlassCard {
            VStack(spacing: 10) {
                Text("Lumey")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(LGradients.header)

                Text("Glass card preview")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
        }
        .padding(.horizontal, 24)
    }
}
