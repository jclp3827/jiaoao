import SwiftUI

enum TunerTheme {
    static let ink = Color(red: 0.12, green: 0.10, blue: 0.09)
    static let panel = Color(red: 0.17, green: 0.15, blue: 0.13)
    static let panelRaised = Color(red: 0.23, green: 0.20, blue: 0.17)
    static let gold = Color(red: 1.00, green: 0.78, blue: 0.50)
    static let copper = Color(red: 0.84, green: 0.45, blue: 0.20)
    static let acidGreen = Color(red: 0.72, green: 0.95, blue: 0.22)
    static let text = Color(red: 0.98, green: 0.88, blue: 0.72)
    static let muted = Color(red: 0.72, green: 0.65, blue: 0.57)
    static let border = Color.white.opacity(0.12)
    static let actionInk = Color(red: 0.12, green: 0.07, blue: 0.03)

    static var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.08),
                    Color(red: 0.18, green: 0.15, blue: 0.13),
                    Color(red: 0.09, green: 0.08, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image("pipaHero")
                .resizable()
                .scaledToFit()
                .opacity(0.16)
                .blur(radius: 8)
                .scaleEffect(1.18)

            Color.black.opacity(0.54)

            RadialGradient(
                colors: [
                    copper.opacity(0.34),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )

            RadialGradient(
                colors: [
                    gold.opacity(0.16),
                    .clear
                ],
                center: .bottom,
                startRadius: 40,
                endRadius: 380
            )
        }
    }

    static func color(from name: String) -> Color {
        switch name {
        case "gold":
            return gold
        case "green":
            return Color(red: 0.35, green: 0.88, blue: 0.47)
        case "orange":
            return Color(red: 1.00, green: 0.62, blue: 0.26)
        case "blue":
            return Color(red: 0.40, green: 0.68, blue: 1.00)
        case "red":
            return Color(red: 1.00, green: 0.36, blue: 0.30)
        default:
            return muted
        }
    }

    static var raisedPanelGradient: LinearGradient {
        LinearGradient(
            colors: [
                panelRaised.opacity(0.92),
                panel.opacity(0.94)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var optionSelectedGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.52, green: 0.28, blue: 0.13),
                Color(red: 0.28, green: 0.16, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var optionIdleGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.06),
                Color.black.opacity(0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var actionGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.00, green: 0.71, blue: 0.42),
                Color(red: 0.62, green: 0.30, blue: 0.13)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
