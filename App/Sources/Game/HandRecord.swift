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
