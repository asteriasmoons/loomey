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
    case berry = "Berry"
    case slate = "Slate"
    case cocoa = "Dark"
    case plum = "Plum"
    case teal = "Teal"
    case aqua = "Aqua"
    case taupe = "Taupe"
    case lilac = "Lilac"
    case blush = "Blush"
    case paper = "Paper"
    
    var id: String { rawValue }
    
    var backgroundColor: UIColor {
        switch self {
        case .berry: return UIColor(hex: "#82245f")
        case .slate: return UIColor(hex: "#1c1e22")
        case .cocoa: return UIColor(hex: "#41383a")
        case .plum: return UIColor(hex: "#42305d")
        case .teal: return UIColor(hex: "#164961")
        case .aqua: return UIColor(hex: "#b6e3e9")
        case .taupe: return UIColor(hex: "#85766a")
        case .lilac: return UIColor(hex: "#8f77a8")
        case .blush: return UIColor(hex: "#f582b4")
        case .paper: return UIColor(hex: "#ecedef")
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .berry: return UIColor(hex: "#FCE7F4")
        case .slate: return UIColor(hex: "#EEF5F3")
        case .cocoa: return UIColor(hex: "#F4ECEC")
        case .plum: return UIColor(hex: "#EFE7FF")
        case .teal: return UIColor(hex: "#DFF9F7")
        case .aqua: return UIColor(hex: "#07383E")
        case .taupe: return UIColor(hex: "#2E2824")
        case .lilac: return UIColor(hex: "#2F2439")
        case .blush: return UIColor(hex: "#4B1731")
        case .paper: return UIColor(hex: "#202124")
        }
    }
    
    var chromeBackgroundColor: UIColor {
        backgroundColor
    }
    
    var chromeBorderColor: UIColor {
        textColor.withAlphaComponent(isDark ? 0.16 : 0.20)
    }
    
    var chromeTextColor: UIColor {
        textColor
    }
    
    var swatchColor: UIColor {
        backgroundColor
    }
    
    var swatchBorderColor: UIColor {
        textColor.withAlphaComponent(isDark ? 0.34 : 0.30)
    }
    
    var isDark: Bool {
        switch self {
        case .berry, .slate, .cocoa, .plum, .teal:
            return true
        case .aqua, .taupe, .lilac, .blush, .paper:
            return false
        }
    }
    
    var epubPreferencesTheme: ReadiumNavigator.Theme? {
        isDark ? .dark : .light
    }
    
    var readiumBackgroundColor: Color? {
        Color(hex: backgroundHex)
    }

    var readiumTextColor: Color? {
        Color(hex: textHex)
    }

    private var backgroundHex: String {
        switch self {
        case .berry: return "#82245f"
        case .slate: return "#1c1e22"
        case .cocoa: return "#41383a"
        case .plum: return "#42305d"
        case .teal: return "#164961"
        case .aqua: return "#b6e3e9"
        case .taupe: return "#85766a"
        case .lilac: return "#8f77a8"
        case .blush: return "#f582b4"
        case .paper: return "#ecedef"
        }
    }

    private var textHex: String {
        switch self {
        case .berry: return "#FCE7F4"
        case .slate: return "#EEF5F3"
        case .cocoa: return "#F4ECEC"
        case .plum: return "#EFE7FF"
        case .teal: return "#DFF9F7"
        case .aqua: return "#07383E"
        case .taupe: return "#2E2824"
        case .lilac: return "#2F2439"
        case .blush: return "#4B1731"
        case .paper: return "#202124"
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
    case hachiMaruPop = "Hachi Maru Pop"
    case montserrat = "Montserrat"
    case quicksand = "Quicksand"
    case baskerville = "Baskerville"
    case charter = "Charter"
    case cochin = "Cochin"
    case timesNewRoman = "Times New Roman"
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
        case .hachiMaruPop: return FontFamily(rawValue: "Hachi Maru Pop")
        case .montserrat: return FontFamily(rawValue: "Montserrat")
        case .quicksand: return FontFamily(rawValue: "Quicksand")
        case .baskerville: return FontFamily(rawValue: "Baskerville")
        case .charter: return FontFamily(rawValue: "Charter")
        case .cochin: return FontFamily(rawValue: "Cochin")
        case .timesNewRoman: return FontFamily(rawValue: "Times New Roman")
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
        case .hachiMaruPop: return "HachiMaruPop-Regular"
        case .montserrat: return "Montserrat-Regular"
        case .quicksand: return "Quicksand-Regular"
        case .baskerville: return "Baskerville"
        case .charter: return "Charter-Roman"
        case .cochin: return "Cochin"
        case .timesNewRoman: return "TimesNewRomanPSMT"
        case .seravek: return "Seravek"
        case .helveticaNeue: return "HelveticaNeue"
        }
    }
}

