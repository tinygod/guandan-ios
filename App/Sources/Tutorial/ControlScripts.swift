import Foundation
import GuandanCore

/// L16 — Feeding Your Partner (传牌的艺术), scripted.
extension LessonScripts {
    private static func card16(_ rank: Rank, _ suit: Suit?, _ copy: UInt8 = 0) -> Card {
        Card(rank: rank, suit: suit, copy: copy)
    }

    static var feeding: ScriptedLesson {
        let s4a = card16(.four, .spades), s4b = card16(.four, .hearts)
        let s9 = card16(.nine, .clubs), sQ = card16(.queen, .diamonds)
        let sAa = card16(.ace, .spades), sAb = card16(.ace, .hearts)

        let n6a = card16(.six, .spades), n6b = card16(.six, .hearts)
        let e7 = card16(.seven, .diamonds)
        let wJ = card16(.jack, .diamonds)

        return ScriptedLesson(
            lessonId: 16,
            title: "Feeding Your Partner",
            level: .two,
            hands: [
                .south: [s4a, s4b, s9, sQ, sAa, sAb],
                .north: [n6a, n6b],
                .east: [e7, card16(.eight, .clubs), card16(.ten, .clubs),
                        card16(.queen, .clubs), card16(.five, .diamonds), card16(.three, .diamonds)],
                .west: [wJ, card16(.nine, .diamonds), card16(.eight, .diamonds),
                        card16(.ten, .diamonds), card16(.five, .clubs), card16(.three, .spades)],
            ],
            firstLeader: .east,
            steps: [
                .coach("Coach Wu kept exactly TWO cards all hand. He answered pairs eagerly and ignored every single — he's been telling you all along: MY LAST TWO ARE A PAIR."),
                .botPlays(.east, [e7], "Lena leads a single 7…"),
                .botPlays(.north, nil, "…and Coach Wu ignores it. Confirmation: he doesn't hold singles."),
                .botPlays(.west, [wJ], "Marco rides a Jack through."),
                .humanPlay([sAa], "Step one of feeding: TAKE CONTROL. Your Ace."),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, "The lead is yours. Now deliver."),
                .humanPlay([s4a, s4b], "Feed him: a tiny pair — a gift only your partner can want."),
                .botPlays(.east, nil, "Lena won't waste cards on a 4-pair…"),
                .botPlays(.north, [n6a, n6b], "Coach Wu POUNCES — his 6s take it and he's OUT! 🎉"),
                .botPlays(.west, nil, nil),
                .humanPass("His pair stands. Obviously, pass."),
                .botPlays(.east, nil, "Nobody answers. And since the trick-winner is out — you catch the wind."),
                .humanPlay([sAb], "Free lead. March: the other Ace…"),
                .botPlays(.east, nil, nil),
                .botPlays(.west, nil, nil),
                .humanPlay([sQ], "…the Queen…"),
                .botPlays(.east, nil, nil),
                .botPlays(.west, nil, nil),
                .humanPlay([s9], "…and out. Partners 1st and 2nd — a DOUBLE, +3 levels!"),
                .finish("That's the feeding craft: read the signal, seize control, deliver the exact shape, then ride the wind home. Timing note — feed too early and enemies wall it off; strike when their blockers are spent. 🐼"),
            ])
    }
}
