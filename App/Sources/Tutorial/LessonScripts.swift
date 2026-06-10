import Foundation
import GuandanCore

/// Stacked decks + move scripts for the guided-play lessons.
enum LessonScripts {
    private static func card(_ rank: Rank, _ suit: Suit?, _ copy: UInt8 = 0) -> Card {
        Card(rank: rank, suit: suit, copy: copy)
    }

    // MARK: Lesson 3 — Your First Hand

    static var firstHand: ScriptedLesson {
        let s3s = card(.three, .spades), h3 = card(.three, .hearts)
        let s6 = card(.six, .spades), h6 = card(.six, .hearts)
        let s10 = card(.ten, .spades), h10 = card(.ten, .hearts)
        let sK = card(.king, .spades), hA = card(.ace, .hearts)

        let e9a = card(.nine, .spades), e9b = card(.nine, .hearts)
        let nQa = card(.queen, .spades), nQb = card(.queen, .hearts)
        let n4 = card(.four, .clubs)
        let w8 = card(.eight, .spades)

        return ScriptedLesson(
            lessonId: 3,
            title: "Your First Hand",
            level: .two,
            hands: [
                .south: [s3s, h3, s6, h6, s10, h10, sK, hA],
                .east: [e9a, e9b, card(.five, .spades), card(.five, .clubs),
                        card(.seven, .spades), card(.seven, .clubs),
                        card(.jack, .spades), card(.jack, .hearts)],
                .north: [nQa, nQb, n4, card(.eight, .clubs), card(.eight, .hearts),
                         card(.seven, .hearts), card(.three, .clubs), card(.five, .hearts)],
                .west: [w8, card(.six, .clubs), card(.six, .diamonds), card(.ten, .clubs),
                        card(.jack, .clubs), card(.queen, .diamonds), card(.king, .clubs),
                        card(.ace, .diamonds)],
            ],
            firstLeader: .south,
            steps: [
                .coach("Welcome to your first real hand! 🐼 Coach Wu, across the table, is your PARTNER. Everyone got 8 cards — empty your hand first to win."),
                .humanPlay([s3s, h3], "You lead. Tap the two glowing 3s, then hit Play — shed low pairs early."),
                .botPlays(.east, [e9a, e9b], "Lena answers with two 9s. A pair can only be beaten by a higher pair."),
                .botPlays(.north, [nQa, nQb], "Coach Wu fires back Queens — he's fighting for your team!"),
                .botPlays(.west, nil, "Marco can't beat Queens. He passes."),
                .humanPass("Your partner's Queens are winning. Never outbid your own partner — pass!"),
                .botPlays(.east, nil, "Lena passes too. Coach Wu wins the trick and leads next."),
                .botPlays(.north, [n4], "He leads a cheap single to probe."),
                .botPlays(.west, [w8], "Marco bumps it to an 8."),
                .humanPlay([hA], "Your Ace crushes the 8 — take the trick!"),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, "Coach Wu passes. Partners don't fight each other."),
                .botPlays(.west, nil, "Marco has nothing bigger."),
                .coach("Trick won — you lead again. Time to dump everything."),
                .humanPlay([s6, h6], "Play your 6s."),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, "Everyone passes!"),
                .humanPlay([s10, h10], "Keep rolling — the 10s."),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, "Still no answer."),
                .humanPlay([sK], "Last card. Go out FIRST! 🎉"),
                .finish("You finished 1st — that's how your team climbs levels. Next lesson: levels, wildcards and tribute."),
            ])
    }

    // MARK: Lesson 5 — Bombs!

    static var bombs: ScriptedLesson {
        let b5a = card(.five, .spades), b5b = card(.five, .hearts)
        let b5c = card(.five, .clubs), b5d = card(.five, .diamonds)
        let s7a = card(.seven, .spades), s7b = card(.seven, .hearts)
        let s9 = card(.nine, .clubs)

        let eKa = card(.king, .spades), eKb = card(.king, .hearts), eKc = card(.king, .clubs)
        let e4a = card(.four, .spades), e4b = card(.four, .hearts)

        return ScriptedLesson(
            lessonId: 5,
            title: "Bombs!",
            level: .two,
            hands: [
                .south: [b5a, b5b, b5c, b5d, s7a, s7b, s9],
                .east: [eKa, eKb, eKc, e4a, e4b, card(.jack, .diamonds), card(.ten, .diamonds)],
                .north: [card(.ace, .spades), card(.queen, .clubs), card(.queen, .diamonds),
                         card(.three, .spades), card(.three, .hearts), card(.six, .hearts),
                         card(.eight, .diamonds)],
                .west: [card(.ten, .spades), card(.ten, .hearts), card(.nine, .diamonds),
                        card(.eight, .hearts), card(.jack, .spades), card(.jack, .hearts),
                        card(.ace, .clubs)],
            ],
            firstLeader: .east,
            steps: [
                .coach("Final lesson: the BOMB 💣 — four or more cards of the same rank. Bombs ignore the follow-the-shape rule."),
                .botPlays(.east, [eKa, eKb, eKc, e4a, e4b], "Lena opens with a monster: a full house of Kings."),
                .botPlays(.north, nil, "Coach Wu can't match it."),
                .botPlays(.west, nil, "Marco folds too."),
                .humanPlay([b5a, b5b, b5c, b5d], "You can't beat Kings shape-for-shape… but your four glowing 5s are a BOMB. Drop it!"),
                .coach("💥 A bomb beats ANY non-bomb. Bigger bombs beat smaller ones, a straight flush sits between 5- and 6-bombs, and the four jokers beat everything."),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, "Nobody answers a bomb cheaply. The lead is yours."),
                .humanPlay([s7a, s7b], "Cash in — play your 7s."),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, "All pass."),
                .humanPlay([s9], "And your last card — out FIRST again!"),
                .finish("Graduated! 🎓 One tip: a bomb spent on a cheap trick is a bomb wasted — save them for big moments. Now go win a real match!"),
            ])
    }

    static func lesson(for id: Int) -> ScriptedLesson? {
        switch id {
        case 3: return firstHand
        case 5: return bombs
        case 6: return partnerPlay
        case 10: return endgame
        default: return nil
        }
    }

    static var allScripted: [ScriptedLesson] { [firstHand, bombs, partnerPlay, endgame] }
}
