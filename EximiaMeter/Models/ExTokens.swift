import SwiftUI

// ═══════════════════════════════════════════════════════════
// ExTokens — Design Tokens exímIA
// Fonte: design-system/design-system/TokensSection.tsx
// ═══════════════════════════════════════════════════════════

enum ExTokens {

    // ─── CORES ────────────────────────────────────────────
    enum Colors {
        // Backgrounds
        static let backgroundPrimary = Color(hex: "#0A0A0A")
        static let backgroundDeep = Color(hex: "#050505")
        static let backgroundCard = Color(hex: "#121214")
        static let backgroundElevated = Color(hex: "#1F1F22")
        static let surface = Color(hex: "#151518")

        // Accent (Regra dos 8%)
        static let accentPrimary = Color(hex: "#F59E0B")
        static let accentPrimaryHover = Color(hex: "#D97706")
        static let accentSecondary = Color(hex: "#8B5CF6")
        static let accentCyan = Color(hex: "#22D3EE")

        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "#A1A1AA")
        static let textTertiary = Color(hex: "#71717A")
        static let textMuted = Color(hex: "#52525B")
        static let textPlaceholder = Color(hex: "#52525B")

        // Borders
        static let borderDefault = Color(hex: "#27272A")
        static let borderHover = Color(hex: "#3F3F46")
        static let borderSubtle = Color(hex: "#1F1F22")

        // Status
        static let statusSuccess = Color(hex: "#10B981")
        static let statusWarning = Color(hex: "#EAB308")
        static let statusCritical = Color(hex: "#EF4444")

        // Semantic
        static let destructive = Color(hex: "#E11D48")
        static let destructiveBg = Color(hex: "#4C0519").opacity(0.3)
    }

    // Escala Monocromática (zinc)
    enum Zinc {
        static let _50 = Color(hex: "#FAFAFA")
        static let _100 = Color(hex: "#F4F4F5")
        static let _200 = Color(hex: "#E4E4E7")
        static let _300 = Color(hex: "#D4D4D8")
        static let _400 = Color(hex: "#A1A1AA")
        static let _500 = Color(hex: "#71717A")
        static let _600 = Color(hex: "#52525B")
        static let _700 = Color(hex: "#3F3F46")
        static let _800 = Color(hex: "#27272A")
        static let _900 = Color(hex: "#18181B")
        static let _950 = Color(hex: "#09090B")
    }

    // ─── TIPOGRAFIA ───────────────────────────────────────
    enum Typography {
        static let menuBarFont = Font.system(size: 12, weight: .bold, design: .monospaced)

        static let title = Font.system(size: 14, weight: .bold)
        static let subtitle = Font.system(size: 12, weight: .semibold)
        static let body = Font.system(size: 12, weight: .regular)
        static let caption = Font.system(size: 10, weight: .medium)
        static let captionMono = Font.system(size: 10, weight: .medium, design: .monospaced)
        static let micro = Font.system(size: 9, weight: .bold, design: .monospaced)
        static let label = Font.system(size: 10, weight: .bold)

        static let settingsTitle = Font.system(size: 16, weight: .bold)
        static let settingsBody = Font.system(size: 13, weight: .regular)
        static let settingsLabel = Font.system(size: 11, weight: .medium)
    }

    // ─── BORDER RADIUS ────────────────────────────────────
    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 24
        static let full: CGFloat = 9999
    }

    // ─── ESPAÇAMENTO ──────────────────────────────────────
    enum Spacing {
        static let _2: CGFloat = 2
        static let _4: CGFloat = 4
        static let _6: CGFloat = 6
        static let _8: CGFloat = 8
        static let _12: CGFloat = 12
        static let _16: CGFloat = 16
        static let _24: CGFloat = 24
        static let _32: CGFloat = 32
        static let _48: CGFloat = 48
        static let _64: CGFloat = 64

        static let cardPadding: CGFloat = 24
        static let popoverPadding: CGFloat = 16
        static let sectionGap: CGFloat = 16
    }
}

// ─── COLOR HEX EXTENSION ─────────────────────────────────

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String? {
        guard let components = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = Int(components.redComponent * 255)
        let g = Int(components.greenComponent * 255)
        let b = Int(components.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
