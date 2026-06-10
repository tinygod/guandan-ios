import Foundation

extension ComboKind {
    /// Position on the bomb ladder; nil for non-bombs.
    /// 4炸 < 5炸 < 同花顺 < 6炸 < 7炸 < 8炸 < 四大天王
    public var bombTier: Int? {
        switch self {
        case .bomb(let size) where size <= 5: return size          // 4, 5
        case .straightFlush: return 5_5                            // 55: between 5 and 6
        case .bomb(let size): return size * 10                     // 60, 70, 80
        case .jokerBomb: return 1000
        default: return nil
        }
    }
}

extension Combo {
    /// Whether self beats `other` when `other` is on the table.
    public func beats(_ other: Combo, level: Rank) -> Bool {
        switch (kind.bombTier, other.kind.bombTier) {
        case (nil, .some): return false                  // nothing beats a bomb but a bomb
        case (.some, nil): return true                   // any bomb beats any non-bomb
        case (.some(let a), .some(let b)):
            if a != b { return a > b }
            return rankValue > other.rankValue           // same tier: by rank
        case (nil, nil):
            guard kind == other.kind else { return false } // must match shape
            return rankValue > other.rankValue
        }
    }
}
