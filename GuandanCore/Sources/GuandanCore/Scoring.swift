import Foundation

public enum Scoring {
    /// Level gain for the winning team based on where the winner's PARTNER
    /// finished: 2nd → +3 (双上), 3rd → +2, 4th → +1.
    public static func levelDelta(finishOrder: [Seat]) -> (winner: Team, delta: Int) {
        precondition(finishOrder.count == 4)
        let winner = finishOrder[0].team
        let partnerIndex = finishOrder.firstIndex(of: finishOrder[0].partner)!
        switch partnerIndex {
        case 1: return (winner, 3)
        case 2: return (winner, 2)
        default: return (winner, 1)
        }
    }

    /// Apply a delta to a level, capping at Ace.
    public static func advance(_ level: Rank, by delta: Int) -> Rank {
        let suitedOrder: [Rank] = Rank.suited            // 2...A
        let index = suitedOrder.firstIndex(of: level)!
        return suitedOrder[min(index + delta, suitedOrder.count - 1)]
    }

    /// Ace-win rule (v1 simplification): the hand was played at Ace level by
    /// the winning team, and the winner's partner did not finish last.
    public static func isMatchWon(handLevel: Rank, winner: Team,
                                  winnerTeamLevel: Rank, finishOrder: [Seat]) -> Bool {
        guard winnerTeamLevel == .ace, handLevel == .ace else { return false }
        let partner = finishOrder[0].partner
        return finishOrder.last != partner
    }
}

/// Drives a match: a sequence of hands until one team wins at Ace.
public struct MatchSession: Sendable {
    public private(set) var levels: [Team: Rank] = [.northSouth: .two, .eastWest: .two]
    /// Team whose level is in play this hand (last hand's winning team;
    /// first hand: northSouth by convention — the human's team).
    public private(set) var activeTeam: Team = .northSouth
    public private(set) var lastFinishOrder: [Seat]?
    public private(set) var matchWinner: Team?
    public private(set) var handsPlayed = 0

    public init() {}

    public var activeLevel: Rank { levels[activeTeam]! }

    /// Record a finished hand and update levels.
    public mutating func recordHand(finishOrder: [Seat]) {
        precondition(matchWinner == nil)
        let (winner, delta) = Scoring.levelDelta(finishOrder: finishOrder)
        let handLevel = activeLevel
        handsPlayed += 1
        lastFinishOrder = finishOrder

        if Scoring.isMatchWon(handLevel: handLevel, winner: winner,
                              winnerTeamLevel: levels[winner]!, finishOrder: finishOrder) {
            matchWinner = winner
            return
        }
        // a team only climbs while playing its own level? No — standard:
        // winner climbs by delta regardless; next hand plays winner's level.
        levels[winner] = Scoring.advance(levels[winner]!, by: delta)
        activeTeam = winner
    }
}