// MARK: - SwiftData Model

@Model
final class ReaderSettings {
    var id: UUID = UUID()
    var themeRawValue: String = ReaderTheme.cocoa.rawValue
    var fontRawValue: String = ReaderFont.original.rawValue
    var fontSize: Double = 1.0
    var lineHeight: Double = 1.4
    var pageMargins: Double = 0.6
    var letterSpacing: Double = 0.0
    var wordSpacing: Double = 0.0
    var paragraphSpacing: Double = 0.0
    var isJustified: Bool = false
    var updatedAt: Date = Date()

    init(
        theme: ReaderTheme = .cocoa,
        font: ReaderFont = .original,
        fontSize: Double = 1.0,
        lineHeight: Double = 1.4,
        pageMargins: Double = 0.6,
        letterSpacing: Double = 0.0,
        wordSpacing: Double = 0.0,
        paragraphSpacing: Double = 0.0,
        isJustified: Bool = false
    ) {
        self.id = UUID()
        self.themeRawValue = theme.rawValue
        self.fontRawValue = font.rawValue
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.pageMargins = pageMargins
        self.letterSpacing = letterSpacing
        self.wordSpacing = wordSpacing
        self.paragraphSpacing = paragraphSpacing
        self.isJustified = isJustified
        self.updatedAt = Date()
    }
}

extension ReaderSettings {
    var theme: ReaderTheme {
        get { ReaderTheme(rawValue: themeRawValue) ?? .cocoa }
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
    
    func buildPreferences(isIPadLayout: Bool = false) -> EPUBPreferences {
        EPUBPreferences(
            backgroundColor: theme.readiumBackgroundColor,
            columnCount: isIPadLayout ? .one : nil,
            fontFamily: font.fontFamily,
            fontSize: fontSize,
            letterSpacing: letterSpacing > 0 ? letterSpacing : nil,
            lineHeight: lineHeight,
            pageMargins: pageMargins,
            paragraphSpacing: paragraphSpacing > 0 ? paragraphSpacing : nil,
            spread: isIPadLayout ? .never : nil,
            textAlign: isJustified ? .justify : nil,
            textColor: theme.readiumTextColor,
            theme: theme.epubPreferencesTheme ?? .dark,
            wordSpacing: wordSpacing > 0 ? wordSpacing : nil
        )
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let r: UInt64
        let g: UInt64
        let b: UInt64
        let a: UInt64

        switch cleaned.count {
        case 3:
            r = (int >> 8) * 17
            g = ((int >> 4) & 0xF) * 17
            b = (int & 0xF) * 17
            a = 255
        case 6:
            r = int >> 16
            g = (int >> 8) & 0xFF
            b = int & 0xFF
            a = 255
        case 8:
            r = int >> 24
            g = (int >> 16) & 0xFF
            b = (int >> 8) & 0xFF
            a = int & 0xFF
        default:
            r = 255
            g = 255
            b = 255
            a = 255
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
