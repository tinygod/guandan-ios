import Foundation

/// The shape of a play.
public enum ComboKind: Hashable, Codable, Sendable {
    case single
    case pair
    case triple
    case fullHouse        // triple + pair (三带二)
    case straight         // 5 consecutive ranks, mixed suits (顺子)
    case tube             // 3 consecutive pairs (三连对 / 木板)
    case plate            // 2 consecutive triples (钢板)
    case bomb(size: Int)  // 4–8 of a kind (only 4...8 possible with wildcards ≤2)
    case straightFlush    // 5 consecutive, same suit (同花顺)
    case jokerBomb        // all four jokers (四大天王)

    public var isBomb: Bool {
        switch self {
        case .bomb, .straightFlush, .jokerBomb: return true
        default: return false
        }
    }
}

/// A concrete, validated play.
public struct Combo: Hashable, Codable, Sendable {
    public let kind: ComboKind
    public let cards: [Card]
    /// Strength of the shape's anchor rank. For non-sequence shapes the
    /// current level rank maps to 15 (above ace, below jokers). For
    /// sequences this is the natural rank of the HIGHEST card (A-2-3-4-5
    /// counts as a 5-high straight, value 5).
    public let rankValue: Int

    public init(kind: ComboKind, cards: [Card], rankValue: Int) {
        self.kind = kind
        self.cards = cards
        self.rankValue = rankValue
    }
}

extension Combo {
    /// Trick-relative strength of a rank for non-sequence shapes.
    static func strength(of rank: Rank, level: Rank) -> Int {
        if rank == level { return 15 }
        return rank.rawValue
    }

    /// Detect the combo formed by EXACTLY this set of cards (order ignored).
    /// Wildcards (heart level cards) are substituted to find the strongest
    /// valid interpretation. Returns nil if the set forms no legal shape.
    public static func detect(_ cards: [Card], level: Rank) -> Combo? {
        guard !cards.isEmpty, cards.count <= 8 else { return nil }
        let wilds = cards.filter { $0.isWildcard(level: level) }
        let naturals = cards.filter { !$0.isWildcard(level: level) }

        // Jokers can never be substituted by wildcards, and a wildcard can
        // not represent a joker. Joker bomb must be exact.
        if naturals.contains(where: { $0.rank.isJoker }) {
            // sets mixing jokers with anything else: only joker bomb or
            // single/pair of identical jokers are legal.
            if cards.count == 4, Set(cards.map(\.rank)) == [.smallJoker, .bigJoker],
               cards.filter({ $0.rank == .smallJoker }).count == 2, wilds.isEmpty {
                return Combo(kind: .jokerBomb, cards: cards, rankValue: 100)
            }
            guard wilds.isEmpty, Set(naturals.map(\.rank)).count == 1 else { return nil }
            let rank = naturals[0].rank
            switch cards.count {
            case 1: return Combo(kind: .single, cards: cards,
                                 rankValue: strength(of: rank, level: level))
            case 2: return Combo(kind: .pair, cards: cards,
                                 rankValue: strength(of: rank, level: level))
            default: return nil
            }
        }

        var best: Combo?
        forEachAssignment(wilds: wilds.count, level: level) { substitution in
            if let combo = detectNatural(naturals: naturals, substitutedRanks: substitution.ranks,
                                         substitutedSuit: substitution.suit,
                                         allCards: cards, level: level) {
                if best == nil || combo.outranksForOwner(best!) { best = combo }
            }
        }
        return best
    }

    /// Wildcard substitution candidates: each wild becomes (rank, suit).
    /// To keep the search small we only enumerate ranks (suits matter only
    /// for straight flush, where all cards share one suit anyway).
    private struct Substitution { let ranks: [Rank]; let suit: Suit? }

    private static func forEachAssignment(wilds: Int, level: Rank,
                                          _ body: (Substitution) -> Void) {
        let candidates = Rank.suited
        switch wilds {
        case 0:
            body(Substitution(ranks: [], suit: nil))
        case 1:
            for r in candidates {
                for s in [Suit?.none, .spades, .hearts, .clubs, .diamonds] {
                    body(Substitution(ranks: [r], suit: s))
                }
            }
        case 2:
            for r1 in candidates {
                for r2 in candidates where r2.rawValue >= r1.rawValue {
                    for s in [Suit?.none, .spades, .hearts, .clubs, .diamonds] {
                        body(Substitution(ranks: [r1, r2], suit: s))
                    }
                }
            }
        default:
            break // at most 2 wildcards exist (two heart level cards)
        }
    }

