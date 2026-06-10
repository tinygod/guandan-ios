import XCTest
@testable import GuandanCore

final class ScoringTests: XCTestCase {
    func testLevelDeltas() {
        XCTAssertEqual(Scoring.levelDelta(finishOrder: [.south, .north, .east, .west]).delta, 3)
        XCTAssertEqual(Scoring.levelDelta(finishOrder: [.south, .east, .north, .west]).delta, 2)
        XCTAssertEqual(Scoring.levelDelta(finishOrder: [.south, .east, .west, .north]).delta, 1)
        XCTAssertEqual(Scoring.levelDelta(finishOrder: [.east, .south, .west, .north]).winner, .eastWest)
    }

    func testAdvanceCapsAtAce() {
        XCTAssertEqual(Scoring.advance(.queen, by: 3), .ace)
        XCTAssertEqual(Scoring.advance(.two, by: 3), .five)
        XCTAssertEqual(Scoring.advance(.ace, by: 1), .ace)
    }

    func testMatchSessionFlow() {
        var match = MatchSession()
        XCTAssertEqual(match.activeLevel, .two)
        // north-south double-up
        match.recordHand(finishOrder: [.south, .north, .east, .west])
        XCTAssertEqual(match.levels[.northSouth], .five)
        XCTAssertEqual(match.activeTeam, .northSouth)
        XCTAssertEqual(match.activeLevel, .five)
        // east-west win the next hand at NS's level 5
        match.recordHand(finishOrder: [.east, .south, .west, .north])
        XCTAssertEqual(match.levels[.eastWest], .four)
        XCTAssertEqual(match.activeLevel, .four)
        XCTAssertNil(match.matchWinner)
    }

    func testAceWinRequiresPartnerNotLast() {
        var match = MatchSession()
        // climb NS to ace quickly: 4 double-ups: 2→5→8→J→A
        for _ in 0..<4 { match.recordHand(finishOrder: [.south, .north, .east, .west]) }
        XCTAssertEqual(match.levels[.northSouth], .ace)
        XCTAssertNil(match.matchWinner)
        // playing at ace: south 1st but north LAST → no win, stays at A
        match.recordHand(finishOrder: [.south, .east, .west, .north])
        XCTAssertNil(match.matchWinner)
        XCTAssertEqual(match.levels[.northSouth], .ace)
        // ace hand with partner 3rd → match won
        match.recordHand(finishOrder: [.south, .east, .north, .west])
        XCTAssertEqual(match.matchWinner, .northSouth)
    }
}

final class TributeTests: XCTestCase {
    let level = Rank.two

    func testTributeCardExcludesWildcards() {
        let hand = [Card(rank: .two, suit: .hearts),  // wildcard at level 2
                    c(.king), c(.nine)]
        XCTAssertEqual(Tribute.tributeCard(from: hand, level: level), c(.king))
    }

    func testTributeCardPrefersJokerThenLevel() {
        let hand = [c(.bigJoker), c(.two, .spades), c(.ace)]
        XCTAssertEqual(Tribute.tributeCard(from: hand, level: level), c(.bigJoker))
        let hand2 = [c(.two, .spades), c(.ace), c(.nine)]
        XCTAssertEqual(Tribute.tributeCard(from: hand2, level: level), c(.two, .spades),
                       "spade level card outranks ace")
    }

    func testSingleDownTribute() {
        var hands: [Seat: [Card]] = [
            .south: [c(.three)], .east: [c(.four)], .north: [c(.five)],
            .west: [c(.king), c(.six)],
        ]
        let r = Tribute.resolve(finishOrder: [.south, .east, .north, .west],
                                hands: hands, level: level)
        XCTAssertFalse(r.antiTribute)
        XCTAssertEqual(r.transfers, [.init(from: .west, to: .south, card: c(.king))])
        XCTAssertEqual(r.firstLeader, .west, "payer leads")
        Tribute.apply(r.transfers, to: &hands)
        XCTAssertTrue(hands[.south]!.contains(c(.king)))
        XCTAssertFalse(hands[.west]!.contains(c(.king)))
    }

    func testDoubleDownTribute() {
        let hands: [Seat: [Card]] = [
            .south: [c(.three)], .north: [c(.five)],
            .east: [c(.queen), c(.four)], .west: [c(.king), c(.six)],
        ]
        let r = Tribute.resolve(finishOrder: [.south, .north, .east, .west],
                                hands: hands, level: level)
        XCTAssertEqual(r.transfers.count, 2)
        XCTAssertEqual(r.transfers[0], .init(from: .west, to: .south, card: c(.king)),
                       "higher card to 1st finisher")
        XCTAssertEqual(r.transfers[1], .init(from: .east, to: .north, card: c(.queen)))
        XCTAssertEqual(r.firstLeader, .west, "higher payer leads")
    }

    func testAntiTribute() {
        let hands: [Seat: [Card]] = [
            .south: [c(.three)], .north: [c(.five)],
            .east: [c(.bigJoker), c(.four)], .west: [c(.bigJoker, copy: 1), c(.six)],
        ]
        let r = Tribute.resolve(finishOrder: [.south, .north, .east, .west],
                                hands: hands, level: level)
        XCTAssertTrue(r.antiTribute)
        XCTAssertTrue(r.transfers.isEmpty)
        XCTAssertEqual(r.firstLeader, .south, "previous winner leads")
    }

    func testLegalReturn() {
        XCTAssertTrue(Tribute.isLegalReturn(c(.ten)))
        XCTAssertTrue(Tribute.isLegalReturn(c(.two)))
        XCTAssertFalse(Tribute.isLegalReturn(c(.jack)))
        XCTAssertFalse(Tribute.isLegalReturn(c(.bigJoker)))
    }
}
