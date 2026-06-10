import Foundation

public enum BotDifficulty: String, CaseIterable, Codable, Sendable {
    case easy, normal, hard
}

/// Play personality (丁华：控制型 vs 冲锋型).
public enum BotStyle: String, CaseIterable, Codable, Sendable {
    case balanced
    case controller   // 控制型：节约牌力，留大牌封盖，长于忍耐
    case charger      // 冲锋型：见牌就盖，宁愿自己不舒服也让对手不舒服
}

public protocol Bot: Sendable {
    func decide(engine: GameEngine, seat: Seat, rng: inout SeededGenerator) -> PlayerAction
}

/// Rule-based bot. Strategy outline:
/// - Leading: shed the weakest combo, preferring multi-card shapes; never
///   lead a bomb unless it is the only thing left.
/// - Following: play the cheapest combo that beats the table. Pass when the
///   table is the partner's and reasonably strong. Spend bombs only on
///   high-value tables or to go out.
/// - Difficulties: easy picks randomly among legal moves; normal applies the
///   heuristics; hard additionally protects bombs from being wasted and
///   pushes harder when close to finishing.
public struct HeuristicBot: Bot {
    public let difficulty: BotDifficulty
    public let style: BotStyle

    public init(difficulty: BotDifficulty = .normal, style: BotStyle = .balanced) {
        self.difficulty = difficulty
        self.style = style
    }

    public func decide(engine: GameEngine, seat: Seat,
                       rng: inout SeededGenerator) -> PlayerAction {
        let state = engine.state
        let combos = engine.legalCombos(for: seat)
        guard !combos.isEmpty else { return .pass }

        if difficulty == .easy {
            // mostly the weakest move, sometimes random, avoids bombs unless forced
            let nonBombs = combos.filter { !$0.kind.isBomb }
            let pool = nonBombs.isEmpty ? combos : nonBombs
            if engine.mayPass, Int.random(in: 0..<4, using: &rng) == 0 { return .pass }
            return .play(pool[Int.random(in: 0..<min(2, pool.count), using: &rng)])
        }

        let hand = state.hands[seat]!
        let bombs = combos.filter { $0.kind.isBomb }
        let nonBombs = combos.filter { !$0.kind.isBomb }

        // Following a trick
        if let owner = state.trick.tableOwner, let table = state.trick.tableCombo,
           owner != seat {
            let partnerOwns = owner == seat.partner
            if partnerOwns {
                // pass on partner's strong play unless we can go out now
                let canGoOut = combos.contains { $0.cards.count == hand.count }
                let partnerStrong = table.rankValue >= 13 || table.kind.isBomb
                if partnerStrong && !canGoOut { return .pass }
                // beat partner only with a cheap same-shape move
                if let cheap = nonBombs.first, !partnerStrong { return .play(cheap) }
                return .pass
            }
            // opponent owns the table
            if let cheapest = nonBombs.first {
                // controllers conserve big cards on cheap tables mid-hand
                if style == .controller, cheapest.rankValue >= 13,
                   table.rankValue < 9, hand.count > 10 {
                    return .pass
                }
                return .play(cheapest)
            }
            if let bomb = bombs.first {
                let tableValuable = table.rankValue >= 12 || table.cards.count >= 4
                    || hand.count <= 8
                let useBomb: Bool
                switch style {
                case .charger: useBomb = true                       // 见之必盖
                case .controller: useBomb = table.kind.isBomb == false && hand.count <= 8
                case .balanced: useBomb = difficulty == .hard ? tableValuable : true
                }
                if useBomb { return .play(bomb) }
            }
            return .pass
        }

        // Leading: prefer shedding many cards with low rank; keep bombs intact.
        let bombCards = Set(bombs.flatMap { $0.cards })
        let preserving = nonBombs.filter { combo in
            difficulty == .hard ? combo.cards.allSatisfy { !bombCards.contains($0) } : true
        }
        let candidates = preserving.isEmpty ? nonBombs : preserving
        if candidates.isEmpty { return .play(combos.first!) } // only bombs left

        let best = candidates.min { a, b in
            score(leading: a, handCount: hand.count) > score(leading: b, handCount: hand.count)
        }!
        return .play(best)
    }

    /// Higher score = better lead. Shed more cards, lower ranks first.
    private func score(leading combo: Combo, handCount: Int) -> Double {
        var s = Double(combo.cards.count) * 10 - Double(combo.rankValue)
        if combo.cards.count == handCount { s += 1000 }   // going out wins outright
        return s
    }
}
