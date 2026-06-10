import Foundation

/// Orchestrates full hands/matches with bots — used by the fuzz tests and by
/// the app for the three AI seats (the human seat injects actions instead).
public enum MatchRunner {
    /// Choose a return card (还贡): lowest-strength legal return; if the
    /// receiver somehow holds no card ≤ 10, the lowest non-joker is allowed.
    public static func returnCard(from hand: [Card], level: Rank) -> Card {
        let legal = hand.filter { Tribute.isLegalReturn($0) }
        let pool = legal.isEmpty ? hand.filter { !$0.rank.isJoker } : legal
        return pool.min { a, b in
            Combo.strength(of: a.rank, level: level) < Combo.strength(of: b.rank, level: level)
        }!
    }

    public struct HandResult: Sendable {
        public let finishOrder: [Seat]
        public let actionsTaken: Int
    }

    /// Play one full hand with bots in every seat. Returns the finish order.
    /// `previousFinishOrder` triggers the tribute phase (nil for first hand).
    public static func playBotHand(seed: UInt64, level: Rank,
                                   previousFinishOrder: [Seat]?,
                                   bots: [Seat: any Bot],
                                   maxActions: Int = 10_000) throws -> HandResult {
        var rng = SeededGenerator(seed: seed)
        let dealt = Deck.deal(seed: seed)
        var hands: [Seat: [Card]] = [.south: dealt[0], .east: dealt[1],
                                     .north: dealt[2], .west: dealt[3]]
        var leader = Seat.south

        if let prev = previousFinishOrder {
            let resolution = Tribute.resolve(finishOrder: prev, hands: hands, level: level)
            if !resolution.antiTribute {
                Tribute.apply(resolution.transfers, to: &hands)
                // returns: each receiver gives back lowest legal card
                let returns = resolution.transfers.map { t in
                    Tribute.Transfer(from: t.to, to: t.from,
                                     card: returnCard(from: hands[t.to]!, level: level))
                }
                Tribute.apply(returns, to: &hands)
            }
            leader = resolution.firstLeader
        }

        var engine = GameEngine(level: level, hands: hands, firstLeader: leader)
        var actions = 0
        while !engine.state.isOver {
            actions += 1
            if actions > maxActions { throw FuzzError.didNotTerminate }
            let seat = engine.state.turn
            let bot = bots[seat]!
            let action = bot.decide(engine: engine, seat: seat, rng: &rng)
            try engine.apply(action, by: seat)
        }
        return HandResult(finishOrder: engine.state.finishOrder, actionsTaken: actions)
    }

    public enum FuzzError: Error { case didNotTerminate }
}
