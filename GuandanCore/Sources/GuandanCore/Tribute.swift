import Foundation

/// Tribute (进贡/还贡) between hands.
///
/// After a hand, the loser(s) pay tribute to the winner(s):
/// - Single down (单下: loser finished 4th, partner 3rd): 4th pays the winner.
/// - Double down (双下: losers finished 3rd & 4th): both pay; the 1st finisher
///   receives the higher tribute card, the 2nd finisher the lower one.
/// - Tribute card: payer's highest-ranked card EXCLUDING heart level cards
///   (wildcards stay home). Jokers are paid if held.
/// - Return (还贡): each receiver returns any card of rank ≤ 10.
/// - Anti-tribute (抗贡): if the paying side together holds BOTH big jokers,
///   no tribute happens and the previous winner leads as usual.
/// - Lead: after single tribute the payer leads; after double tribute the
///   payer of the HIGHER card leads. After anti-tribute the previous 1st
///   finisher leads.
public enum Tribute {
    public struct Transfer: Equatable, Sendable {
        public let from: Seat
        public let to: Seat
        public let card: Card
    }

    public struct Resolution: Equatable, Sendable {
        public var transfers: [Transfer]      // tribute payments
        public var returnsDue: [(Transfer)]   // filled after receivers choose
        public var antiTribute: Bool
        public var firstLeader: Seat
    }

    /// Highest tribute-eligible card in a hand (wildcards excluded).
    public static func tributeCard(from hand: [Card], level: Rank) -> Card {
        let eligible = hand.filter { !$0.isWildcard(level: level) }
        precondition(!eligible.isEmpty, "27-card hand cannot be all wildcards")
        return eligible.max { lhs, rhs in
            Combo.strength(of: lhs.rank, level: level) < Combo.strength(of: rhs.rank, level: level)
        }!
    }

    /// Resolve the tribute phase for the new hand.
    /// - Parameters:
    ///   - finishOrder: previous hand's final order.
    ///   - hands: freshly dealt 27-card hands for the new hand.
    ///   - level: level in play for the new hand.
    public static func resolve(finishOrder: [Seat], hands: [Seat: [Card]],
                               level: Rank) -> Resolution {
        let first = finishOrder[0]
        let isDoubleDown = finishOrder[0].partner == finishOrder[1]
        let payers: [Seat] = isDoubleDown ? [finishOrder[2], finishOrder[3]] : [finishOrder[3]]

        // anti-tribute: paying side holds both big jokers
        let bigJokers = payers.flatMap { hands[$0]! }.filter { $0.rank == .bigJoker }
        if bigJokers.count == 2 {
            return Resolution(transfers: [], returnsDue: [], antiTribute: true,
                              firstLeader: first)
        }

        if isDoubleDown {
            let cardA = tributeCard(from: hands[payers[0]]!, level: level)
            let cardB = tributeCard(from: hands[payers[1]]!, level: level)
            let aHigher = Combo.strength(of: cardA.rank, level: level)
                        >= Combo.strength(of: cardB.rank, level: level)
            let highPayer = aHigher ? payers[0] : payers[1]
            let lowPayer = aHigher ? payers[1] : payers[0]
            let highCard = aHigher ? cardA : cardB
            let lowCard = aHigher ? cardB : cardA
            let second = finishOrder[1]
            return Resolution(
                transfers: [Transfer(from: highPayer, to: first, card: highCard),
                            Transfer(from: lowPayer, to: second, card: lowCard)],
                returnsDue: [], antiTribute: false, firstLeader: highPayer)
        } else {
            let payer = payers[0]
            let card = tributeCard(from: hands[payer]!, level: level)
            return Resolution(transfers: [Transfer(from: payer, to: first, card: card)],
                              returnsDue: [], antiTribute: false, firstLeader: payer)
        }
    }

    /// Whether `card` is a legal return (还贡): rank ten or below.
    public static func isLegalReturn(_ card: Card) -> Bool {
        !card.rank.isJoker && card.rank.rawValue <= 10
    }

    /// Apply transfers to hands (tribute payments and returns alike).
    public static func apply(_ transfers: [Transfer], to hands: inout [Seat: [Card]]) {
        for t in transfers {
            precondition(hands[t.from]!.contains(t.card), "transfer card must be held")
            hands[t.from]!.removeAll { $0 == t.card }
            hands[t.to]!.append(t.card)
        }
    }
}
