import SwiftUI
import GuandanCore

/// A single playing card, scaled by `width` (height = 1.4 × width).
struct CardView: View {
    let card: Card
    var width: CGFloat = 56
    var selected: Bool = false
    var highlighted: Bool = false

    private var isRed: Bool {
        card.suit == .hearts || card.suit == .diamonds || card.rank == .bigJoker
    }

    private var rankText: String {
        switch card.rank {
        case .smallJoker, .bigJoker: return "★"
        default: return card.rank.shortName
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: -2) {
                Text(rankText)
                    .font(.system(size: width * 0.34, weight: .heavy, design: .rounded))
                if let suit = card.suit {
                    Text(suit.symbol)
                        .font(.system(size: width * 0.26))
                } else {
                    Text(card.rank == .bigJoker ? "JOKER" : "joker")
                        .font(.system(size: width * 0.13, weight: .black, design: .rounded))
                        .rotationEffect(.degrees(0))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(width * 0.1)
        }
        .foregroundStyle(isRed ? Theme.cardRed : Theme.ink)
        .frame(width: width, height: width * 1.4)
        .background(Theme.ivory, in: RoundedRectangle(cornerRadius: width * 0.14))
        .overlay(
            RoundedRectangle(cornerRadius: width * 0.14)
                .strokeBorder(highlighted ? Theme.gold : .black.opacity(0.12),
                              lineWidth: highlighted ? 2.5 : 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
        .offset(y: selected ? -16 : 0)
        .animation(.spring(duration: 0.2), value: selected)
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
