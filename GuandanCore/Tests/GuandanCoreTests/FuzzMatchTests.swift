import XCTest
@testable import GuandanCore

final class FuzzMatchTests: XCTestCase {
    /// Bots of every difficulty play hundreds of seeded hands: everything must
    /// stay legal, terminate, and conserve cards.
    func testFuzzHands() throws {
        let botSets: [[Seat: any Bot]] = [
            [.south: HeuristicBot(difficulty: .normal), .east: HeuristicBot(difficulty: .normal),
             .north: HeuristicBot(difficulty: .normal), .west: HeuristicBot(difficulty: .normal)],
            [.south: HeuristicBot(difficulty: .easy), .east: HeuristicBot(difficulty: .hard),
             .north: HeuristicBot(difficulty: .easy), .west: HeuristicBot(difficulty: .hard)],
        ]
        var previous: [Seat]? = nil
        for seed in 0..<150 {
            for (i, bots) in botSets.enumerated() {
                let result = try MatchRunner.playBotHand(
                    seed: UInt64(seed * 10 + i), level: .five,
                    previousFinishOrder: previous, bots: bots)
                XCTAssertEqual(Set(result.finishOrder), Set(Seat.allCases),
                               "every seat appears exactly once in the order")
                XCTAssertLessThan(result.actionsTaken, 10_000)
                previous = result.finishOrder
            }
        }
    }

    /// Full matches: levels advance correctly until a winner exists.
    func testFuzzFullMatches() throws {
        for matchSeed in 0..<20 {
            var match = MatchSession()
            var previous: [Seat]? = nil
            let bots: [Seat: any Bot] = [
                .south: HeuristicBot(difficulty: .normal),
                .east: HeuristicBot(difficulty: .normal),
                .north: HeuristicBot(difficulty: .normal),
                .west: HeuristicBot(difficulty: .normal),
            ]
            var hands = 0
            while match.matchWinner == nil {
                hands += 1
                XCTAssertLessThan(hands, 200, "match must terminate")
                let result = try MatchRunner.playBotHand(
                    seed: UInt64(matchSeed * 1000 + hands), level: match.activeLevel,
                    previousFinishOrder: previous, bots: bots)
                match.recordHand(finishOrder: result.finishOrder)
                previous = result.finishOrder
            }
            XCTAssertNotNil(match.matchWinner)
            XCTAssertEqual(match.levels[match.matchWinner!], .ace)
        }
    }

    /// Card conservation inside the engine across a full hand.
    func testCardConservation() throws {
        let dealt = Deck.deal(seed: 7)
        var engine = GameEngine(level: .two,
                                hands: [.south: dealt[0], .east: dealt[1],
                                        .north: dealt[2], .west: dealt[3]],
                                firstLeader: .south)
        var rng = SeededGenerator(seed: 7)
        let bot = HeuristicBot(difficulty: .normal)
        var played: [Card] = []
        while !engine.state.isOver {
            let seat = engine.state.turn
            let action = bot.decide(engine: engine, seat: seat, rng: &rng)
            if case .play(let combo) = action { played += combo.cards }
            try engine.apply(action, by: seat)
        }
        let remaining = Seat.allCases.flatMap { engine.state.hands[$0]! }
        XCTAssertEqual(Set(played + remaining).count, 108, "no card created or lost")
    }
}
