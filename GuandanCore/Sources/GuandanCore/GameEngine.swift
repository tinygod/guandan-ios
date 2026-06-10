import Foundation

/// Table position. South is the human seat in the app. Teams: south+north
/// vs east+west. Turn order is counter-clockwise in Guandan convention but
/// modeled simply as seat order south → east → north → west.
public enum Seat: Int, CaseIterable, Hashable, Codable, Sendable {
    case south = 0, east, north, west

    public var next: Seat { Seat(rawValue: (rawValue + 1) % 4)! }
    public var partner: Seat { Seat(rawValue: (rawValue + 2) % 4)! }
    public var team: Team { rawValue % 2 == 0 ? .northSouth : .eastWest }
}

public enum Team: Int, CaseIterable, Hashable, Codable, Sendable {
    case northSouth = 0, eastWest

    public var other: Team { self == .northSouth ? .eastWest : .northSouth }
    public var seats: [Seat] { self == .northSouth ? [.south, .north] : [.east, .west] }
}

public enum PlayerAction: Hashable, Sendable {
    case play(Combo)
    case pass
}

public enum EngineError: Error, Equatable {
    case notYourTurn
    case cardsNotInHand
    case notACombo
    case mustBeatTable
    case leaderCannotPass
    case handOver
}

/// One trick on the table.
public struct TrickState: Codable, Sendable {
    public var tableCombo: Combo?
    public var tableOwner: Seat?

    public init() {}
}

/// Full state of one hand (deal → tricks → finish order).
public struct HandState: Sendable {
    public let level: Rank
    public internal(set) var hands: [Seat: [Card]]
    public internal(set) var turn: Seat
    public internal(set) var finished: [Seat] = []
    public internal(set) var trick = TrickState()
    /// Seats that passed since the last play on this trick.
    public internal(set) var passedSinceLastPlay: Set<Seat> = []

    public var isOver: Bool {
        if finished.count >= 3 { return true }
        // 双下: first two finishers are partners → remaining two both lose
        if finished.count == 2, finished[0].partner == finished[1] { return true }
        return false
    }

    public func isActive(_ seat: Seat) -> Bool { !finished.contains(seat) }

    /// Final ranking south-of: finished seats in order, then remaining active
    /// seats (for early 双下 endings both losers share the bottom; order them
    /// by seat for determinism).
    public var finishOrder: [Seat] {
        finished + Seat.allCases.filter { !finished.contains($0) }
    }
}

/// Pure state machine for a single hand.
public struct GameEngine: Sendable {
    public private(set) var state: HandState

    public init(level: Rank, hands: [Seat: [Card]], firstLeader: Seat) {
        precondition(Seat.allCases.allSatisfy { hands[$0] != nil })
        state = HandState(level: level, hands: hands, turn: firstLeader)
    }

    /// Legal combos for the seat right now (empty when only passing is legal).
    public func legalCombos(for seat: Seat) -> [Combo] {
        guard seat == state.turn, !state.isOver else { return [] }
        return Combo.allPlayable(from: state.hands[seat]!,
                                 beating: currentTable(for: seat),
                                 level: state.level)
    }

    public var mayPass: Bool { currentTable(for: state.turn) != nil }

    /// The combo that must be beaten, or nil when the seat is leading.
    private func currentTable(for seat: Seat) -> Combo? {
        guard let owner = state.trick.tableOwner else { return nil }
        return owner == seat ? nil : state.trick.tableCombo
    }

