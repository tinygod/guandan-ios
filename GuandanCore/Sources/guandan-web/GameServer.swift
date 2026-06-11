import Foundation
import GuandanCore

/// One web-played match: you (south) vs three hard bots with personalities.
final class WebGame {
    var match = MatchSession()
    var engine: GameEngine!
    var lastPlays: [Seat: PlayerAction] = [:]
    var previousOrder: [Seat]?
    var handResult: [Seat]?
    var tributeNote: String?
    var rng = SeededGenerator(seed: UInt64(Date().timeIntervalSince1970 * 1000))

    let bots: [Seat: HeuristicBot] = [
        .east: HeuristicBot(difficulty: .hard, style: .charger),     // Lena 🔥
        .north: HeuristicBot(difficulty: .hard, style: .balanced),   // Coach Wu
        .west: HeuristicBot(difficulty: .hard, style: .controller),  // Marco 🧊
    ]

    init() { startHand() }

    func reset() {
        match = MatchSession()
        previousOrder = nil
        startHand()
    }

    func startHand() {
        let seed = rng.next()
        let dealt = Deck.deal(seed: seed)
        var hands: [Seat: [Card]] = [.south: dealt[0], .east: dealt[1],
                                     .north: dealt[2], .west: dealt[3]]
        var leader = Seat.south
        tributeNote = nil
        if let prev = previousOrder {
            let level = match.activeLevel
            let res = Tribute.resolve(finishOrder: prev, hands: hands, level: level)
            if res.antiTribute {
                tributeNote = "Anti-tribute! Both big jokers refused to pay."
            } else if !res.transfers.isEmpty {
                Tribute.apply(res.transfers, to: &hands)
                let returns = res.transfers.map {
                    Tribute.Transfer(from: $0.to, to: $0.from,
                                     card: MatchRunner.returnCard(from: hands[$0.to]!,
                                                                  level: level))
                }
                Tribute.apply(returns, to: &hands)
                tributeNote = res.transfers
                    .map { "\(name($0.from)) pays \($0.card.displayName)" }
                    .joined(separator: " · ")
            }
            leader = res.firstLeader
        }
        engine = GameEngine(level: match.activeLevel, hands: hands, firstLeader: leader)
        lastPlays = [:]
        handResult = nil
    }

    func name(_ seat: Seat) -> String {
        switch seat {
        case .south: return "You"
        case .east: return "Lena"
        case .north: return "Coach Wu"
        case .west: return "Marco"
        }
    }

    /// Advance exactly one bot action (called from each /state poll → pacing).
    func stepBot() {
        guard handResult == nil, engine.state.turn != .south,
              !engine.state.isOver else { return }
        let seat = engine.state.turn
        let action = bots[seat]!.decide(engine: engine, seat: seat, rng: &rng)
        apply(action, by: seat)
    }

    func apply(_ action: PlayerAction, by seat: Seat) {
        guard (try? engine.apply(action, by: seat)) != nil else { return }
        if engine.state.trick.tableCombo == nil {
            lastPlays = [:]
        } else {
            lastPlays[seat] = action
        }
        if engine.state.isOver {
            let order = engine.state.finishOrder
            handResult = order
            previousOrder = order
            match.recordHand(finishOrder: order)
        }
    }

    func humanPlay(ids: [String]) -> String? {
        guard handResult == nil, engine.state.turn == .south else { return "not your turn" }
        let hand = engine.state.hands[.south] ?? []
        let cards = hand.filter { ids.contains($0.id) }
        guard cards.count == ids.count else { return "cards not in hand" }
        guard let combo = Combo.detect(cards, level: engine.state.level) else {
            return "not a valid combo"
        }
        if let table = engine.state.trick.tableCombo,
           engine.state.trick.tableOwner != .south,
           !combo.beats(table, level: engine.state.level) {
            return "doesn't beat the table"
        }
        apply(.play(combo), by: .south)
        return nil
    }

