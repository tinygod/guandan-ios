import Foundation

/// Targeted dealing for training scenarios: guarantee specific cards land in
/// specific seats, fill the rest randomly. 教学定向发牌。
public enum DealRecipe {
    /// Deal 27 cards to each seat with `required` cards forced into place.
    /// Required cards are matched by rank+suit (copy index resolved
    /// automatically so recipes don't care which physical copy).
    public static func deal(seed: UInt64, required: [Seat: [Card]]) -> [Seat: [Card]] {
        var pool = Deck.standard()
        var hands: [Seat: [Card]] = [:]

        for seat in Seat.allCases {
            var assigned: [Card] = []
            for want in required[seat] ?? [] {
                guard let i = pool.firstIndex(where: {
                    $0.rank == want.rank && $0.suit == want.suit
                }) else {
                    preconditionFailure("recipe demands unavailable card \(want.displayName)")
                }
                assigned.append(pool.remove(at: i))
            }
            precondition(assigned.count <= 27, "recipe exceeds 27 cards for \(seat)")
            hands[seat] = assigned
        }

        var rng = SeededGenerator(seed: seed)
        pool.shuffle(using: &rng)
        for seat in Seat.allCases {
            let need = 27 - hands[seat]!.count
            hands[seat]!.append(contentsOf: pool.prefix(need))
            pool.removeFirst(need)
        }
        return hands
    }
}

/// Post-hand mistake analysis for review (复盘失误标记).
public enum MistakeKind: String, CaseIterable, Sendable {
    case beatPartner        // 压队友：盖过队友正在赢的牌
    case wastedBomb         // 浪费炸弹：炸低价值小牌桌
    case earlyWildcard      // 早烧逢人配：前期把万能牌用在普通小牌型上
}

public struct Mistake: Sendable {
    public let kind: MistakeKind
    public let stepIndex: Int     // index into the action list
    public let note: String
}

public enum MistakeDetector {
    /// Replay a hand and flag the focus seat's questionable moves.
    public static func analyze(level: Rank, initialHands: [Seat: [Card]],
                               firstLeader: Seat,
                               actions: [(Seat, PlayerAction)],
                               focus: Seat = .south) -> [Mistake] {
        var engine = GameEngine(level: level, hands: initialHands, firstLeader: firstLeader)
        var mistakes: [Mistake] = []

        for (i, (seat, action)) in actions.enumerated() {
            if seat == focus, case .play(let combo) = action {
                let state = engine.state
                let handCount = state.hands[focus]!.count
                let goingOut = combo.cards.count == handCount

                // 压队友
                if let owner = state.trick.tableOwner, owner == focus.partner,
                   let table = state.trick.tableCombo, !goingOut {
                    let partnerStrong = table.rankValue >= 13 || table.kind.isBomb
                    if partnerStrong {
                        mistakes.append(Mistake(
                            kind: .beatPartner, stepIndex: i,
                            note: "Partner's \(table.rankValue >= 15 ? "level-high" : "strong") play was already winning — passing keeps team cards intact."))
                    }
                }

                // 浪费炸弹
                if combo.kind.isBomb, !goingOut {
                    let table = state.trick.tableOwner != focus ? state.trick.tableCombo : nil
                    let cheapTable = table == nil ||
                        (table!.rankValue < 12 && table!.cards.count < 4 && !table!.kind.isBomb)
                    let nooneClose = Seat.allCases
                        .filter { $0.team != focus.team }
                        .allSatisfy { (state.hands[$0]?.count ?? 0) > 6 }
                    if cheapTable && nooneClose {
                        mistakes.append(Mistake(
                            kind: .wastedBomb, stepIndex: i,
                            note: "Bombing a cheap table while no opponent is close to finishing — save it for an exit or a real threat."))
                    }
                }

                // 早烧逢人配
                let usesWildcard = combo.cards.contains { $0.isWildcard(level: level) }
                let lowValueShape = !combo.kind.isBomb && combo.kind != .straightFlush
                    && combo.cards.count <= 3 && combo.rankValue < 13
                if usesWildcard, lowValueShape, handCount > 15 {
                    mistakes.append(Mistake(
                        kind: .earlyWildcard, stepIndex: i,
                        note: "A wildcard spent early on a small \(combo.cards.count)-card play — held, it could complete a straight flush or grow a bomb."))
                }
            }
            try? engine.apply(action, by: seat)
        }
        return mistakes
    }
}
