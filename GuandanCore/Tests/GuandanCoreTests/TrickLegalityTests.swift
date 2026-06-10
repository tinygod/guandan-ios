import XCTest
@testable import GuandanCore

final class TrickLegalityTests: XCTestCase {
    /// Build an engine with small fixed hands for precise scenarios.
    func makeEngine(level: Rank = .two,
                    south: [Card], east: [Card], north: [Card], west: [Card],
                    leader: Seat = .south) -> GameEngine {
        GameEngine(level: level,
                   hands: [.south: south, .east: east, .north: north, .west: west],
                   firstLeader: leader)
    }

    func play(_ engine: inout GameEngine, _ cards: [Card], by seat: Seat,
              level: Rank = .two) throws {
        let combo = Combo.detect(cards, level: level)!
        try engine.apply(.play(combo), by: seat)
    }

    func testTurnOrderAndBasicTrick() throws {
        var e = makeEngine(south: [c(.three), c(.ten)], east: [c(.four), c(.ten, .hearts)],
                           north: [c(.five), c(.ten, .clubs)], west: [c(.six), c(.ten, .diamonds)])
        try play(&e, [c(.three)], by: .south)
        XCTAssertEqual(e.state.turn, .east)
        XCTAssertThrowsError(try e.apply(.pass, by: .north)) { error in
            XCTAssertEqual(error as? EngineError, .notYourTurn)
        }
        try play(&e, [c(.four)], by: .east)
        try e.apply(.pass, by: .north)
        try e.apply(.pass, by: .west)
        // south must beat the 4 or pass
        XCTAssertThrowsError(try play(&e, [c(.three)], by: .south)) { _ in }
        try e.apply(.pass, by: .south)
        // trick closed; east leads anything
        XCTAssertEqual(e.state.turn, .east)
        XCTAssertNil(e.state.trick.tableCombo)
        try play(&e, [c(.ten, .hearts)], by: .east)
    }

    func testLeaderCannotPass() {
        var e = makeEngine(south: [c(.three)], east: [c(.four)],
                           north: [c(.five)], west: [c(.six)])
        XCTAssertThrowsError(try e.apply(.pass, by: .south)) { error in
            XCTAssertEqual(error as? EngineError, .leaderCannotPass)
        }
    }

    func testCannotPlayCardsNotInHand() {
        var e = makeEngine(south: [c(.three)], east: [c(.four)],
                           north: [c(.five)], west: [c(.six)])
        XCTAssertThrowsError(try play(&e, [c(.king)], by: .south)) { error in
            XCTAssertEqual(error as? EngineError, .cardsNotInHand)
        }
    }

    func testMustMatchShape() throws {
        var e = makeEngine(south: [c(.three), c(.three, .hearts)],
                           east: [c(.king), c(.queen)],
                           north: [c(.five)], west: [c(.six)])
        try play(&e, [c(.three), c(.three, .hearts)], by: .south)
        // east cannot answer a pair with a single
        XCTAssertThrowsError(try play(&e, [c(.king)], by: .east)) { error in
            XCTAssertEqual(error as? EngineError, .mustBeatTable)
        }
    }

    func testBombBeatsAnyShape() throws {
        var e = makeEngine(south: [c(.ace), c(.ace, .hearts)],
                           east: [c(.two), c(.two, .hearts), c(.two, .clubs), c(.two, .diamonds), c(.nine)],
                           north: [c(.five)], west: [c(.six)])
        try play(&e, [c(.ace), c(.ace, .hearts)], by: .south)
        try play(&e, [c(.two), c(.two, .hearts), c(.two, .clubs), c(.two, .diamonds)], by: .east)
        XCTAssertEqual(e.state.trick.tableOwner, .east)
    }

    func testFinishAndJieFeng() throws {
        // south plays their last card; everyone passes → north (partner) leads (接风)
        var e = makeEngine(south: [c(.three)],
                           east: [c(.four), c(.nine)],
                           north: [c(.five), c(.nine, .hearts)],
                           west: [c(.six), c(.nine, .clubs)])
        try play(&e, [c(.three)], by: .south)
        XCTAssertEqual(e.state.finished, [.south])
        try e.apply(.pass, by: .east)
        try e.apply(.pass, by: .north)
        try e.apply(.pass, by: .west)
        XCTAssertEqual(e.state.turn, .north, "partner inherits the lead")
        XCTAssertNil(e.state.trick.tableCombo)
    }

    func testFinishedPlayersAreSkipped() throws {
        var e = makeEngine(south: [c(.three)],
                           east: [c(.four), c(.nine)],
                           north: [c(.five), c(.nine, .hearts)],
                           west: [c(.six), c(.nine, .clubs)])
        try play(&e, [c(.three)], by: .south)
        try play(&e, [c(.four)], by: .east)
        try e.apply(.pass, by: .north)
        try e.apply(.pass, by: .west)
        // back to east (owner), south skipped
        XCTAssertEqual(e.state.turn, .east)
    }

    func testDoubleDownEndsHandEarly() throws {
        // south then north finish → 双下, hand over with east/west at bottom
        var e = makeEngine(south: [c(.three)],
                           east: [c(.four), c(.nine)],
                           north: [c(.ten)],
                           west: [c(.six), c(.nine, .clubs)])
        try play(&e, [c(.three)], by: .south)
        try play(&e, [c(.four)], by: .east)
        try play(&e, [c(.ten)], by: .north)
        XCTAssertTrue(e.state.isOver)
        XCTAssertEqual(e.state.finished, [.south, .north])
        XCTAssertEqual(e.state.finishOrder, [.south, .north, .east, .west])
        XCTAssertThrowsError(try e.apply(.pass, by: .west)) { error in
            XCTAssertEqual(error as? EngineError, .handOver)
        }
    }

    func testThreeFinishersEndHand() throws {
        var e = makeEngine(south: [c(.three)],
                           east: [c(.four)],
                           north: [c(.five)],
                           west: [c(.six), c(.nine, .clubs)])
        try play(&e, [c(.three)], by: .south)   // south finishes (1st)
        try play(&e, [c(.four)], by: .east)     // east finishes (2nd)
        try play(&e, [c(.five)], by: .north)    // north finishes (3rd) → over
        XCTAssertTrue(e.state.isOver)
        XCTAssertEqual(e.state.finishOrder, [.south, .east, .north, .west])
    }
}
