import Foundation

/// Deterministic RNG so deals are reproducible (tutorial stacked decks,
/// fuzz tests, replays). SplitMix64.
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64
    public init(seed: UInt64) { state = seed }
    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

public enum Deck {
    /// The full 108-card Guandan deck: two standard 52-card decks + 4 jokers.
    public static func standard() -> [Card] {
        var cards: [Card] = []
        for copy: UInt8 in [0, 1] {
            for rank in Rank.suited {
                for suit in Suit.allCases {
                    cards.append(Card(rank: rank, suit: suit, copy: copy))
                }
            }
            cards.append(Card(rank: .smallJoker, suit: nil, copy: copy))
            cards.append(Card(rank: .bigJoker, suit: nil, copy: copy))
        }
        return cards
    }

    /// Shuffle and deal 27 cards to each of the 4 seats.
    public static func deal(seed: UInt64) -> [[Card]] {
        var rng = SeededGenerator(seed: seed)
        let shuffled = standard().shuffled(using: &rng)
        return (0..<4).map { seat in
            Array(shuffled[seat * 27 ..< (seat + 1) * 27])
        }
    }
}
