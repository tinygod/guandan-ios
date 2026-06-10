import Foundation
import GuandanCore

/// Scripted technique courses (6: Partner Play, 10: Endgame Lines).
extension LessonScripts {
    private static func card(_ rank: Rank, _ suit: Suit?, _ copy: UInt8 = 0) -> Card {
        Card(rank: rank, suit: suit, copy: copy)
    }

    // MARK: Course 6 — Partner Play

    static var partnerPlay: ScriptedLesson {
        let s4a = card(.four, .spades), s4b = card(.four, .hearts)
        let s8 = card(.eight, .spades)
        let sJa = card(.jack, .spades), sJb = card(.jack, .hearts)
        let sA = card(.ace, .spades)

        let nKa = card(.king, .spades), nKb = card(.king, .hearts)
        let e9a = card(.nine, .spades), e9b = card(.nine, .hearts)
        let eQ = card(.queen, .spades)

        return ScriptedLesson(
            lessonId: 10,
            title: "Partner Play",
            level: .two,
            hands: [
                .south: [s4a, s4b, s8, sJa, sJb, sA],
                .north: [nKa, nKb],
                .east: [e9a, e9b, eQ, card(.ten, .clubs), card(.seven, .diamonds),
                        card(.six, .diamonds)],
                .west: [card(.ten, .spades), card(.ten, .hearts), card(.five, .diamonds),
                        card(.queen, .diamonds), card(.eight, .diamonds), card(.three, .diamonds)],
            ],
            firstLeader: .south,
            steps: [
                .coach("Look at Coach Wu: only TWO cards left! Your one job now is to clear the road so he can go out."),
                .humanPlay([s4a, s4b], "Lead a LOW pair. If his two cards are a pair, you just opened his lane."),
                .botPlays(.east, [e9a, e9b], "Lena bumps it with 9s — she smells danger."),
                .botPlays(.north, [nKa, nKb], "BOOM — Coach Wu slams his last two cards: Kings! He's out FIRST."),
                .botPlays(.west, nil, "Marco can't answer."),
                .humanPass("Never bid against your own partner — pass and protect his exit."),
                .botPlays(.east, nil, "Lena passes. The Kings stand…"),
                .coach("…and here's the magic: the trick-winner already went out, so his PARTNER inherits the lead. That's 接风 — catching the wind. The lead is yours, free."),
                .humanPlay([sJa, sJb], "Spend the free lead: Jacks."),
                .botPlays(.east, nil, nil),
                .botPlays(.west, nil, "No answers."),
                .humanPlay([s8], "Lead the 8 — keep the Ace as your closer."),
                .botPlays(.east, [eQ], "Lena grabs it with a Queen…"),
                .botPlays(.west, nil, nil),
                .humanPlay([sA], "…and your Ace takes it right back. That's your LAST card!"),
                .finish("Partners finishing 1st and 2nd is a DOUBLE — your team rockets up 3 levels. Feed your partner, never fight them. 🐼"),
            ])
    }

    // MARK: Course 10 — Endgame Lines

    static var endgame: ScriptedLesson {
        let s3 = card(.three, .clubs)
        let s6a = card(.six, .spades), s6b = card(.six, .hearts)
        let sA = card(.ace, .clubs)
        let e9 = card(.nine, .diamonds)

        return ScriptedLesson(
            lessonId: 22,
            title: "Four Ways to First",
            level: .two,
            hands: [
                .south: [s3, s6a, s6b, sA],
                .east: [e9, card(.jack, .clubs), card(.queen, .clubs), card(.king, .diamonds)],
                .north: [card(.five, .spades), card(.seven, .clubs), card(.ten, .diamonds),
                         card(.jack, .diamonds)],
                .west: [card(.four, .diamonds), card(.eight, .clubs), card(.nine, .clubs),
                        card(.queen, .hearts)],
            ],
            firstLeader: .south,
            steps: [
                .coach("There are four roads to 1st place: BOMB out (fire escorts everything), CHARGE out (your last big play just happens to be unbeatable), LISTEN out (one move left, partner delivers), and AMBUSH out (a 6-card tube nobody saw coming). Most wins are charges and listens."),
                .coach("This drill is a CHARGE. 4 cards left — a lone ♣3, a pair of 6s, and an Ace. STOP. Plan the exit before touching anything."),
                .coach("Count your exits: the Ace wins a trick. The 6s only walk if everyone passes. The 3 can NEVER win. So the 3 must go while your Ace can still win back the lead."),
                .humanPlay([s3], "Shed the dead card — lead the 3."),
                .botPlays(.east, [e9], "Lena takes it cheap with a 9."),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, "Nobody fights for a small trick."),
                .humanPlay([sA], "Now win the lead back — Ace!"),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, "All fold. Control is yours."),
                .humanPlay([s6a, s6b], "And the 6s walk out unopposed. OUT — a flawless exit."),
                .finish("That's an endgame line: dump the dead card while you still hold control, then exit clean. Lead the 6s first instead, and that 3 strands you in last place. 🏁"),
            ])
    }
}
