import SwiftUI
import GuandanCore

/// Hand display modeled on serious GuanDan apps: same-rank cards stack
/// vertically, groups read left → right by strength. Two modes:
/// by-rank (理牌) and combo suggestion (一键理, via HandPlanner).
enum HandSortMode: String, CaseIterable {
    case byRank = "Rank"
    case combos = "Combos"
}

struct GroupedHandView: View {
    let cards: [Card]
    let level: Rank
    let mode: HandSortMode
    let selection: Set<Card>
    var highlightedCards: Set<Card> = []
    let onTap: (Card) -> Void

    private struct Column: Identifiable {
        let id: String
        let cards: [Card]      // bottom-up draw order
        let label: String?
        var count: Int { cards.count }
    }

    private var columns: [Column] {
        switch mode {
        case .byRank:
            return rankColumns()
        case .combos:
            return HandPlanner.partition(cards, level: level).map { group in
                Column(id: group.id, cards: group.cards,
                       label: group.kind.label.isEmpty ? nil : group.kind.label)
            }
        }
    }

    private func rankColumns() -> [Column] {
        var result: [Column] = []
        let wilds = cards.filter { $0.isWildcard(level: level) }
        let rest = cards.filter { !$0.isWildcard(level: level) }
        let groups = Dictionary(grouping: rest, by: \.rank)

        func strength(_ rank: Rank) -> Int { rank == level ? 15 : rank.rawValue }

        // jokers big→small, then wildcards, then ranks descending
        for rank in [Rank.bigJoker, .smallJoker] {
            if let cs = groups[rank] {
                result.append(Column(id: "r\(rank.rawValue)", cards: cs, label: nil))
            }
        }
        if !wilds.isEmpty {
            result.append(Column(id: "wild", cards: wilds, label: "WILD"))
        }
        for rank in groups.keys.filter({ !$0.isJoker })
            .sorted(by: { strength($0) > strength($1) }) {
            result.append(Column(id: "r\(rank.rawValue)", cards: groups[rank]!, label: nil))
        }
        return result
    }

    var body: some View {
        GeometryReader { geo in
            let cols = columns
            let spacing: CGFloat = 5
            let cardW = min(66, max(40, (geo.size.width - spacing * CGFloat(cols.count - 1))
                                        / CGFloat(cols.count)))
            let cardH = cardW * 1.4
            // step exposes the full rank+suit index row of covered cards
            let stackStep: CGFloat = cardW * 0.44

            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(cols) { column in
                    columnView(column, cardW: cardW, cardH: cardH, step: stackStep)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: maxColumnHeight())
    }

    private func maxColumnHeight() -> CGFloat {
        let maxStack = columns.map(\.count).max() ?? 1
        // estimate with a mid-size card; GeometryReader refines actual width
        let cardW: CGFloat = 56
        return cardW * 1.4 + CGFloat(min(maxStack, 8) - 1) * cardW * 0.44 + 20
    }

    private func columnView(_ column: Column, cardW: CGFloat, cardH: CGFloat,
                            step: CGFloat) -> some View {
        VStack(spacing: 2) {
            if let label = column.label {
                Text(label)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 5).padding(.vertical, 1.5)
                    .background(Theme.gold, in: Capsule())
            }
            ZStack(alignment: .bottom) {
                ForEach(Array(column.cards.enumerated()), id: \.element.id) { i, card in
                    CardView(card: card, width: cardW,
                             selected: selection.contains(card),
                             highlighted: highlightedCards.contains(card),
                             wildBadge: card.isWildcard(level: level))
                        .offset(y: -CGFloat(column.count - 1 - i) * step)
                        .onTapGesture { onTap(card) }
                }
            }
            .frame(width: cardW,
                   height: cardH + CGFloat(column.count - 1) * step,
                   alignment: .bottom)
        }
    }
}
