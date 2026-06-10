import XCTest
@testable import GuandanCore

final class ComboCompareTests: XCTestCase {
    let level = Rank.five

    func combo(_ cards: [Card]) -> Combo {
        guard let combo = Combo.detect(cards, level: level) else {
            fatalError("test cards do not form a combo")
        }
        return combo
    }

    func testSameShapeHigherRankWins() {
        let nines = combo([c(.nine), c(.nine, .hearts)])
        let kings = combo([c(.king), c(.king, .clubs)])
        XCTAssertTrue(kings.beats(nines, level: level))
        XCTAssertFalse(nines.beats(kings, level: level))
        XCTAssertFalse(kings.beats(kings, level: level), "equal rank does not beat")
    }

    func testLevelPairBeatsAcePair() {
        let aces = combo([c(.ace), c(.ace, .clubs)])
        let fives = combo([c(.five, .spades), c(.five, .clubs)])
        XCTAssertTrue(fives.beats(aces, level: level))
    }

    func testBigJokerPairBeatsLevelPair() {
        let fives = combo([c(.five, .spades), c(.five, .clubs)])
        let jokers = combo([c(.bigJoker), c(.bigJoker, copy: 1)])
        XCTAssertTrue(jokers.beats(fives, level: level))
    }

    func testShapeMismatchNeverBeats() {
        let pair = combo([c(.king), c(.king, .clubs)])
        let triple = combo([c(.three), c(.three, .hearts), c(.three, .clubs)])
        XCTAssertFalse(triple.beats(pair, level: level))
        let straight = combo([c(.three), c(.four), c(.five, .clubs), c(.six), c(.seven)])
        let tube = combo([c(.seven), c(.seven, .hearts), c(.eight), c(.eight, .clubs),
                          c(.nine), c(.nine, .diamonds)])
        XCTAssertFalse(tube.beats(straight, level: level))
    }

    func testStraightComparison() {
        let sevenHigh = combo([c(.three), c(.four), c(.five, .clubs), c(.six), c(.seven)])
        let aceLow = combo([c(.ace), c(.two), c(.three, .clubs), c(.four), c(.five, .diamonds)])
        let aceHigh = combo([c(.ten), c(.jack), c(.queen, .clubs), c(.king), c(.ace, .diamonds)])
        XCTAssertTrue(sevenHigh.beats(aceLow, level: level), "A-2-3-4-5 is lowest")
        XCTAssertTrue(aceHigh.beats(sevenHigh, level: level))
    }

    func testBombLadder() {
        let bomb4 = combo([c(.three), c(.three, .hearts), c(.three, .clubs), c(.three, .diamonds)])
        let bomb4high = combo([c(.ace), c(.ace, .hearts), c(.ace, .clubs), c(.ace, .diamonds)])
        let bomb5 = combo([c(.two), c(.two, .hearts), c(.two, .clubs), c(.two, .diamonds),
                           c(.two, .spades, copy: 1)])
        let flush = combo([c(.three, .clubs), c(.four, .clubs), c(.five, .clubs),
                           c(.six, .clubs), c(.seven, .clubs)])
        let bomb6 = combo([c(.four), c(.four, .hearts), c(.four, .clubs), c(.four, .diamonds),
                           c(.four, .spades, copy: 1), c(.four, .hearts, copy: 1)])
        let joker = combo([c(.bigJoker), c(.bigJoker, copy: 1), c(.smallJoker),
                           c(.smallJoker, copy: 1)])

        XCTAssertTrue(bomb4high.beats(bomb4, level: level), "same size: rank decides")
        XCTAssertTrue(bomb5.beats(bomb4high, level: level), "5 bomb beats any 4 bomb")
        XCTAssertTrue(flush.beats(bomb5, level: level), "straight flush beats 5 bomb")
        XCTAssertTrue(bomb6.beats(flush, level: level), "6 bomb beats straight flush")
        XCTAssertTrue(joker.beats(bomb6, level: level), "four jokers beat everything")

        let fullHouse = combo([c(.nine), c(.nine, .hearts), c(.nine, .clubs),
                               c(.four), c(.four, .hearts)])
        XCTAssertTrue(bomb4.beats(fullHouse, level: level), "any bomb beats non-bomb")
        XCTAssertFalse(fullHouse.beats(bomb4, level: level))
    }
}

final class WildcardTests: XCTestCase {
    let level = Rank.five
    let wild = Card(rank: .five, suit: .hearts)        // 逢人配
    let wild2 = Card(rank: .five, suit: .hearts, copy: 1)

    func testWildCompletesPair() {
        let combo = Combo.detect([c(.king), wild], level: level)
        XCTAssertEqual(combo?.kind, .pair)
        XCTAssertEqual(combo?.rankValue, 13, "wild acts as a king")
    }

    func testWildPreferredAsLevelPairWhenAlone() {
        // wild + natural level card: best interpretation is a level pair (15)
        let combo = Combo.detect([c(.five, .spades), wild], level: level)
        XCTAssertEqual(combo?.kind, .pair)
        XCTAssertEqual(combo?.rankValue, 15)
    }

    func testWildCannotBeJoker() {
        let combo = Combo.detect([c(.bigJoker), wild], level: level)
        XCTAssertNil(combo, "wildcard may not substitute a joker")
    }

    func testWildCompletesStraightFlush() {
        let combo = Combo.detect([c(.three, .clubs), c(.four, .clubs), wild,
                                  c(.six, .clubs), c(.seven, .clubs)], level: level)
        XCTAssertEqual(combo?.kind, .straightFlush, "wild fills the clubs 5")
    }

    func testTwoWildsMakeSixBomb() {
        let combo = Combo.detect([c(.nine), c(.nine, .hearts), c(.nine, .clubs),
                                  c(.nine, .diamonds), wild, wild2], level: level)
        XCTAssertEqual(combo?.kind, .bomb(size: 6))
        XCTAssertEqual(combo?.rankValue, 9)
    }

    func testWildCompletesTube() {
        let combo = Combo.detect([c(.seven), c(.seven, .hearts), c(.eight), c(.eight, .clubs),
                                  c(.nine), wild], level: level)
        XCTAssertEqual(combo?.kind, .tube)
    }

    func testWildPrefersStrongestInterpretation() {
        // 4♠4♥4♣ + wild: bomb(4) of fours beats interpreting wild elsewhere
        let combo = Combo.detect([c(.four), c(.four, .hearts), c(.four, .clubs), wild],
                                 level: level)
        XCTAssertEqual(combo?.kind, .bomb(size: 4))
    }
}