    /// Detect a shape from natural cards + virtual cards from wildcards.
    private static func detectNatural(naturals: [Card], substitutedRanks: [Rank],
                                      substitutedSuit: Suit?, allCards: [Card],
                                      level: Rank) -> Combo? {
        var rankCounts: [Rank: Int] = [:]
        for c in naturals { rankCounts[c.rank, default: 0] += 1 }
        for r in substitutedRanks { rankCounts[r, default: 0] += 1 }
        let total = naturals.count + substitutedRanks.count
        let distinct = rankCounts.keys.sorted()

        // Same-rank shapes
        if distinct.count == 1 {
            let rank = distinct[0]
            let value = strength(of: rank, level: level)
            switch total {
            case 1: return Combo(kind: .single, cards: allCards, rankValue: value)
            case 2: return Combo(kind: .pair, cards: allCards, rankValue: value)
            case 3: return Combo(kind: .triple, cards: allCards, rankValue: value)
            case 4...8: return Combo(kind: .bomb(size: total), cards: allCards, rankValue: value)
            default: return nil
            }
        }

        // Full house: 3 + 2
        if total == 5, distinct.count == 2 {
            let counts = distinct.map { rankCounts[$0]! }
            if counts.sorted() == [2, 3] {
                let tripleRank = distinct[counts[0] == 3 ? 0 : 1]
                return Combo(kind: .fullHouse, cards: allCards,
                             rankValue: strength(of: tripleRank, level: level))
            }
        }

        // Sequence shapes use NATURAL rank order; ace may be high or low.
        // Build the multiset over natural positions (A = 14 or 1).
        if let seq = sequenceCombo(rankCounts: rankCounts, total: total,
                                   naturals: naturals, substitutedRanks: substitutedRanks,
                                   substitutedSuit: substitutedSuit, allCards: allCards) {
            return seq
        }
        return nil
    }

    private static func sequenceCombo(rankCounts: [Rank: Int], total: Int,
                                      naturals: [Card], substitutedRanks: [Rank],
                                      substitutedSuit: Suit?, allCards: [Card]) -> Combo? {
        guard rankCounts.keys.allSatisfy({ !$0.isJoker }) else { return nil }

        // try ace-high and ace-low positions
        let positionsSets: [[Int: Int]] = {
            var high: [Int: Int] = [:]
            for (r, c) in rankCounts { high[r.rawValue] = c }
            guard rankCounts[.ace] != nil else { return [high] }
            var low = high
            low[1] = low.removeValue(forKey: 14)
            return [high, low]
        }()

        for positions in positionsSets {
            let sorted = positions.keys.sorted()
            let isConsecutive = sorted.count > 1 &&
                zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 == 1 }
            guard isConsecutive else { continue }
            let counts = Set(positions.values)
            let top = sorted.last!

            if total == 5, sorted.count == 5, counts == [1] {
                // straight; flush if all five share a suit
                let naturalSuits = Set(naturals.compactMap(\.suit))
                let isFlush: Bool
                if substitutedRanks.isEmpty {
                    isFlush = naturalSuits.count == 1
                } else {
                    isFlush = naturalSuits.count == 1 &&
                        (substitutedSuit == nil || substitutedSuit == naturalSuits.first)
                }
                return Combo(kind: isFlush ? .straightFlush : .straight,
                             cards: allCards, rankValue: top)
            }
            if total == 6, sorted.count == 3, counts == [2] {
                return Combo(kind: .tube, cards: allCards, rankValue: top)
            }
            if total == 6, sorted.count == 2, counts == [3] {
                return Combo(kind: .plate, cards: allCards, rankValue: top)
            }
        }
        return nil
    }

    /// Preference order when several interpretations exist for the SAME card
    /// set (owner wants the strongest): bombs > straightFlush > others, then
    /// higher rankValue.
    func outranksForOwner(_ other: Combo) -> Bool {
        func tier(_ k: ComboKind) -> Int {
            switch k {
            case .jokerBomb: return 4
            case .straightFlush: return 3
            case .bomb: return 2
            default: return 1
            }
        }
        if tier(kind) != tier(other.kind) { return tier(kind) > tier(other.kind) }
        if case .bomb(let a) = kind, case .bomb(let b) = other.kind, a != b { return a > b }
        return rankValue > other.rankValue
    }
}
