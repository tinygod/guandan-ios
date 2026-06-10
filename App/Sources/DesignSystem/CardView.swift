import SwiftUI
import GuandanCore

/// A single playing card in the premium art direction: warm ivory stock,
/// gold hairline inset, serif indices, ornamented courts and jokers.
struct CardView: View {
    let card: Card
    var width: CGFloat = 56
    var selected: Bool = false
    var highlighted: Bool = false
    var wildBadge: Bool = false

    private var isRed: Bool {
        card.suit == .hearts || card.suit == .diamonds || card.rank == .bigJoker
    }

    private var isCourt: Bool {
        card.rank == .jack || card.rank == .queen || card.rank == .king
    }

    var body: some View {
        ZStack {
            // stock + gold hairline inset
            RoundedRectangle(cornerRadius: width * 0.13)
                .fill(LinearGradient(colors: [Theme.ivory, Theme.ivoryDeep],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: width * 0.09)
                .strokeBorder(Theme.gold.opacity(0.5), lineWidth: max(0.5, width * 0.012))
                .padding(width * 0.055)

            // corner index — horizontal rank+suit so a thin stacked strip
            // still shows both; jokers spell JOKER vertically (classic style)
            Group {
                if card.rank.isJoker {
                    VStack(spacing: -width * 0.015) {
                        ForEach(Array("JOKER".enumerated()), id: \.offset) { _, ch in
                            Text(String(ch))
                                .font(.system(size: width * 0.19,
                                              weight: .heavy, design: .serif))
                        }
                    }
                } else {
                    HStack(spacing: width * 0.05) {
                        Text(card.rank.shortName)
                            .font(.system(size: width * 0.34, weight: .bold, design: .serif))
                        if let suit = card.suit {
                            Text(suit.symbol).font(.system(size: width * 0.3))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(EdgeInsets(top: width * 0.05, leading: width * 0.08,
                                bottom: 0, trailing: 0))

            // center motif
            centerMotif

            // 逢人配 ribbon
            if wildBadge {
                Text("WILD")
                    .font(.system(size: width * 0.13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, width * 0.08).padding(.vertical, width * 0.025)
                    .background(Theme.coral, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, width * 0.08)
            }
        }
        .foregroundStyle(isRed ? Theme.cardRed : Theme.ink)
        .frame(width: width, height: width * 1.4)
        .overlay(
            RoundedRectangle(cornerRadius: width * 0.13)
                .strokeBorder(highlighted ? Theme.gold : .black.opacity(0.15),
                              lineWidth: highlighted ? 2.5 : 0.8)
        )
        .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
        .offset(y: selected ? -16 : 0)
        .animation(.spring(duration: 0.2), value: selected)
    }

    @ViewBuilder
    private var centerMotif: some View {
        if card.rank.isJoker {
            Text("🃏").font(.system(size: width * 0.4))
                .offset(x: width * 0.1, y: width * 0.24)
        } else if isCourt {
            ZStack {
                RoundedRectangle(cornerRadius: width * 0.06)
                    .strokeBorder(Theme.gold.opacity(0.7), lineWidth: max(0.6, width * 0.015))
                    .frame(width: width * 0.46, height: width * 0.58)
                    .rotationEffect(.degrees(45))
                Text(card.rank.shortName)
                    .font(.system(size: width * 0.34, weight: .bold, design: .serif))
            }
            .offset(y: width * 0.22)
        } else {
            Text(card.suit?.symbol ?? "")
                .font(.system(size: width * 0.5))
                .shadow(color: Theme.gold.opacity(0.35), radius: 0.5, x: 1, y: 1)
                .offset(y: width * 0.22)
        }
    }
}

/// A fanned, overlapping hand of cards with tap-to-select. Sizes itself to
/// the width it is given (landscape: the full bottom strip).
struct HandFanView: View {
    let cards: [Card]
    let selection: Set<Card>
    var highlightedCards: Set<Card> = []
    var cardWidth: CGFloat = 52
    let onTap: (Card) -> Void

    var body: some View {
        GeometryReader { geo in
            let overlap: CGFloat = {
                guard cards.count > 1 else { return 0 }
                let available = geo.size.width - cardWidth
                return min(cardWidth * 0.72, available / CGFloat(cards.count - 1))
            }()
            HStack(spacing: overlap - cardWidth) {
                ForEach(cards) { card in
                    CardView(card: card, width: cardWidth,
                             selected: selection.contains(card),
                             highlighted: highlightedCards.contains(card))
                        .onTapGesture { onTap(card) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: cardWidth * 1.4 + 18)
    }
}

/// Sort a hand for display: descending strength, grouped by rank.
func displaySorted(_ cards: [Card], level: Rank) -> [Card] {
    cards.sorted { a, b in
        let sa = a.rank == level ? 15 : a.rank.rawValue
        let sb = b.rank == level ? 15 : b.rank.rawValue
        if sa != sb { return sa > sb }
        return (a.suit?.rawValue ?? 9) < (b.suit?.rawValue ?? 9)
    }
}
