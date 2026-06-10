import SwiftUI

/// Design tokens lifted from the Stitch designs
/// (~/claudecode/guandan-design/screens/*.html).
enum Theme {
    // Core palette
    static let felt = Color(hex: 0x0F4C46)          // deep teal felt
    static let feltDark = Color(hex: 0x0A3B36)
    static let feltLight = Color(hex: 0x16635B)
    static let coral = Color(hex: 0xFF6B5E)         // primary CTA
    static let coralDark = Color(hex: 0xB34B42)
    static let gold = Color(hex: 0xE8C268)          // achievements, levels
    static let goldSoft = Color(hex: 0xFFDF98)
    static let mint = Color(hex: 0x99D1C9)          // secondary text on felt
    static let mintBright = Color(hex: 0xB5EDE5)
    static let ivory = Color(hex: 0xFCF9F2)         // card faces
    static let ink = Color(hex: 0x121412)           // text on light surfaces
    static let cardRed = Color(hex: 0xAE3029)

    static let cornerRadius: CGFloat = 16

    /// Layered felt background used by every screen.
    static var background: some View {
        LinearGradient(colors: [feltLight, felt, feltDark],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: typography

extension Font {
    /// Rounded friendly type ramp (system rounded ≈ Plus Jakarta Sans vibe
    /// without bundling a font in v1).
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
    static func heading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
}

// MARK: shared components

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title).font(.heading(18))
                if let icon { Image(systemName: icon) }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.coral, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .shadow(color: Theme.coral.opacity(0.4), radius: 12, y: 6)
        }
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.heading(16))
                .foregroundStyle(Theme.mintBright)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .strokeBorder(.white.opacity(0.15)))
        }
    }
}

struct PanelCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.07),
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .strokeBorder(.white.opacity(0.1)))
    }
}
