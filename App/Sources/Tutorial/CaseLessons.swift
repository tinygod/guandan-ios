import SwiftUI
import GuandanCore

// MARK: - Course 30: The Feeding Ladder (经典送牌名局, scripted replay)

extension LessonScripts {
    private static func card30(_ rank: Rank, _ suit: Suit?, _ copy: UInt8 = 0) -> Card {
        Card(rank: rank, suit: suit, copy: copy)
    }

    static var feedingLadder: ScriptedLesson {
        let t10a = card30(.ten, .spades), t10b = card30(.ten, .hearts)
        let e8a = card30(.eight, .spades), e8b = card30(.eight, .hearts)
        let t3a = card30(.three, .spades), t3b = card30(.three, .hearts)
        let aceA = card30(.ace, .spades), aceB = card30(.ace, .hearts)
        let s9 = card30(.nine, .clubs)

        let eKa = card30(.king, .spades), eKb = card30(.king, .hearts)
        let e7 = card30(.seven, .diamonds)
        let wBomb = [card30(.five, .spades), card30(.five, .hearts),
                     card30(.five, .clubs), card30(.five, .diamonds)]
        let w6 = card30(.six, .diamonds)
        let n4a = card30(.four, .spades), n4b = card30(.four, .hearts)

        return ScriptedLesson(
            lessonId: 30,
            title: "The Feeding Ladder",
            level: .two,
            hands: [
                .south: [t10a, t10b, e8a, e8b, t3a, t3b, aceA, aceB, s9],
                .north: [n4a, n4b],
                .east: [eKa, eKb, e7, card30(.jack, .clubs), card30(.queen, .clubs),
                        card30(.six, .clubs)],
                .west: wBomb + [w6, card30(.nine, .diamonds), card30(.jack, .diamonds)],
            ],
            firstLeader: .south,
            steps: [
                .coach("A real club hand, famous enough to be quoted in every Guandan guide. Coach Wu holds TWO cards — you've read them as a small pair. The enemies still hold one BIG pair and one BOMB."),
                .coach("Beginners feed small-to-large… and watch every gift get eaten. The masters feed THE LADDER: biggest first, to drain the blockers before the real gift."),
                .humanPlay([t10a, t10b], "Rung one — feed the pair of 10s."),
                .botPlays(.east, [eKa, eKb], "Lena's Kings stomp it. GOOD. That big pair can never block again."),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, nil),
                .humanPass("Let her have the trick — her Kings died for nothing."),
                .botPlays(.east, [e7], "She leads a 7."),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, nil),
                .humanPlay([aceA], "Take the lead back — first Ace."),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, "Yours again."),
                .humanPlay([e8a, e8b], "Rung two — the pair of 8s."),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, wBomb, "Marco BOMBS a pair of 8s! Perfect — a bomb spent on a feed, not on your partner's exit."),
                .humanPass("Smile and pass. The board is now BLOCKER-FREE."),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, [w6], "He leads a 6 off the bomb's win."),
                .humanPlay([aceB], "Second Ace — reclaim."),
                .botPlays(.east, nil, nil),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, "Now the table is yours, and nothing big is left out there."),
                .humanPlay([t3a, t3b], "The REAL gift, last rung: pair of 3s."),
                .botPlays(.east, nil, "Nothing to block with…"),
                .botPlays(.north, [n4a, n4b], "Coach Wu's 4s take it — he's OUT! The ladder worked: 10s drew the Kings, 8s drew the bomb, 3s walked home."),
                .botPlays(.west, nil, nil),
                .humanPass("Done — and thanks to 接风…"),
                .botPlays(.east, nil, nil),
                .humanPlay([s9], "…the free lead is yours. Out — a DOUBLE finish."),
                .finish("The Feeding Ladder: feed from the TOP so every blocker dies on a decoy, then slide the true gift underneath. Count the enemy's weapons, spend your feeds against them one for one. 🪜"),
            ])
    }
}

struct FeedingLadderLesson: View {
    var body: some View {
        ScriptedLessonView(lesson: LessonScripts.feedingLadder)
    }
}

// MARK: - Course 31: Number Rules (数字诀 quiz)

struct NumberRulesLesson: View {
    var body: some View {
        QuizLessonView(
            lessonId: 31,
            title: "Number Rules",
            intro: [
                AnyView(LessonPage(
                    title: "The folk numbers that work",
                    body: "Chinese club players compress endgame judgment into counting rhymes — and the good ones survive statistical checking. This drill decodes five: bomb-at-5-not-4, fight-7-not-8, pairs-against-5, the 9/10 lead rule, and the low-single squeeze.",
                    diagram: AnyView(GoldPlaque(top: "口诀", big: "5·7·9", bottom: "numbers that decide hands")))),
            ],
            questions: [
                QuizQuestion(
                    prompt: "One enemy has 4 cards left, another situation has an enemy at 5. Which one deserves your bomb? (炸五不炸四)",
                    options: ["The 4 — closer to out", "The 5 — bombing the 4 is wasted either way", "Both equally"],
                    correct: 1,
                    explanation: "At 4 cards they hold either a bomb (yours bounces) or a hand that can't exit in one move (no need). At 5 they may hold a straight, flush bomb or 3+2 — one play and gone. Bomb the FIVE."),
                QuizQuestion(
                    prompt: "Two runners: one at 7 cards, one at 8. The rhyme says fight only one of them. Which? (打七不打八)",
                    options: ["The 7 — likely a 5-shape + 2, one block stops the run", "The 8 — bigger threat", "Whoever played last"],
                    correct: 0,
                    explanation: "7 splits as 5+2 or 4+3 — block once and the exit dies. 8 hides 5+3 or two bombs; blocking burns your cards for nothing. Fight the 7, release the 8."),
                QuizQuestion(
                    prompt: "An enemy sits at exactly 5 cards. Your safest LEAD shape? (逢五出对)",
                    options: ["Small single — cheap probe", "A pair — their 5 can't ride pairs out", "A five-card straight"],
                    correct: 1,
                    explanation: "5 cards is one move from freedom only via a 5-shape or 3+2 — pairs fit neither. Singles, meanwhile, slip straight through. 逢五出对: against a five, go double."),
                QuizQuestion(
                    prompt: "Your OWN hand: 9 cards in one case, 10 in another. The rhyme assigns each a preferred lead. Which pairing is right?",
                    options: ["9 → lead singles · 10 → lead pairs", "9 → lead pairs · 10 → lead singles", "Both → always pairs"],
                    correct: 0,
                    explanation: "九打单、十打对: at 9 your structure is likely 5+3+1 — singles keep flexibility; at 10 (5+5 or 4+4+2) pairs interfere with enemy timing while keeping your shapes whole."),
                QuizQuestion(
                    prompt: "An enemy guards exactly 2 cards. How do you torture them? (单张降级)",
                    options: ["Lead big singles to beat their best", "Lead LOW singles repeatedly — force them to burn high cards or split their pair", "Lead pairs to wall them"],
                    correct: 1,
                    explanation: "Two cards = a pair (walled by your pairs) or two singles. Cheap singles force a brutal choice every trick: spend the big one, or crack the pair. Either way their exit decays."),
            ])
    }
}