    public mutating func apply(_ action: PlayerAction, by seat: Seat) throws {
        guard !state.isOver else { throw EngineError.handOver }
        guard seat == state.turn else { throw EngineError.notYourTurn }

        switch action {
        case .pass:
            guard currentTable(for: seat) != nil else { throw EngineError.leaderCannotPass }
            state.passedSinceLastPlay.insert(seat)
            advanceAfterPass(from: seat)

        case .play(let combo):
            let hand = state.hands[seat]!
            let comboSet = Set(combo.cards)
            guard comboSet.isSubset(of: Set(hand)), comboSet.count == combo.cards.count else {
                throw EngineError.cardsNotInHand
            }
            guard let validated = Combo.detect(combo.cards, level: state.level) else {
                throw EngineError.notACombo
            }
            if let table = currentTable(for: seat) {
                guard validated.beats(table, level: state.level) else {
                    throw EngineError.mustBeatTable
                }
            }
            state.hands[seat]!.removeAll { comboSet.contains($0) }
            state.trick.tableCombo = validated
            state.trick.tableOwner = seat
            state.passedSinceLastPlay = []
            if state.hands[seat]!.isEmpty {
                state.finished.append(seat)
            }
            guard !state.isOver else { return }
            advanceToNextActive(after: seat)
        }
    }

    private mutating func advanceToNextActive(after seat: Seat) {
        var s = seat.next
        while !state.isActive(s) { s = s.next }
        state.turn = s
        closeTrickIfRoundComplete()
    }

    private mutating func advanceAfterPass(from seat: Seat) {
        advanceToNextActive(after: seat)
    }

    /// If the turn returned to the table owner (everyone else active passed),
    /// the trick closes and the owner leads. If the owner already finished,
    /// their PARTNER inherits the lead (接风); if the partner finished too,
    /// the next active seat after the owner leads.
    private mutating func closeTrickIfRoundComplete() {
        guard let owner = state.trick.tableOwner else { return }

        let othersActive = Seat.allCases.filter { $0 != owner && state.isActive($0) }
        let everyonePassed = othersActive.allSatisfy { state.passedSinceLastPlay.contains($0) }
        guard everyonePassed else { return }

        // trick closes
        state.trick = TrickState()
        state.passedSinceLastPlay = []
        if state.isActive(owner) {
            state.turn = owner
        } else if state.isActive(owner.partner) {
            state.turn = owner.partner            // 接风
        } else {
            var s = owner.next
            while !state.isActive(s) { s = s.next }
            state.turn = s
        }
    }
}

extension Combo {
    /// All distinct combos playable from `hand`. When `beating` is nil every
    /// shape is allowed (leading); otherwise only combos that beat it.
    public static func allPlayable(from hand: [Card], beating table: Combo?,
                                   level: Rank) -> [Combo] {
        var results: [Combo] = []
        var seen = Set<[Card]>()

        func consider(_ cards: [Card]) {
            let key = cards.sorted { $0.id < $1.id }
            guard !seen.contains(key) else { return }
            seen.insert(key)
            guard let combo = Combo.detect(cards, level: level) else { return }
            if let table {
                guard combo.beats(table, level: level) else { return }
            }
            results.append(combo)
        }

        let wilds = hand.filter { $0.isWildcard(level: level) }
        let handNoWilds = hand.filter { !$0.isWildcard(level: level) }
        let byRankNoWilds = Dictionary(grouping: handNoWilds, by: \.rank)

        // same-rank shapes (with 0...2 wilds attached)
        for (_, cards) in byRankNoWilds {
            for n in 1...min(cards.count, 8) {
                let base = Array(cards.prefix(n))
                consider(base)
                if wilds.count >= 1, n + 1 <= 8 { consider(base + [wilds[0]]) }
                if wilds.count >= 2, n + 2 <= 8 { consider(base + Array(wilds.prefix(2))) }
            }
        }
        if wilds.count == 1 { consider([wilds[0]]) }
        if wilds.count == 2 { consider(wilds); consider([wilds[0]]) }

        // joker bomb
        let jokers = hand.filter { $0.rank.isJoker }
        if jokers.count == 4 { consider(jokers) }

        // full houses: triple rank + pair rank (wilds already covered by
        // attaching to triples/pairs above is NOT enough; enumerate pairs)
        let tripleRanks = byRankNoWilds.filter { $0.value.count >= 3 }.keys
        let pairRanks = byRankNoWilds.filter { $0.value.count >= 2 }.keys
        for t in tripleRanks {
            for p in pairRanks where p != t {
                consider(Array(byRankNoWilds[t]!.prefix(3)) + Array(byRankNoWilds[p]!.prefix(2)))
            }
        }
        if wilds.count >= 1 {
            // wild completing the pair of a full house: triple + single + wild
            for t in tripleRanks {
                for (p, cards) in byRankNoWilds where p != t {
                    consider(Array(byRankNoWilds[t]!.prefix(3)) + [cards[0], wilds[0]])
                }
            }
            // wild completing the triple: pair + wild as triple + pair
            for t in pairRanks {
                for p in pairRanks where p != t {
                    consider(Array(byRankNoWilds[t]!.prefix(2)) + [wilds[0]]
                             + Array(byRankNoWilds[p]!.prefix(2)))
                }
            }
        }

        // sequences: straights, straight flushes (5), tubes (2x3), plates (3x2)
        appendSequences(hand: handNoWilds, wilds: wilds, byRank: byRankNoWilds,
                        consider: consider)

        // sort weakest-first so bots/UI can pick cheaply
        return results.sorted { a, b in
            if a.kind.isBomb != b.kind.isBomb { return !a.kind.isBomb }
            if let ta = a.kind.bombTier, let tb = b.kind.bombTier, ta != tb { return ta < tb }
            return a.rankValue < b.rankValue
        }
    }

