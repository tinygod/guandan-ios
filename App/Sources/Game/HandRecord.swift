import Foundation
import GuandanCore

/// Everything needed to replay a finished hand step by step.
struct HandRecord: Identifiable {
    let id = UUID()
    let level: Rank
    let initialHands: [Seat: [Card]]
    let firstLeader: Seat
    let actions: [(seat: Seat, action: PlayerAction)]
    let finishOrder: [Seat]

    /// Engine state after applying the first `steps` actions.
    func engineState(afterSteps steps: Int) -> GameEngine {
        var engine = GameEngine(level: level, hands: initialHands, firstLeader: firstLeader)
        for (seat, action) in actions.prefix(steps) {
            try? engine.apply(action, by: seat)
        }
        return engine
    }

    /// The hard bot's choice in the position BEFORE action `index` —
    /// the coach's "what I would do" for review annotations.
    func coachChoice(beforeStep index: Int) -> PlayerAction? {
        guard index < actions.count else { return nil }
        let engine = engineState(afterSteps: index)
        guard !engine.state.isOver else { return nil }
        var rng = SeededGenerator(seed: 99)
        return HeuristicBot(difficulty: .hard)
            .decide(engine: engine, seat: engine.state.turn, rng: &rng)
    }
}

extension PlayerAction {
    var reviewDescription: String {
        switch self {
        case .pass: return "Pass"
        case .play(let combo): return combo.cards.map(\.displayName).joined(separator: " ")
        }
    }
}

// MARK: 局势图 — per-move momentum evaluation

extension HandRecord {
    struct MomentumPoint: Identifiable {
        let id: Int          // step * 4 + seat
        let step: Int
        let seat: Seat
        let score: Double
        let bombPlayed: Bool
    }

    /// Heuristic 0–100 winning-odds curve for every seat at every step.
    func momentum() -> [MomentumPoint] {
        var points: [MomentumPoint] = []
        var engine = GameEngine(level: level, hands: initialHands, firstLeader: firstLeader)

        func snapshot(step: Int, bombSeat: Seat?) {
            let counts = Seat.allCases.map { Double(engine.state.hands[$0]?.count ?? 0) }
            let avg = counts.reduce(0, +) / 4
            for seat in Seat.allCases {
                let hand = engine.state.hands[seat] ?? []
                var score = 50.0
                if let i = engine.state.finished.firstIndex(of: seat) {
                    score = [95.0, 80, 25, 8][i]
                } else {
                    let groups = HandPlanner.partition(hand, level: level)
                    let bombs = groups.filter {
                        $0.kind == .bomb || $0.kind == .straightFlush || $0.kind == .jokerBomb
                    }.count
                    let tops = hand.filter {
                        $0.rank == .bigJoker || ($0.rank == level && !$0.isWildcard(level: level))
                    }.count
                    let deadSingles = groups.filter {
                        $0.kind == .single && $0.cards[0].rank.rawValue <= 10
                    }.count
                    score += Double(bombs) * 7 + Double(tops) * 2.5
                          - Double(deadSingles) * 2 + (avg - Double(hand.count)) * 1.8
                }
                points.append(MomentumPoint(id: step * 4 + seat.rawValue, step: step,
                                            seat: seat, score: min(95, max(5, score)),
                                            bombPlayed: bombSeat == seat))
            }
        }

        snapshot(step: 0, bombSeat: nil)
        for (i, (seat, action)) in actions.enumerated() {
            var bombSeat: Seat?
            if case .play(let combo) = action, combo.kind.isBomb { bombSeat = seat }
            try? engine.apply(action, by: seat)
            snapshot(step: i + 1, bombSeat: bombSeat)
        }
        return points
    }
}
