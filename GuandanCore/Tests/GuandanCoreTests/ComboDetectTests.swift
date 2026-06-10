import XCTest
@testable import GuandanCore

/// Card-building helpers shared by test files.
func c(_ rank: Rank, _ suit: Suit? = .spades, copy: UInt8 = 0) -> Card {
    Card(rank: rank, suit: rank.isJoker ? nil : suit, copy: copy)
}

final class ComboDetectTests: XCTestCase {
    let level = Rank.five  // hearts-5 is the wildcard in most tests

    func detect(_ cards: [Card]) -> Combo? { Combo.detect(cards, level: level) }

    // MARK: same-rank shapes

    func testSingle() {
        let combo = detect([c(.nine)])
        XCTAssertEqual(combo?.kind, .single)
        XCTAssertEqual(combo?.rankValue, 9)
    }

    func testSingleLevelCardIsElevated() {
        let combo = detect([c(.five, .spades)])
        XCTAssertEqual(combo?.kind, .single)
        XCTAssertEqual(combo?.rankValue, 15, "level card sits above ace")
    }

    func testPairAndRejectMismatchedPair() {
        XCTAssertEqual(detect([c(.king), c(.king, .hearts)])?.kind, .pair)
        XCTAssertNil(detect([c(.king), c(.queen)]))
    }

    func testJokerPairOK_MixedJokersRejected() {
        XCTAssertEqual(detect([c(.bigJoker), c(.bigJoker, copy: 1)])?.kind, .pair)
        XCTAssertNil(detect([c(.bigJoker), c(.smallJoker)]))
    }

    func testTripleAndBombs() {
        XCTAssertEqual(detect([c(.eight), c(.eight, .hearts), c(.eight, .clubs)])?.kind, .triple)
        let four = [c(.eight), c(.eight, .hearts), c(.eight, .clubs), c(.eight, .diamonds)]
        XCTAssertEqual(detect(four)?.kind, .bomb(size: 4))
        let five = four + [c(.eight, .spades, copy: 1)]
        XCTAssertEqual(detect(five)?.kind, .bomb(size: 5))
    }

    func testJokerBomb() {
        let cards = [c(.bigJoker), c(.bigJoker, copy: 1), c(.smallJoker), c(.smallJoker, copy: 1)]
        XCTAssertEqual(detect(cards)?.kind, .jokerBomb)
    }

    // MARK: full house

    func testFullHouse() {
        let combo = detect([c(.nine), c(.nine, .hearts), c(.nine, .clubs),
                            c(.four), c(.four, .hearts)])
        XCTAssertEqual(combo?.kind, .fullHouse)
        XCTAssertEqual(combo?.rankValue, 9, "anchored on the triple")
    }

    // MARK: sequences

    func testStraightMixedSuits() {
        let combo = detect([c(.three), c(.four, .hearts), c(.five, .clubs), c(.six), c(.seven)])
        XCTAssertEqual(combo?.kind, .straight)
        XCTAssertEqual(combo?.rankValue, 7)
    }

    func testAceLowStraight() {
        let combo = detect([c(.ace), c(.two, .hearts), c(.three), c(.four), c(.five, .clubs)])
        XCTAssertEqual(combo?.kind, .straight)
        XCTAssertEqual(combo?.rankValue, 5, "A-2-3-4-5 is five-high")
    }

    func testAceHighStraight() {
        let combo = detect([c(.ten), c(.jack), c(.queen, .hearts), c(.king), c(.ace, .clubs)])
        XCTAssertEqual(combo?.kind, .straight)
        XCTAssertEqual(combo?.rankValue, 14)
    }

    func testStraightFlush() {
        let combo = detect([c(.three), c(.four), c(.six), c(.seven), c(.five, .spades)])
        XCTAssertEqual(combo?.kind, .straightFlush)
    }

    func testLevelCardCountsNaturallyInStraight() {
        // level five (spade, not wild) inside 3-4-5-6-7 — natural position
        let combo = detect([c(.three), c(.four, .hearts), c(.five, .clubs), c(.six), c(.seven)])
        XCTAssertNotNil(combo)
    }

    func testTube() {
        let combo = detect([c(.seven), c(.seven, .hearts), c(.eight), c(.eight, .clubs),
                            c(.nine), c(.nine, .diamonds)])
        XCTAssertEqual(combo?.kind, .tube)
        XCTAssertEqual(combo?.rankValue, 9)
    }

    func testPlate() {
        let combo = detect([c(.queen), c(.queen, .hearts), c(.queen, .clubs),
                            c(.king), c(.king, .hearts), c(.king, .clubs)])
        XCTAssertEqual(combo?.kind, .plate)
        XCTAssertEqual(combo?.rankValue, 13)
    }

    // MARK: rejects

    func testRejects() {
        XCTAssertNil(detect([c(.three), c(.four), c(.five), c(.six)]), "4-card run is nothing")
        XCTAssertNil(detect([c(.three), c(.four), c(.five), c(.six), c(.eight)]), "gap")
        XCTAssertNil(detect([c(.king), c(.king, .hearts), c(.ace), c(.two), c(.two, .hearts)]),
                     "K-K-A-2-2 does not wrap")
        XCTAssertNil(detect([]))
        XCTAssertNil(detect([c(.queen, .hearts), c(.king), c(.ace), c(.two), c(.three)]),
                     "Q-K-A-2-3 does not wrap")
    }
}
