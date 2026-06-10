import XCTest
@testable import GuandanCore

final class HandPlannerTests: XCTestCase {
    let level = Rank.two

    func testPartitionCoversAllCardsOnce() {
        for seed in 0..<30 {
            let hand = Deck.deal(seed: UInt64(seed))[0]
            let groups = HandPlanner.partition(hand, level: level)
            let all = groups.flatMap(\.cards)
            XCTAssertEqual(Set(all.map(\.id)).count, 27, "seed \(seed): exact cover")
            XCTAssertEqual(all.count, 27)
        }
    }

    func testFindsBombAndStraightFlush() {
        let hand = [c(.nine), c(.nine, .hearts), c(.nine, .clubs), c(.nine, .diamonds),
                    c(.three, .clubs), c(.four, .clubs), c(.five, .clubs),
                    c(.six, .clubs), c(.seven, .clubs),
                    c(.king), c(.king, .hearts), c(.ace)]
        let groups = HandPlanner.partition(hand, level: level)
        XCTAssertTrue(groups.contains { $0.kind == .bomb && $0.cards.count == 4 })
        XCTAssertTrue(groups.contains { $0.kind == .straightFlush })
        XCTAssertTrue(groups.contains { $0.kind == .pair })
        XCTAssertTrue(groups.contains { $0.kind == .single })
    }

    func testWildcardsHeldSeparately() {
        let hand = [Card(rank: .two, suit: .hearts), c(.king), c(.king, .hearts)]
        let groups = HandPlanner.partition(hand, level: level)
        XCTAssertEqual(groups.first?.kind, .wildcard)
    }

    func testTubeAndPlate() {
        let tube = [c(.seven), c(.seven, .hearts), c(.eight), c(.eight, .clubs),
                    c(.nine), c(.nine, .diamonds)]
        XCTAssertTrue(HandPlanner.partition(tube, level: level)
            .contains { $0.kind == .tube })
        let plate = [c(.queen), c(.queen, .hearts), c(.queen, .clubs),
                     c(.king), c(.king, .hearts), c(.king, .clubs)]
        XCTAssertTrue(HandPlanner.partition(plate, level: level)
            .contains { $0.kind == .plate })
    }
}
