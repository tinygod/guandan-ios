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
            // clean white stock (reference style)
            RoundedRectangle(cornerRadius: width * 0.12)
                .fill(Color(hex: 0xFEFDFA))

            if card.rank.isJoker {
                // vertical JOKER lettering + mascot
                VStack(spacing: -width * 0.02) {
                    ForEach(Array("JOKER".enumerated()), id: \.offset) { _, ch in
                        Text(String(ch))
                            .font(.system(size: width * 0.2, weight: .heavy, design: .serif))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(EdgeInsets(top: width * 0.05, leading: width * 0.09,
                                    bottom: 0, trailing: 0))
                Text("🃏").font(.system(size: width * 0.46))
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: .bottomTrailing)
                    .padding(EdgeInsets(top: 0, leading: 0,
                                        bottom: width * 0.1, trailing: width * 0.08))
            } else {
                // BIG rank top-left with the small suit to its RIGHT —
                // a thin stacked strip always shows both
                HStack(alignment: .firstTextBaseline, spacing: width * 0.04) {
                    Text(card.rank.shortName)
                        .font(.system(size: width * 0.44, weight: .heavy))
                    Text(card.suit?.symbol ?? "")
                        .font(.system(size: width * 0.3))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(EdgeInsets(top: width * 0.03, leading: width * 0.08,
                                    bottom: 0, trailing: 0))

                // medium suit pip at the bottom
                Text(card.suit?.symbol ?? "")
                    .font(.system(size: width * 0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, width * 0.1)
            }

            // 逢人配: gold heart at top-right + WILD ribbon bottom-left
            if wildBadge {
                Text("♥")
                    .font(.system(size: width * 0.2, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(width * 0.05)
                    .background(Theme.gold, in: Circle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(EdgeInsets(top: width * 0.05, leading: 0,
                                        bottom: 0, trailing: width * 0.05))
                Text("WILD")
                    .font(.system(size: width * 0.12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, width * 0.07).padding(.vertical, width * 0.02)
                    .background(Theme.coral, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(EdgeInsets(top: 0, leading: width * 0.05,
                                        bottom: width * 0.05, trailing: 0))
            }
            // selected state: gray veil (reference style)
            if selected {
                RoundedRectangle(cornerRadius: width * 0.12)
                    .fill(.black.opacity(0.24))
            }
        }
        .foregroundStyle(isRed ? Theme.cardRed : Theme.ink)
        .frame(width: width, height: width * 1.4)
        .overlay(
            RoundedRectangle(cornerRadius: width * 0.12)
                .strokeBorder(highlighted ? Theme.gold : .black.opacity(0.18),
                              lineWidth: highlighted ? 2.5 : 0.8)
        )
        .shadow(color: .black.opacity(0.25), radius: 2.5, y: 1.5)
        .animation(.easeInOut(duration: 0.15), value: selected)
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