    func humanPass() -> String? {
        guard handResult == nil, engine.state.turn == .south else { return "not your turn" }
        guard engine.mayPass else { return "you lead — play anything" }
        apply(.pass, by: .south)
        return nil
    }

    var hintIndex = 0
    func hint() -> [String] {
        guard engine.state.turn == .south else { return [] }
        let candidates = engine.legalCombos(for: .south)
        guard !candidates.isEmpty else { return [] }
        let pick = candidates[hintIndex % candidates.count]
        hintIndex += 1
        return pick.cards.map(\.id)
    }

    // MARK: JSON state

    func stateJSON() -> [String: Any] {
        stepBot()
        let state = engine.state
        let level = state.level

        func cardJSON(_ c: Card) -> [String: Any] {
            ["id": c.id, "rank": c.rank.shortName,
             "suit": c.suit.map(suitChar) ?? "🃏",
             "red": c.rank == .bigJoker || c.suit == .hearts || c.suit == .diamonds,
             "wild": c.isWildcard(level: level),
             "big": c.rank == .bigJoker]
        }
        func playJSON(_ seat: Seat) -> Any {
            switch lastPlays[seat] {
            case .play(let combo):
                return ["cards": combo.cards.map(cardJSON), "label": comboLabel(combo.kind)]
            case .pass: return ["pass": true]
            case nil: return NSNull()
            }
        }

        let hand = (state.hands[.south] ?? []).sorted { a, b in
            let sa = a.rank == level ? 15 : a.rank.rawValue
            let sb = b.rank == level ? 15 : b.rank.rawValue
            if a.isWildcard(level: level) != b.isWildcard(level: level) {
                return a.isWildcard(level: level)
            }
            if sa != sb { return sa > sb }
            return (a.suit?.rawValue ?? 9) < (b.suit?.rawValue ?? 9)
        }

        var result: Any = NSNull()
        if let order = handResult {
            result = ["order": order.map(name),
                      "teams": order.map { $0.team == .northSouth ? "us" : "them" },
                      "matchOver": match.matchWinner != nil,
                      "matchWinner": match.matchWinner.map { $0 == .northSouth ? "us" : "them" } ?? ""]
        }

        return [
            "level": level.shortName,
            "usLevel": match.levels[.northSouth]!.shortName,
            "themLevel": match.levels[.eastWest]!.shortName,
            "turn": name(state.turn),
            "yourTurn": state.turn == .south && handResult == nil,
            "mayPass": engine.mayPass,
            "hand": hand.map(cardJSON),
            "seats": [
                "north": ["name": name(.north), "count": state.hands[.north]?.count ?? 0,
                          "play": playJSON(.north), "turn": state.turn == .north],
                "east": ["name": name(.east), "count": state.hands[.east]?.count ?? 0,
                         "play": playJSON(.east), "turn": state.turn == .east],
                "west": ["name": name(.west), "count": state.hands[.west]?.count ?? 0,
                         "play": playJSON(.west), "turn": state.turn == .west],
            ],
            "yourPlay": playJSON(.south),
            "tribute": tributeNote ?? "",
            "result": result,
        ]
    }

    private func suitChar(_ s: Suit) -> String {
        switch s {
        case .spades: return "♠"
        case .hearts: return "♥"
        case .clubs: return "♣"
        case .diamonds: return "♦"
        }
    }

    private func comboLabel(_ kind: ComboKind) -> String {
        switch kind {
        case .single: return "Single"
        case .pair: return "Pair"
        case .triple: return "Triple"
        case .fullHouse: return "Full House"
        case .straight: return "Straight"
        case .tube: return "Tube"
        case .plate: return "Plate"
        case .bomb(let n): return "BOMB \(n)"
        case .straightFlush: return "ST. FLUSH"
        case .jokerBomb: return "FOUR JOKERS"
        }
    }
}
