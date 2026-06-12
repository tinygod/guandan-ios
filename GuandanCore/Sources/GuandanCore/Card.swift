import Foundation

/// Card suit. Jokers carry no suit.
public enum Suit: UInt8, CaseIterable, Hashable, Codable, Sendable {
    case spades, hearts, clubs, diamonds

    public var symbol: String {
        switch self {
        case .spades: return "♠"
        case .hearts: return "♥"
        case .clubs: return "♣"
        case .diamonds: return "♦"
        }
    }
}

/// Card rank. Natural order 2...A, then jokers above all.
/// The current *level* rank is elevated to sit between Ace and the small
/// joker for non-sequence shapes; that mapping lives in `Combo`, not here.
public enum Rank: Int, CaseIterable, Comparable, Hashable, Codable, Sendable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen = 12, king = 13, ace = 14
    case smallJoker = 16
    case bigJoker = 17

    public static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Ranks that appear with suits in a standard deck (2...A).
    public static let suited: [Rank] = [.two, .three, .four, .five, .six, .seven,
                                        .eight, .nine, .ten, .jack, .queen, .king, .ace]

    public var isJoker: Bool { self == .smallJoker || self == .bigJoker }

    public var shortName: String {
        switch self {
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        case .smallJoker: return "joker"
        case .bigJoker: return "JOKER"
        default: return String(rawValue)
        }
    }
}

/// One physical card. Two decks are used, so identical rank+suit cards are
/// distinguished by `copy` (0 or 1) to keep identity stable in the UI.
public struct Card: Hashable, Identifiable, Codable, Sendable {
    public let rank: Rank
    public let suit: Suit?
    public let copy: UInt8

    public init(rank: Rank, suit: Suit?, copy: UInt8 = 0) {
        precondition(rank.isJoker == (suit == nil), "jokers and only jokers have no suit")
        self.rank = rank
        self.suit = suit
        self.copy = copy
    }

    /// Cheap, stable identity (rank | suit | copy packed into an Int).
    public var id: Int {
        Int(rank.rawValue) << 8 | Int(suit?.rawValue ?? 8) << 4 | Int(copy)
    }

    /// Heart cards of the current level rank are wildcards (逢人配).
    public func isWildcard(level: Rank) -> Bool {
        rank == level && suit == .hearts
    }

    public var displayName: String {
        if rank.isJoker { return rank.shortName }
        return "\(suit!.symbol)\(rank.shortName)"
    }
}
