import SwiftUI

/// Design tokens lifted from the Stitch designs
/// (~/claudecode/guandan-design/screens/*.html).
enum Theme {
    // Core palette — premium revision matching the Stitch art direction
    static let felt = Color(hex: 0x0D3B34)          // deep emerald felt
    static let feltDark = Color(hex: 0x092A25)
    static let feltLight = Color(hex: 0x125248)
    static let coral = Color(hex: 0xE85D4E)         // primary CTA (deepened)
    static let coralDark = Color(hex: 0xB34B42)
    static let gold = Color(hex: 0xD4AF5E)          // engraved gold
    static let goldSoft = Color(hex: 0xEFD9A0)
    static let mint = Color(hex: 0x8FC4BA)          // secondary text on felt
    static let mintBright = Color(hex: 0xB5EDE5)
    static let ivory = Color(hex: 0xFAF6EA)         // warm card stock
    static let ivoryDeep = Color(hex: 0xF0E9D6)
    static let ink = Color(hex: 0x1A1B18)           // text on light surfaces
    static let cardRed = Color(hex: 0xA8281F)

    static let cornerRadius: CGFloat = 16

    /// Premium felt: emerald gradient + faint jacquard wave pattern.
    static var background: some View { FeltBackground() }
}

/// Dark emerald felt with a subtle repeating wave engraving, per the Stitch
/// premium-table design.
struct FeltBackground: View {
    var body: some View {
        ZStack {
            RadialGradient(colors: [Theme.feltLight, Theme.felt, Theme.feltDark],
                           center: .center, startRadius: 60, endRadius: 600)
            Canvas { ctx, size in
                let waveW: CGFloat = 56, waveH: CGFloat = 30
                var path = Path()
                var y: CGFloat = -waveH
                while y < size.height + waveH {
                    var x: CGFloat = -waveW
                    while x < size.width + waveW {
                        path.move(to: CGPoint(x: x, y: y + waveH / 2))
                        path.addQuadCurve(to: CGPoint(x: x + waveW / 2, y: y + waveH / 2),
                                          control: CGPoint(x: x + waveW / 4, y: y))
                        path.addQuadCurve(to: CGPoint(x: x + waveW, y: y + waveH / 2),
                                          control: CGPoint(x: x + waveW * 3 / 4, y: y + waveH))
                        x += waveW
                    }
                    y += waveH
                }
                ctx.stroke(path, with: .color(.white.opacity(0.025)), lineWidth: 1.2)
            }
        }
        .ignoresSafeArea()
    }
}

/// Engraved gold plaque (level indicator, section headers).
struct GoldPlaque: View {
    let top: String
    let big: String
    var bottom: String? = nil

    var body: some View {
        VStack(spacing: 1) {
            Text(top).font(.system(size: 9, weight: .semibold, design: .serif))
                .tracking(1.5)
                .foregroundStyle(Theme.gold.opacity(0.8))
            Text(big).font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Theme.goldSoft)
            if let bottom {
                Text(bottom).font(.system(size: 9, weight: .medium, design: .serif))
                    .foregroundStyle(Theme.gold.opacity(0.8))
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 6)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .strokeBorder(Theme.gold.opacity(0.55), lineWidth: 1))
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
