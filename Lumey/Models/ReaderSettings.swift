//
//  ReaderSettings.swift
//  Lumey
//

import Foundation
import UIKit
import SwiftData
import ReadiumShared
import ReadiumNavigator

// MARK: - Reader Theme

enum ReaderTheme: String, Codable, CaseIterable, Identifiable {
    case white = "White"
    case sepia = "Sepia"
    case gray = "Gray"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var backgroundColor: UIColor {
        switch self {
        case .white: return .white
        case .sepia: return UIColor(red: 0.976, green: 0.960, blue: 0.918, alpha: 1.0)
        case .gray: return UIColor(red: 0.188, green: 0.192, blue: 0.200, alpha: 1.0)
        case .dark: return UIColor(red: 0.008, green: 0.012, blue: 0.016, alpha: 1.0)
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .white: return .black
        case .sepia: return UIColor(red: 0.294, green: 0.231, blue: 0.169, alpha: 1.0)
        case .gray: return UIColor(red: 0.850, green: 0.850, blue: 0.860, alpha: 1.0)
        case .dark: return .white
        }
    }
    
    var chromeBackgroundColor: UIColor {
        switch self {
        case .white: return UIColor(red: 0.965, green: 0.965, blue: 0.970, alpha: 1.0)
        case .sepia: return UIColor(red: 0.945, green: 0.925, blue: 0.880, alpha: 1.0)
        case .gray: return UIColor(red: 0.145, green: 0.149, blue: 0.157, alpha: 1.0)
        case .dark: return UIColor(red: 0.008, green: 0.012, blue: 0.016, alpha: 1.0)
        }
    }
    
    var chromeBorderColor: UIColor {
        switch self {
        case .white: return UIColor.black.withAlphaComponent(0.08)
        case .sepia: return UIColor.brown.withAlphaComponent(0.12)
        case .gray: return UIColor.white.withAlphaComponent(0.08)
        case .dark: return UIColor.white.withAlphaComponent(0.05)
        }
    }
    
    var chromeTextColor: UIColor {
        switch self {
        case .white: return .black
        case .sepia: return UIColor(red: 0.294, green: 0.231, blue: 0.169, alpha: 1.0)
        case .gray, .dark: return .white
        }
    }
    
    var swatchColor: UIColor {
        backgroundColor
    }
    
    var swatchBorderColor: UIColor {
        switch self {
        case .white: return UIColor.black.withAlphaComponent(0.15)
        case .sepia: return UIColor.brown.withAlphaComponent(0.3)
        case .gray: return UIColor.white.withAlphaComponent(0.2)
        case .dark: return UIColor.white.withAlphaComponent(0.15)
        }
    }
    
    var isDark: Bool {
        self == .gray || self == .dark
    }
    
    var epubPreferencesTheme: ReadiumNavigator.Theme? {
        switch self {
        case .white: return .light
        case .sepia: return .sepia
        case .gray: return nil
        case .dark: return .dark
        }
    }
    
    var readiumBackgroundColor: Color? {
        switch self {
        case .white: return Color(hex: "#FFFFFF")
        case .sepia: return Color(hex: "#EDDBCB")
        case .gray: return Color(hex: "#303136")
        case .dark: return Color(hex: "#020304")
        }
    }

    var readiumTextColor: Color? {
        switch self {
        case .white: return Color(hex: "#111111")
        case .sepia: return Color(hex: "#3B2F22")
        case .gray: return Color(hex: "#D9D9DB")
        case .dark: return Color(hex: "#FFFFFF")
        }
    }
}

// MARK: - Reader Font

enum ReaderFont: String, Codable, CaseIterable, Identifiable {
    case original = "Original"
    case georgia = "Georgia"
    case palatino = "Palatino"
    case iowanOldStyle = "Iowan Old Style"
    case athelas = "Athelas"
    case seravek = "Seravek"
    case helveticaNeue = "Helvetica Neue"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var fontFamily: FontFamily? {
        switch self {
        case .original: return nil
        case .georgia: return .georgia
        case .palatino: return .palatino
        case .iowanOldStyle: return .iowanOldStyle
        case .athelas: return .athelas
        case .seravek: return .seravek
        case .helveticaNeue: return .helveticaNeue
        }
    }
    
    var uiFontName: String? {
        switch self {
        case .original: return nil
        case .georgia: return "Georgia"
        case .palatino: return "Palatino"
        case .iowanOldStyle: return "IowanOldStyle-Roman"
        case .athelas: return "Athelas"
        case .seravek: return "Seravek"
        case .helveticaNeue: return "HelveticaNeue"
        }
    }
}

// MARK: - SwiftData Model

@Model
final class ReaderSettings {
    var id: UUID = UUID()
    var themeRawValue: String = ReaderTheme.dark.rawValue
    var fontRawValue: String = ReaderFont.original.rawValue
    var fontSize: Double = 1.0
    var lineHeight: Double = 1.4
    var pageMargins: Double = 1.0
    var updatedAt: Date = Date()
    
    init(
        theme: ReaderTheme = .dark,
        font: ReaderFont = .original,
        fontSize: Double = 1.0,
        lineHeight: Double = 1.4,
        pageMargins: Double = 1.0
    ) {
        self.id = UUID()
        self.themeRawValue = theme.rawValue
        self.fontRawValue = font.rawValue
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.pageMargins = pageMargins
        self.updatedAt = Date()
    }
}

extension ReaderSettings {
    var theme: ReaderTheme {
        get { ReaderTheme(rawValue: themeRawValue) ?? .dark }
        set {
            themeRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    var font: ReaderFont {
        get { ReaderFont(rawValue: fontRawValue) ?? .original }
        set {
            fontRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    func buildPreferences() -> EPUBPreferences {
        EPUBPreferences(
            backgroundColor: theme.readiumBackgroundColor,
            fontFamily: font.fontFamily,
            fontSize: fontSize,
            lineHeight: lineHeight,
            pageMargins: pageMargins,
            textColor: theme.readiumTextColor,
            theme: theme.epubPreferencesTheme ?? .dark
        )
    }
}
