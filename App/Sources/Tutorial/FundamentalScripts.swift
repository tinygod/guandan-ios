import Foundation
import GuandanCore

/// Scripted lessons: 4 Follow or Pass, 9 The Tail Card (尾牌原理).
extension LessonScripts {
    private static func card(_ rank: Rank, _ suit: Suit?, _ copy: UInt8 = 0) -> Card {
        Card(rank: rank, suit: suit, copy: copy)
    }

    // MARK: Lesson 4 — Follow or Pass

    static var followOrPass: ScriptedLesson {
        let s5a = card(.five, .spades), s5b = card(.five, .hearts)
        let s8 = card(.eight, .clubs), sJ = card(.jack, .diamonds)
        let sA = card(.ace, .spades), s3 = card(.three, .clubs)

        let e7 = card(.seven, .diamonds)
        let wQ = card(.queen, .spades)
        let w3a = card(.three, .spades), w3b = card(.three, .hearts)
        let n10a = card(.ten, .hearts), n10b = card(.ten, .clubs)
        let n6 = card(.six, .hearts)
        let w8 = card(.eight, .diamonds)

        return ScriptedLesson(
            lessonId: 4,
            title: "Follow or Pass",
            level: .two,
            hands: [
                .south: [s5a, s5b, s8, sJ, sA, s3],
                .east: [e7, card(.four, .spades), card(.four, .hearts), card(.ten, .spades),
                        card(.queen, .diamonds), card(.six, .clubs)],
                .north: [n10a, n10b, n6, card(.king, .spades), card(.seven, .clubs),
                         card(.eight, .hearts)],
                .west: [wQ, w3a, w3b, w8, card(.nine, .diamonds), card(.jack, .clubs)],
            ],
            firstLeader: .east,
            steps: [
                .coach("Rule one of following: match the SHAPE, beat the rank — or pass. Rule two, the one nobody teaches: beating is OPTIONAL. Passing is a weapon."),
                .botPlays(.east, [e7], "Lena leads a single 7. Only a higher single answers it."),
                .botPlays(.north, nil, "Coach Wu waits…"),
                .botPlays(.west, nil, "Marco too."),
                .humanPlay([sJ], "Beat it with the Jack — never spend more than the trick needs."),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, [wQ], "Marco tops you with a Queen."),
                .coach("Your turn against the Queen. Your Ace CAN beat it. But an Ace spent here is an Ace you won't have when it matters."),
                .humanPass("Pass — and feel how little it costs."),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, "Nobody fights. Marco's trick."),
                .botPlays(.west, [w3a, w3b], "He leads a small pair."),
                .humanPlay([s5a, s5b], "Pairs answer pairs — your 5s do the job."),
                .botPlays(.east, nil, nil),
                .botPlays(.north, [n10a, n10b], "Coach Wu strengthens the team's grip with 10s."),
                .botPlays(.west, nil, nil),
                .humanPass("You know this one already: never outbid your partner. Pass."),
                .botPlays(.east, nil, "The trick is Coach Wu's."),
                .botPlays(.north, [n6], "He leads a 6."),
                .botPlays(.west, [w8], "Marco bumps it to an 8."),
                .humanPlay([sA], "NOW the Ace earns its keep — take the trick!"),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, "All pass — the lead is yours."),
                .humanPlay([s8], "Two cards left. Lead the 8 first, keep the 3 for last (you'll learn why in Stage 2)."),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, nil),
                .humanPlay([s3], "And out! 🎉"),
                .finish("You beat only when it was worth it, passed twice on purpose, and still finished first. That's the follow-or-pass mindset."),
            ])
    }

    // MARK: Lesson 9 — The Tail Card (尾牌原理)

    static var tailCard: ScriptedLesson {
        let s3 = card(.three, .clubs), s6 = card(.six, .diamonds)
        let s8a = card(.eight, .spades), s8b = card(.eight, .hearts)
        let sAa = card(.ace, .spades), sAb = card(.ace, .hearts)
        let sK = card(.king, .diamonds)

        let e10 = card(.ten, .diamonds)
        let e4a = card(.four, .spades), e4b = card(.four, .hearts)

        return ScriptedLesson(
            lessonId: 9,
            title: "The Tail Card",
            level: .two,
            hands: [
                .south: [s3, s6, s8a, s8b, sAa, sAb, sK],
                .east: [e10, e4a, e4b, card(.jack, .clubs), card(.queen, .clubs),
                        card(.seven, .diamonds), card(.nine, .diamonds)],
                .north: [card(.five, .spades), card(.seven, .clubs), card(.nine, .clubs),
                         card(.ten, .spades), card(.jack, .diamonds), card(.queen, .diamonds),
                         card(.king, .clubs)],
                .west: [card(.four, .diamonds), card(.five, .diamonds), card(.six, .clubs),
                        card(.nine, .hearts), card(.ten, .hearts), card(.jack, .hearts),
                        card(.queen, .hearts)],
            ],
            firstLeader: .south,
            steps: [
                .coach("Two lonely small singles: a 3 and a 6. Most beginners lead the 3 first. Most beginners are wrong."),
                .coach("Your LAST card decides nothing — the hand is already won when it leaves. So park your very smallest card at the tail, and spend the 6 NOW, where it blocks the next player's 4s and 5s."),
                .humanPlay([s6], "Lead the 6 — not the 3."),
                .botPlays(.east, [e10], "Lena pays a 10 to take a 6. Already a win: her 4s and 5s are still stuck in hand."),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, nil),
                .humanPass("Let it go — the 6 did its job."),
                .botPlays(.east, [e4a, e4b], "See? She's forced to lead those small cards as a PAIR now, where you have answers."),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, nil),
                .humanPlay([s8a, s8b], "Take the pair fight with your 8s."),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, "Trick yours — now sequence the exit."),
                .humanPlay([sAa, sAb], "Ace pair clears the road…"),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, nil),
                .humanPlay([sK], "…the King strolls through…"),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, nil),
                .humanPlay([s3], "…and the 3 — the tail card — walks out LAST. Flawless."),
                .finish("The tail-card principle is worth about half a bomb: lead your bigger small cards early to jam the next player, and save the runt for the final step. 🏁"),
            ])
    }
}
