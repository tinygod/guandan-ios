import SwiftUI
import GuandanCore

/// Hand display modeled on serious GuanDan apps: same-rank cards stack
/// vertically, columns slightly overlap horizontally, locked groups (理牌)
/// sit at the edges — bombs left, other combos right.
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
    var lockedGroups: [GameViewModel.HandGroup] = []
    let onTap: (Card) -> Void

    private struct Column: Identifiable {
        let id: String
        let cards: [Card]      // last = front (fully visible) card
        let label: String?
        let locked: Bool
        var count: Int { cards.count }
    }

    // MARK: column assembly

    private var columns: [Column] {
        let lockedIds = Set(lockedGroups.flatMap(\.cards).map(\.id))
        let free = cards.filter { !lockedIds.contains($0.id) }

        func groupColumn(_ g: GameViewModel.HandGroup) -> Column {
            Column(id: g.id.uuidString, cards: g.cards,
                   label: comboLabel(g.kind), locked: true)
        }

        // bombs far LEFT (big → small), other combos far RIGHT (big → small)
        let bombGroups = lockedGroups.filter { $0.kind.isBomb }
            .sorted { ($0.kind.bombTier ?? 0) > ($1.kind.bombTier ?? 0) }
        let otherGroups = lockedGroups.filter { !$0.kind.isBomb }
            .sorted { groupOrder($0) > groupOrder($1) }

        let middle: [Column]
        switch mode {
        case .byRank:
            middle = rankColumns(of: free)
        case .combos:
            middle = HandPlanner.partition(free, level: level).map { group in
                Column(id: group.id, cards: group.cards,
                       label: group.kind.label.isEmpty ? nil : group.kind.label,
                       locked: false)
            }
        }
        return bombGroups.map(groupColumn) + middle + otherGroups.map(groupColumn)
    }

    private func groupOrder(_ g: GameViewModel.HandGroup) -> Int {
        let kindRank: Int
        switch g.kind {
        case .straight: kindRank = 5
        case .tube: kindRank = 4
        case .plate: kindRank = 3
        case .fullHouse: kindRank = 2
        case .triple: kindRank = 1
        default: kindRank = 0
        }
        let top = g.cards.map { Combo.detect([$0], level: level)?.rankValue ?? 0 }.max() ?? 0
        return kindRank * 100 + top
    }

    private func comboLabel(_ kind: ComboKind) -> String {
        switch kind {
        case .single: return ""
        case .pair: return "PAIR"
        case .triple: return "TRIPLE"
        case .fullHouse: return "3+2"
        case .straight: return "RUN"
        case .tube: return "TUBE"
        case .plate: return "PLATE"
        case .bomb(let n): return "BOMB \(n)"
        case .straightFlush: return "ST.FLUSH"
        case .jokerBomb: return "JOKERS"
        }
    }

    private func rankColumns(of pool: [Card]) -> [Column] {
        var result: [Column] = []
        let wilds = pool.filter { $0.isWildcard(level: level) }
        let rest = pool.filter { !$0.isWildcard(level: level) }
        let groups = Dictionary(grouping: rest, by: \.rank)

        func strength(_ rank: Rank) -> Int { rank == level ? 15 : rank.rawValue }

        for rank in [Rank.bigJoker, .smallJoker] {
            if let cs = groups[rank] {
                result.append(Column(id: "r\(rank.rawValue)", cards: cs,
                                     label: nil, locked: false))
            }
        }
        if !wilds.isEmpty {
            result.append(Column(id: "wild", cards: wilds, label: "WILD", locked: false))
        }
        for rank in groups.keys.filter({ !$0.isJoker })
            .sorted(by: { strength($0) > strength($1) }) {
            result.append(Column(id: "r\(rank.rawValue)", cards: groups[rank]!,
                                 label: nil, locked: false))
        }
        return result
    }

    // MARK: layout

    private static let viewHeight: CGFloat = 128

    var body: some View {
        GeometryReader { geo in
            let cols = columns
            let overlap: CGFloat = 0.1   // horizontal tuck between columns
            let effective = CGFloat(cols.count) * (1 - overlap) + overlap
            let cardW = min(76, max(46, geo.size.width / effective))

            HStack(alignment: .bottom, spacing: -cardW * overlap) {
                ForEach(cols) { column in
                    columnView(column, cardW: cardW)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        // every column is exactly this tall with its base card pinned to the
        // bottom; taller/expanded stacks rise over the felt without clipping
        .frame(height: Self.viewHeight)
    }

    private func columnView(_ column: Column, cardW: CGFloat) -> some View {
        // selecting a COVERED card spreads the column open; selecting the
        // front card changes nothing (reference behaviour)
        let covered = column.cards.dropLast()
        let expanded = covered.contains { selection.contains($0) }
        let step: CGFloat = expanded ? cardW * 0.5 : cardW * 0.40

        return ZStack(alignment: .bottom) {
            ForEach(Array(column.cards.enumerated()), id: \.element.id) { i, card in
                CardView(card: card, width: cardW,
                         selected: selection.contains(card),
                         highlighted: highlightedCards.contains(card),
                         wildBadge: card.isWildcard(level: level))
                    .offset(y: -CGFloat(column.count - 1 - i) * step)
                    .onTapGesture { onTap(card) }
            }
        }
        .frame(width: cardW, height: Self.viewHeight, alignment: .bottom)
        .overlay(alignment: .bottomLeading) {
            if let label = column.label {
                VStack(spacing: -1) {
                    if column.locked {
                        Image(systemName: "lock.fill").font(.system(size: 6))
                    }
                    ForEach(Array(label.prefix(6).enumerated()), id: \.offset) { _, ch in
                        Text(String(ch))
                            .font(.system(size: 7, weight: .black, design: .rounded))
                    }
                }
                .foregroundStyle(Theme.ink)
                .padding(.vertical, 3).padding(.horizontal, 2)
                .background(column.locked ? Theme.goldSoft : Theme.gold,
                            in: RoundedRectangle(cornerRadius: 4))
                .padding(.leading, 2).padding(.bottom, 6)
            }
        }
        .animation(.spring(duration: 0.25), value: expanded)
    }
}
