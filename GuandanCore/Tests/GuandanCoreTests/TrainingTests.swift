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
