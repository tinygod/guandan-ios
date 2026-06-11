import XCTest
@testable import GuandanCore

final class DealRecipeTests: XCTestCase {
    func testRequiredCardsLandInSeat() {
        let bomb = [c(.five, .spades), c(.five, .hearts), c(.five, .clubs), c(.five, .diamonds)]
        let hands = DealRecipe.deal(seed: 1, required: [.south: bomb])
        let southRanks = hands[.south]!.filter { $0.rank == .five }
        XCTAssertGreaterThanOrEqual(southRanks.count, 4, "south must hold the recipe bomb")
        XCTAssertEqual(hands[.south]!.count, 27)
        XCTAssertEqual(Set(Seat.allCases.flatMap { hands[$0]! }).count, 108)
    }

    func testDeterministicBySeed() {
        let req: [Seat: [Card]] = [.north: [c(.bigJoker, nil), c(.bigJoker, nil)]]
        let a = DealRecipe.deal(seed: 9, required: req)
        let b = DealRecipe.deal(seed: 9, required: req)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a[.north]!.filter { $0.rank == .bigJoker }.count, 2)
    }

    func testRecipeForMultipleSeats() {
        let hands = DealRecipe.deal(seed: 3, required: [
            .south: [c(.two, .hearts)],                  // wildcard at level 2
            .north: [c(.king, .spades), c(.king, .hearts)],
        ])
        XCTAssertTrue(hands[.south]!.contains { $0.rank == .two && $0.suit == .hearts })
        XCTAssertEqual(hands[.north]!.filter { $0.rank == .king }.count >= 2, true)
    }
}

final class MistakeDetectorTests: XCTestCase {
    let level = Rank.two

    func testBeatPartnerFlagged() {
        // partner (north) owns a strong table; south beats it anyway
        let hands: [Seat: [Card]] = [
            .north: [c(.king), c(.king, .hearts)],
            .south: [c(.ace), c(.ace, .hearts), c(.three)],
            .east: [c(.four), c(.five)], .west: [c(.six), c(.seven)],
        ]
        let actions: [(Seat, PlayerAction)] = [
            (.north, .play(Combo.detect([c(.king), c(.king, .hearts)], level: level)!)),
            (.west, .pass),
            (.south, .play(Combo.detect([c(.ace), c(.ace, .hearts)], level: level)!)),
        ]
        let mistakes = MistakeDetector.analyze(level: level, initialHands: hands,
                                               firstLeader: .north, actions: actions)
        XCTAssertEqual(mistakes.map(\.kind), [.beatPartner])
        XCTAssertEqual(mistakes[0].stepIndex, 2)
    }

    func testBeatPartnerNotFlaggedWhenGoingOut() {
        let hands: [Seat: [Card]] = [
            .north: [c(.king), c(.king, .hearts), c(.three, .clubs)],
            .south: [c(.ace), c(.ace, .hearts)],
            .east: [c(.four), c(.five)], .west: [c(.six), c(.seven)],
        ]
        let actions: [(Seat, PlayerAction)] = [
            (.north, .play(Combo.detect([c(.king), c(.king, .hearts)], level: level)!)),
            (.west, .pass),
            (.south, .play(Combo.detect([c(.ace), c(.ace, .hearts)], level: level)!)),
        ]
        let mistakes = MistakeDetector.analyze(level: level, initialHands: hands,
                                               firstLeader: .north, actions: actions)
        XCTAssertTrue(mistakes.isEmpty, "finishing with the play is never a mistake")
    }

    func testWastedBombFlagged() {
        let bomb = [c(.nine), c(.nine, .hearts), c(.nine, .clubs), c(.nine, .diamonds)]
        let south = bomb + [c(.three), c(.four), c(.five), c(.six), c(.seven), c(.eight),
                            c(.ten), c(.jack)]
        let filler = Array(Deck.standard().filter { card in
            !south.contains(where: { $0.id == card.id })
        })
        let hands: [Seat: [Card]] = [
            .south: south,
            .east: Array(filler[0..<12]),
            .north: Array(filler[12..<24]),
            .west: Array(filler[24..<36]),
        ]
        let eastSingle = hands[.east]!.first {
            $0.rank.rawValue >= 3 && $0.rank.rawValue <= 8 && $0.rank != level
        }!

        // east leads a cheap single; south bombs it with 12 cards in hand
        let actions: [(Seat, PlayerAction)] = [
            (.east, .play(Combo.detect([eastSingle], level: level)!)),
            (.north, .pass),
            (.west, .pass),
            (.south, .play(Combo.detect(bomb, level: level)!)),
        ]
        let mistakes = MistakeDetector.analyze(level: level, initialHands: hands,
                                               firstLeader: .east, actions: actions)
        XCTAssertTrue(mistakes.contains { $0.kind == .wastedBomb })
    }

