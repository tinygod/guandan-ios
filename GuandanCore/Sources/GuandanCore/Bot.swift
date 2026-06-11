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

        // 逢人配 discipline: a wildcard is half a bomb — it may only be spent
        // inside a bomb/straight flush or to go out, never as a casual play
        func wastesWild(_ combo: Combo) -> Bool {
            guard combo.cards.contains(where: { $0.isWildcard(level: level) }) else {
                return false
            }
            return !combo.kind.isBomb && combo.cards.count != hand.count
        }
        let usable = combos.filter { !wastesWild($0) }

        let bombs = usable.filter { $0.kind.isBomb }
        let nonBombs = usable.filter { !$0.kind.isBomb }
        let clean = nonBombs.filter(isClean)          // weakest-first

        let partnerCards = state.isActive(seat.partner)
            ? (state.hands[seat.partner]?.count ?? 0) : 0
        let opponents = Seat.allCases.filter { $0.team != seat.team && state.isActive($0) }
        let minOppCards = opponents.map { state.hands[$0]?.count ?? 99 }.min() ?? 99

        // ---- 记牌: what the three hidden hands can still hold ----
        // (ported from guandan-ai PersistentMem / Danzero other_left_hands)
        var seen: [Rank: Int] = [:]
        for card in state.played { seen[card.rank, default: 0] += 1 }
        for card in hand { seen[card.rank, default: 0] += 1 }
        func remaining(_ r: Rank) -> Int { (r.isJoker ? 2 : 8) - (seen[r] ?? 0) }

        /// Strongest single strength an unseen hand could still play.
        let maxHiddenSingle: Int = {
            if remaining(.bigJoker) > 0 { return Rank.bigJoker.rawValue }
            if remaining(.smallJoker) > 0 { return Rank.smallJoker.rawValue }
            if remaining(level) > 0 { return 15 }
            for raw in stride(from: 14, through: 2, by: -1) {
                let r = Rank(rawValue: raw)!
                if r != level, remaining(r) > 0 { return raw }
            }
            return 0
        }()
        /// Strongest pair strength an unseen hand could still play.
        let maxHiddenPair: Int = {
            if remaining(.bigJoker) >= 2 { return Rank.bigJoker.rawValue }
            if remaining(.smallJoker) >= 2 { return Rank.smallJoker.rawValue }
            if remaining(level) >= 2 { return 15 }
            for raw in stride(from: 14, through: 2, by: -1) {
                let r = Rank(rawValue: raw)!
                if r != level, remaining(r) >= 2 { return raw }
            }
            return 0
        }()
        /// True when this play can no longer be beaten by any hidden hand
        /// (bombs aside) — a newly-crowned top (新晋最大牌).
        func isCrownedTop(_ combo: Combo) -> Bool {
            switch combo.kind {
            case .single: return combo.rankValue > maxHiddenSingle
            case .pair: return combo.rankValue > maxHiddenPair
            default: return false
            }
        }

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
                // a GUARANTEED stop first: cheapest play no hidden hand can
                // beat (记牌 knowledge); else best whole unit; else break/bomb
                if let sure = clean.first(where: isCrownedTop) { return .play(sure) }
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
                // a crowned top is never a waste — it wins and reclaims the
                // lead for free (记牌 knowledge beats blanket conservation)
                if isCrownedTop(cheap) { return .play(cheap) }
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
        // 喂牌: serve the EXACT shape the partner is listening for
        // (ported from guandan-ai help_ally: 1 card → single, 2 → pair)
        if partnerCards > 0, moveCount > 4 {
            if partnerCards == 1,
               let single = clean.first(where: { $0.kind == .single && $0.rankValue <= 11 }) {
                return .play(single)
            }
            if partnerCards == 2,
               let pair = clean.first(where: { $0.kind == .pair && $0.rankValue <= 11 }) {
                return .play(pair)
            }
            if partnerCards <= 6,
               let feed = clean.filter({ $0.cards.count <= 2 && $0.rankValue <= 10 })
                   .min(by: { $0.rankValue < $1.rankValue }) {
                return .play(feed)
            }
        }

        let pool = (difficulty == .hard && !clean.isEmpty) ? clean : nonBombs
        guard !pool.isEmpty else { return .play(combos.first!) }   // only bombs left

        // 卡位: deny the runner's ride — enemy at 1 card can't follow a
        // pair; at 2 cards a single forces a break (both reference AIs)
        if difficulty == .hard {
            if minOppCards == 1,
               let pair = pool.first(where: { $0.kind == .pair }) {
                return .play(pair)
            }
            if minOppCards == 2,
               let single = pool.first(where: { $0.kind == .single && $0.rankValue <= 11 }) {
                return .play(single)
            }
        }

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
