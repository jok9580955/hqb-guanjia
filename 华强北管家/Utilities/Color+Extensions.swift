import SwiftUI

// MARK: - Hex Color Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 128, 128, 128)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - App Theme

enum AppTheme {
    // Backgrounds
    static let background = Color(hex: "0D1117")
    static let secondaryBackground = Color(hex: "161B22")
    static let cardBackground = Color(hex: "21262D")
    static let elevatedBackground = Color(hex: "2D333B")
    static let border = Color(hex: "30363D")

    // Accent Colors
    static let neonGreen = Color(hex: "00FF9F")
    static let accentGreen = Color(hex: "39D353")
    static let techBlue = Color(hex: "58A6FF")
    static let warningOrange = Color(hex: "F0883E")
    static let dangerRed = Color(hex: "F85149")
    static let purple = Color(hex: "BC8CFF")
    static let cyan = Color(hex: "39D2C0")

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "8B949E")
    static let textTertiary = Color(hex: "6E7681")

    // Gradients
    static let greenGradient = LinearGradient(
        colors: [Color(hex: "238636"), Color(hex: "39D353")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let blueGradient = LinearGradient(
        colors: [Color(hex: "1F6FEB"), Color(hex: "58A6FF")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let orangeGradient = LinearGradient(
        colors: [Color(hex: "BD561D"), Color(hex: "F0883E")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let purpleGradient = LinearGradient(
        colors: [Color(hex: "8B5CF6"), Color(hex: "BC8CFF")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}