    private static func appendSequences(hand: [Card], wilds: [Card],
                                        byRank: [Rank: [Card]],
                                        consider: ([Card]) -> Void) {
        // positions 1...14 (ace both ends)
        func cards(atPosition pos: Int) -> [Card] {
            let rank: Rank? = pos == 1 ? .ace : Rank(rawValue: pos)
            guard let rank, !rank.isJoker else { return [] }
            return byRank[rank] ?? []
        }

        // window helper: need `need` copies at each of `positions`
        func enumerate(positions: [Int], need: Int) {
            var chosen: [Card] = []
            var wildsUsed = 0
            for pos in positions {
                let available = cards(atPosition: pos)
                let take = min(available.count, need)
                chosen += available.prefix(take)
                wildsUsed += need - take
            }
            guard wildsUsed <= wilds.count else { return }
            consider(chosen + Array(wilds.prefix(wildsUsed)))
        }

        for start in 1...10 {           // straights / straight flushes
            enumerate(positions: Array(start...(start + 4)), need: 1)
        }
        // suit-restricted pass so straight flushes are found even when an
        // off-suit copy would otherwise be picked first
        for suit in Suit.allCases {
            let suited = hand.filter { $0.suit == suit }
            guard suited.count + wilds.count >= 5 else { continue }
            let suitedByRank = Dictionary(grouping: suited, by: \.rank)
            func suitedCards(atPosition pos: Int) -> [Card] {
                let rank: Rank? = pos == 1 ? .ace : Rank(rawValue: pos)
                guard let rank, !rank.isJoker else { return [] }
                return suitedByRank[rank] ?? []
            }
            for start in 1...10 {
                var chosen: [Card] = []
                var wildsUsed = 0
                for pos in start...(start + 4) {
                    if let card = suitedCards(atPosition: pos).first {
                        chosen.append(card)
                    } else {
                        wildsUsed += 1
                    }
                }
                guard wildsUsed <= wilds.count else { continue }
                consider(chosen + Array(wilds.prefix(wildsUsed)))
            }
        }
        for start in 1...12 {           // tubes: 3 consecutive pairs
            enumerate(positions: Array(start...(start + 2)), need: 2)
        }
        for start in 1...13 {           // plates: 2 consecutive triples
            enumerate(positions: Array(start...(start + 1)), need: 3)
        }
    }
}
