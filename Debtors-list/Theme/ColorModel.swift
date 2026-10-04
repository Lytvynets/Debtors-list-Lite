
import SwiftUI
import UIKit


extension Color {
    static let brand = Color(light: 0x5B3CDB, dark: 0x8F77FF)
    static let brandBright = Color(hex: 0x8B6CFF)

    static let owedToMe = Color(light: 0x0F8F5B, dark: 0x34D399)
    static let iOwe = Color(light: 0xD7374A, dark: 0xFF6B7A)

    static let owedToMeBright = Color(hex: 0x4ADE9B)
    static let iOweBright = Color(hex: 0xFF7A88)

    static let inkTop = Color(hex: 0x1C1245)
    static let inkBottom = Color(hex: 0x0B0720)
    static let inkGlow = Color(hex: 0x6D4BFF)

    static let premiumGold = Color(hex: 0xF5C451)

    static let appBackground = Color(light: 0xEFECFA, dark: 0x0E0A22)
    static let appSurface = Color(light: 0xFCFBFF, dark: 0x1C1742)
    static let appFill = Color(light: 0xE3DEF7, dark: 0x2B2457)

    static func avatarTint(for name: String) -> Color {
        let palette: [Color] = [
            Color(light: 0x5B3CDB, dark: 0x9C86FF),
            Color(light: 0x0E7C86, dark: 0x3CC7D3),
            Color(light: 0xB4541A, dark: 0xF59E5B),
            Color(light: 0x2F6FDB, dark: 0x6FA3FF),
            Color(light: 0xA3367A, dark: 0xF07AC0),
            Color(light: 0x4E7A1F, dark: 0x9BD65A)
        ]
        let seed = name.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7FFFFFFF }
        return palette[seed % palette.count]
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}


extension View {
    func themedListBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.appBackground)
    }
}


enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