    func testEarlyWildcardFlagged() {
        let wild = Card(rank: .two, suit: .hearts)   // level 2 wildcard
        var south: [Card] = [wild, c(.seven)]
        let filler = Deck.standard().filter { card in
            !(card.rank == .two && card.suit == .hearts && card.copy == 0)
                && !(card.rank == .seven && card.suit == .spades && card.copy == 0)
        }
        south += Array(filler[0..<25])
        let hands: [Seat: [Card]] = [
            .south: south,
            .east: Array(filler[25..<52]),
            .north: Array(filler[52..<79]),
            .west: Array(filler[79..<106]),
        ]
        // south leads pair: 7 + wildcard (a cheap pair burning the wild)
        let combo = Combo.detect([c(.seven), wild], level: level)!
        let mistakes = MistakeDetector.analyze(
            level: level, initialHands: hands, firstLeader: .south,
            actions: [(.south, .play(combo))])
        XCTAssertTrue(mistakes.contains { $0.kind == .earlyWildcard })
    }
}

final class LeadOrderTests: XCTestCase {
    let level = Rank.two

    /// South holds lone singles 3 and 6 plus other structure; leading the 3
    /// first violates the tail-card principle.
    func makeHands(southExtra: [Card]) -> [Seat: [Card]] {
        let south = [c(.three, .clubs), c(.six, .diamonds)] + southExtra
        let filler = Deck.standard().filter { card in
            !south.contains(where: { $0.id == card.id })
        }
        return [.south: south,
                .east: Array(filler[0..<10]),
                .north: Array(filler[10..<20]),
                .west: Array(filler[20..<30])]
    }

    var structure: [Card] {
        [c(.nine), c(.nine, .hearts), c(.queen), c(.queen, .hearts),
         c(.king), c(.king, .hearts), c(.ace), c(.ace, .hearts)]
    }

    func testLeadingSmallestLoneSingleFlagged() {
        let hands = makeHands(southExtra: structure)
        let mistakes = MistakeDetector.analyze(
            level: level, initialHands: hands, firstLeader: .south,
            actions: [(.south, .play(Combo.detect([c(.three, .clubs)], level: level)!))])
        XCTAssertTrue(mistakes.contains { $0.kind == .wrongLeadOrder },
                      "leading the 3 while holding a lone 6 should be flagged")
    }

    func testLeadingBiggerSmallSingleNotFlagged() {
        let hands = makeHands(southExtra: structure)
        let mistakes = MistakeDetector.analyze(
            level: level, initialHands: hands, firstLeader: .south,
            actions: [(.south, .play(Combo.detect([c(.six, .diamonds)], level: level)!))])
        XCTAssertFalse(mistakes.contains { $0.kind == .wrongLeadOrder },
                       "leading the 6 first (keeping 3 as tail) is correct")
    }
}

final class BotStyleTests: XCTestCase {
    /// Styled bots must stay legal and terminate across many seeded hands.
    func testStyledBotsPlayLegalHands() throws {
        let bots: [Seat: any Bot] = [
            .south: HeuristicBot(difficulty: .hard, style: .controller),
            .east: HeuristicBot(difficulty: .hard, style: .charger),
            .north: HeuristicBot(difficulty: .normal, style: .controller),
            .west: HeuristicBot(difficulty: .normal, style: .charger),
        ]
        var previous: [Seat]? = nil
        for seed in 0..<60 {
            let result = try MatchRunner.playBotHand(seed: UInt64(seed + 7777), level: .five,
                                                     previousFinishOrder: previous, bots: bots)
            XCTAssertEqual(Set(result.finishOrder), Set(Seat.allCases))
            previous = result.finishOrder
        }
    }
}

final class PlannerBotTests: XCTestCase {
    let level = Rank.two

    func fill(_ used: [Card], counts: [Int]) -> [[Card]] {
        let pool = Deck.standard().filter { card in
            !used.contains(where: { $0.id == card.id })
        }
        var result: [[Card]] = []
        var i = 0
        for n in counts { result.append(Array(pool[i..<(i+n)])); i += n }
        return result
    }

