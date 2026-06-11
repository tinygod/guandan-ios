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

    // lab ablation flags (default on; set LAB_BLOCK=0 etc. to disable)
    static let labBlock = ProcessInfo.processInfo.environment["LAB_BLOCK"] != "0"
    static let labConserve = ProcessInfo.processInfo.environment["LAB_CONSERVE"] != "0"


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
        let level = state.level

        // ---- 组牌: plan the hand structure and protect it ----
        let plan = HandPlanner.partition(hand, level: level)
        let unitSets = plan.map { Set($0.cards.map(\.id)) }
        let moveCount = plan.count

        /// A play is "clean" when it consumes whole planned units only —
        /// it never fragments a bomb, run or pair the plan wants to keep.
        func isClean(_ combo: Combo) -> Bool {
            let ids = Set(combo.cards.map(\.id))
            for unit in unitSets {
                let hit = ids.intersection(unit)
                if !hit.isEmpty && hit != unit { return false }
            }
            return true
        }

        // exit now whenever possible
        if let out = combos.first(where: { $0.cards.count == hand.count }) {
            return .play(out)
        }

        let bombs = combos.filter { $0.kind.isBomb }
        let nonBombs = combos.filter { !$0.kind.isBomb }
        let clean = nonBombs.filter(isClean)          // weakest-first

        let partnerCards = state.isActive(seat.partner)
            ? (state.hands[seat.partner]?.count ?? 0) : 0

        // ---- following a trick ----
        if let owner = state.trick.tableOwner, let table = state.trick.tableCombo,
           owner != seat {
            if owner == seat.partner {
                // never outbid a winning partner; take over only when WE are
                // about to run and their play is weak
                let partnerWeak = table.rankValue < 9 && !table.kind.isBomb
                if partnerWeak, moveCount <= 4, let cheap = clean.first {
                    return .play(cheap)
                }
                return .pass
            }

            let ownerCards = state.hands[owner]?.count ?? 99

            // 阻断 (hard only, PRECISE): cap to the top only when the owner
            // is genuinely one step from out; at 4–6 cards make riding
            // expensive with a firm (not maximal) beat
            if difficulty == .hard, Self.labBlock, ownerCards <= 3 {
                // cap with our best WHOLE unit; break structures only as
                // a last resort, and bomb rather than let them walk
                if let top = clean.last { return .play(top) }
                if let cheapBreak = nonBombs.first { return .play(cheapBreak) }
                if let bomb = bombs.first { return .play(bomb) }
                return .pass
            }

            // normal-difficulty bots play the cheapest beat even when it
            // fragments a planned unit — the classic club-player habit
            if difficulty != .hard, let naive = nonBombs.first {
                return .play(naive)
            }

            // normal defence: spend small, save shape — passing is a weapon.
            // Beating everything beatable early leaves no late-game pivots.
            if let cheap = clean.first {
                let gap = cheap.rankValue - table.rankValue
                let earlyGame = hand.count > 14
                let cheapTrick = table.rankValue < 9 && table.cards.count <= 2
                    && !table.kind.isBomb
                let bigSpend = cheap.rankValue >= 12        // J/Q/K/A/level on junk
                let overkill = gap >= 6 && cheap.rankValue >= 11
                let shedsTrash = cheap.cards.count <= 2 && cheap.rankValue <= 10

                let conserve: Bool
                switch style {
                case .charger:
                    conserve = false                          // 见牌就盖的性格
                case .controller:
                    conserve = cheapTrick && bigSpend
                case .balanced:
                    conserve = earlyGame && cheapTrick && bigSpend && !shedsTrash
                }
                _ = overkill
                // pass philosophy is a hard-bot skill; never conserve racing
                if difficulty == .hard && Self.labConserve && conserve && hand.count > 16
                    && moveCount > 4 { return .pass }
                return .play(cheap)
            }
            // structure-breaking beats only when the trick matters
            if let cheapBreak = nonBombs.first {
                let worthIt = table.rankValue >= 11 || hand.count <= 8
                    || style == .charger
                if worthIt { return .play(cheapBreak) }
            }
            // bombs: stop a runner, take a rich table, or clear our own road
            if let bomb = bombs.first {
                let tableValuable = table.rankValue >= 12 || table.cards.count >= 4
                let exitAfterBomb = moveCount <= 3
                let useBomb: Bool
                switch style {
                case .charger: useBomb = tableValuable || exitAfterBomb
                case .controller: useBomb = exitAfterBomb && !table.kind.isBomb
                case .balanced: useBomb = tableValuable || exitAfterBomb || hand.count <= 8
                }
                if useBomb { return .play(bomb) }
            }
            return .pass
        }

        // ---- leading ----
        // 喂牌: partner is short and we are not racing — serve small units
        if partnerCards > 0, partnerCards <= 6, moveCount > 5 {
            if let feed = clean.filter({ $0.cards.count <= 2 && $0.rankValue <= 10 })
                .min(by: { $0.rankValue < $1.rankValue }) {
                return .play(feed)
            }
        }

        let pool = (difficulty == .hard && !clean.isEmpty) ? clean : nonBombs
        guard !pool.isEmpty else { return .play(combos.first!) }   // only bombs left

        // normal lead: shed the weakest unit; 尾牌原理 — among small lone
        // singles lead the BIGGER one and park the runt for last
        let best = pool.min { a, b in
            leadScore(a) < leadScore(b) ? false : true
        }!
        return .play(best)
    }

    /// Higher = better lead. Multi-card units first, low ranks first; small
    /// singles invert (bigger small single leads, smallest stays as tail).
    private func leadScore(_ combo: Combo) -> Double {
        var s = Double(combo.cards.count) * 10 - Double(combo.rankValue)
        if combo.kind == .single, combo.rankValue <= 10 {
            s += Double(combo.rankValue) * 1.6   // prefer 6 over 3 as the lead
        }
        return s
    }
}
