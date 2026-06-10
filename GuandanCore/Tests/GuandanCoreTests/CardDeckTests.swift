import XCTest
@testable import GuandanCore

final class CardDeckTests: XCTestCase {
    func testDeckHas108Cards() {
        XCTAssertEqual(Deck.standard().count, 108)
    }

    func testDeckComposition() {
        let deck = Deck.standard()
        XCTAssertEqual(Set(deck).count, 108, "all cards distinct by identity")
        XCTAssertEqual(deck.filter { $0.rank == .bigJoker }.count, 2)
        XCTAssertEqual(deck.filter { $0.rank == .smallJoker }.count, 2)
        // every suited rank appears twice per suit
        for rank in Rank.suited {
            for suit in Suit.allCases {
                XCTAssertEqual(deck.filter { $0.rank == rank && $0.suit == suit }.count, 2,
                               "\(suit)\(rank) should have 2 copies")
            }
        }
    }

    func testDealIsDeterministicBySeed() {
        let a = Deck.deal(seed: 42)
        let b = Deck.deal(seed: 42)
        let c = Deck.deal(seed: 43)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertEqual(a.map(\.count), [27, 27, 27, 27])
        XCTAssertEqual(Set(a.flatMap { $0 }).count, 108, "deal partitions the deck")
    }

    func testWildcardIsHeartLevelCard() {
        let heartFive = Card(rank: .five, suit: .hearts)
        let spadeFive = Card(rank: .five, suit: .spades)
        let heartSix = Card(rank: .six, suit: .hearts)
        XCTAssertTrue(heartFive.isWildcard(level: .five))
        XCTAssertFalse(spadeFive.isWildcard(level: .five))
        XCTAssertFalse(heartSix.isWildcard(level: .five))
    }
}