    /// Holding a lone 9 and a planned pair of Kings, the bot answers a cheap
    /// single with the 9 — it does not split the pair.
    func testDoesNotBreakPairForCheapSingle() throws {
        let south = [c(.nine), c(.king), c(.king, .hearts),
                     c(.queen), c(.queen, .hearts), c(.seven), c(.seven, .hearts),
                     c(.six), c(.six, .hearts), c(.four), c(.four, .hearts), c(.three)]
        let others = fill(south, counts: [12, 12, 12])
        var engine = GameEngine(level: level,
                                hands: [.south: south, .east: others[0],
                                        .north: others[1], .west: others[2]],
                                firstLeader: .east)
        // east leads a small single the bot must answer
        let eastSingle = others[0].first {
            $0.rank.rawValue >= 3 && $0.rank.rawValue <= 8 && $0.rank != level
                && !$0.isWildcard(level: level)
        }!
        try engine.apply(.play(Combo.detect([eastSingle], level: level)!), by: .east)
        try engine.apply(.pass, by: .north)
        try engine.apply(.pass, by: .west)

        var rng = SeededGenerator(seed: 1)
        let action = HeuristicBot(difficulty: .hard)
            .decide(engine: engine, seat: .south, rng: &rng)
        if case .play(let combo) = action {
            XCTAssertEqual(combo.kind, .single)
            XCTAssertNotEqual(combo.cards[0].rank, .king,
                              "must not split the planned pair of Kings")
            XCTAssertNotEqual(combo.cards[0].rank, .queen,
                              "must not split the planned pair of Queens")
        } else {
            XCTFail("bot should beat a cheap single while holding lone 9")
        }
    }

    /// New bots must stay legal across many seeded hands.
    func testPlannerBotFuzz() throws {
        let bots: [Seat: any Bot] = [
            .south: HeuristicBot(difficulty: .hard, style: .controller),
            .east: HeuristicBot(difficulty: .normal, style: .charger),
            .north: HeuristicBot(difficulty: .hard, style: .balanced),
            .west: HeuristicBot(difficulty: .normal, style: .balanced),
        ]
        var previous: [Seat]? = nil
        for seed in 0..<80 {
            let result = try MatchRunner.playBotHand(seed: UInt64(seed + 31337), level: .five,
                                                     previousFinishOrder: previous, bots: bots)
            XCTAssertEqual(Set(result.finishOrder), Set(Seat.allCases))
            previous = result.finishOrder
        }
    }
}

final class PassPhilosophyTests: XCTestCase {
    let level = Rank.two

    /// Early game, cheap single on the table, our cheapest answer is a lone
    /// King — the disciplined bot passes instead of burning a top card.
    func testConservesBigCardOnCheapTrickEarly() throws {
        // 16 cards, smallest lone single is the King (others are pairs/runs)
        let south = [c(.king),
                     c(.queen), c(.queen, .hearts), c(.jack), c(.jack, .hearts),
                     c(.ten), c(.ten, .hearts), c(.nine), c(.nine, .hearts),
                     c(.eight), c(.eight, .hearts), c(.seven), c(.seven, .hearts),
                     c(.six), c(.six, .hearts), c(.ace)]
        let pool = Deck.standard().filter { card in
            !south.contains(where: { $0.id == card.id })
        }
        let east = Array(pool[0..<16]), north = Array(pool[16..<32]), west = Array(pool[32..<48])
        var engine = GameEngine(level: level,
                                hands: [.south: south, .east: east,
                                        .north: north, .west: west],
                                firstLeader: .east)
        let eastSmall = east.first {
            $0.rank.rawValue >= 3 && $0.rank.rawValue <= 5 && $0.rank != level
                && !$0.isWildcard(level: level)
        }!
        try engine.apply(.play(Combo.detect([eastSmall], level: level)!), by: .east)
        try engine.apply(.pass, by: .north)
        try engine.apply(.pass, by: .west)

        var rng = SeededGenerator(seed: 2)
        let balanced = HeuristicBot(difficulty: .hard, style: .balanced)
            .decide(engine: engine, seat: .south, rng: &rng)
        if case .play(let combo) = balanced {
            XCTAssertLessThan(combo.rankValue, 12,
                              "should not burn K/A on a cheap early trick")
        }
        // controllers definitely pass here
        let controller = HeuristicBot(difficulty: .hard, style: .controller)
            .decide(engine: engine, seat: .south, rng: &rng)
        if case .play(let combo) = controller {
            XCTAssertLessThan(combo.rankValue, 12, "controller must conserve")
        }
    }
}
