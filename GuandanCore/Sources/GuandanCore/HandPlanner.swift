import Foundation

/// 一键理牌: partition a hand into suggested play units for display.
/// Greedy, biggest-value structures first. Every card appears exactly once.
public enum HandPlanner {
    public enum GroupKind: String, Sendable {
        case jokerBomb, bomb, straightFlush, plate, tube, straight
        case triple, pair, single, wildcard

        public var label: String {
            switch self {
            case .jokerBomb: return "JOKERS"
            case .bomb: return "BOMB"
            case .straightFlush: return "ST.FLUSH"
            case .plate: return "PLATE"
            case .tube: return "TUBE"
            case .straight: return "RUN"
            case .triple: return "TRIPLE"
            case .pair: return "PAIR"
            case .single: return ""
            case .wildcard: return "WILD"
            }
        }
    }

    public struct Group: Identifiable, Sendable {
        public let kind: GroupKind
        public let cards: [Card]
        public var id: String { cards.map(\.id).joined(separator: "|") }
    }

    public static func partition(_ hand: [Card], level: Rank) -> [Group] {
        var groups: [Group] = []
        var pool = hand

        func take(_ cards: [Card], _ kind: GroupKind) {
            groups.append(Group(kind: kind, cards: cards))
            let ids = Set(cards.map(\.id))
            pool.removeAll { ids.contains($0.id) }
        }

        // wildcards held out as flexible assets
        let wilds = pool.filter { $0.isWildcard(level: level) }
        if !wilds.isEmpty { take(wilds, .wildcard) }

        // joker bomb or joker pairs
        let jokers = pool.filter { $0.rank.isJoker }
        if jokers.count == 4 {
            take(jokers, .jokerBomb)
        }

        // bombs (4+ of a rank)
        for (_, cards) in byRank(pool) where cards.count >= 4 {
            take(cards, .bomb)
        }

        // straight flushes (natural, per suit)
        for suit in Suit.allCases {
            while let run = bestRun(in: pool.filter { $0.suit == suit }, length: 5) {
                take(run, .straightFlush)
            }
        }

        // plates (2 consecutive triples), tubes (3 consecutive pairs)
        while let plate = consecutiveGroups(in: pool, ofSize: 3, runLength: 2) {
            take(plate, .plate)
        }
        while let tube = consecutiveGroups(in: pool, ofSize: 2, runLength: 3) {
            take(tube, .tube)
        }

        // straights (mixed suits) — only while they don't break pairs
        while let run = bestRun(in: singlesOnly(pool), length: 5) {
            take(run, .straight)
        }

        // triples, pairs, singles (descending strength)
        for (_, cards) in byRank(pool).sorted(by: { strengthOf($0.key, level) > strengthOf($1.key, level) }) {
            switch cards.count {
            case 3: take(cards, .triple)
            case 2: take(cards, .pair)
            default:
                for card in cards { take([card], .single) }
            }
        }

        return groups
    }

    // MARK: helpers

    private static func byRank(_ cards: [Card]) -> [Rank: [Card]] {
        Dictionary(grouping: cards, by: \.rank)
    }

    private static func strengthOf(_ rank: Rank, _ level: Rank) -> Int {
        rank == level ? 15 : rank.rawValue
    }

    /// Cards whose rank appears exactly once (safe to use in straights).
    private static func singlesOnly(_ cards: [Card]) -> [Card] {
        byRank(cards).values.filter { $0.count == 1 }.flatMap { $0 }
    }

    /// Highest run of `length` consecutive natural ranks, one card per rank.
    private static func bestRun(in cards: [Card], length: Int) -> [Card]? {
        var byPosition: [Int: Card] = [:]
        for card in cards where !card.rank.isJoker {
            byPosition[card.rank.rawValue] = card
            if card.rank == .ace { byPosition[1] = card }
        }
        for top in stride(from: 14, through: length, by: -1) {
            let positions = Array((top - length + 1)...top)
            let run = positions.compactMap { byPosition[$0] }
            if Set(run.map(\.id)).count == length {
                return run
            }
        }
        return nil
    }

    /// `runLength` consecutive ranks each holding ≥ `ofSize` cards
    /// (plate: 3×2, tube: 2×3). Returns the highest such block.
    private static func consecutiveGroups(in cards: [Card], ofSize size: Int,
                                          runLength: Int) -> [Card]? {
        let grouped = byRank(cards)
        var counts: [Int: [Card]] = [:]
        for (rank, cs) in grouped where !rank.isJoker && cs.count >= size {
            counts[rank.rawValue] = Array(cs.prefix(size))
            if rank == .ace { counts[1] = Array(cs.prefix(size)) }
        }
        for top in stride(from: 14, through: runLength, by: -1) {
            let positions = Array((top - runLength + 1)...top)
            let block = positions.compactMap { counts[$0] }
            if block.count == runLength {
                let cards = block.flatMap { $0 }
                if Set(cards.map(\.id)).count == size * runLength { return cards }
            }
        }
        return nil
    }
}
