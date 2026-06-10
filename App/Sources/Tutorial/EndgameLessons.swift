import SwiftUI
import GuandanCore

// MARK: - L23 Forcing the Bomb (残局逼炸) — scripted

extension LessonScripts {
    private static func card23(_ rank: Rank, _ suit: Suit?, _ copy: UInt8 = 0) -> Card {
        Card(rank: rank, suit: suit, copy: copy)
    }

    static var forcingBomb: ScriptedLesson {
        let bj = card23(.bigJoker, nil)
        let s4a = card23(.four, .spades), s4b = card23(.four, .hearts)
        let s9 = card23(.nine, .clubs)

        return ScriptedLesson(
            lessonId: 23,
            title: "Forcing the Bomb",
            level: .two,
            hands: [
                .south: [bj, s4a, s4b, s9],
                .east: [card23(.eight, .diamonds), card23(.jack, .clubs)],   // 听牌 with 2 singles
                .north: [card23(.five, .spades), card23(.seven, .clubs),
                         card23(.ten, .diamonds), card23(.queen, .diamonds)],
                .west: [card23(.six, .clubs), card23(.nine, .diamonds),
                        card23(.ten, .hearts), card23(.queen, .hearts)],
            ],
            firstLeader: .south,
            steps: [
                .coach("Danger scan: Lena is down to TWO cards — loose singles, waiting to ride out behind your small leads. Your pair is tiny and can't reclaim anything."),
                .coach("The endgame rule: when the next player is about to listen-win, lead your BIGGEST single first — the joker. Nothing rides over it, and any bomb spent stopping it is a bomb they no longer have."),
                .humanPlay([bj], "Drop the big joker — force their hand."),
                .botPlays(.east, nil, "Lena can only watch…"),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, "It stands. Her singles are now trapped."),
                .humanPlay([s4a, s4b], "Now the tiny pair — she holds no pairs, the lane is shut."),
                .botPlays(.east, nil, "Stuck."),
                .botPlays(.north, nil, nil),
                .botPlays(.west, nil, nil),
                .humanPlay([s9], "And the 9 walks out last. First place!"),
                .finish("Lead the 9 first instead and watch the disaster: her Jack rides over it, her 8 follows next trick — she's out before you. Big single FIRST is the forcing play. Cousins of this move: lead a newly-crowned top pair, toss a small bomb to burn tempo, even split a flush bomb into a straight to jam the lane. 💣"),
            ])
    }
}

// MARK: - L24 Co-Defense (协防)

struct CoDefenseLesson: View {
    var body: some View {
        PagedLessonView(lessonId: 24, pages: [
            AnyView(LessonPage(
                title: "Charge with different lanes",
                body: "Late hand, you're charging out with JJ-QQ-KK while your partner holds pairs too? If a bomb stops you, you BOTH die in the same lane. Split your charge — go out via KK and keep QQQ-JJ, or vice versa — so your tails cover different shapes.",
                diagram: AnyView(CoDefenseDemo()))),
            AnyView(LessonPage(
                title: "Patch the hole they're aiming at",
                body: "When the player after you is one move from out, your lone small single is a death sentence — any single they lead, you must answer or feed them. Spend a strong play to win a trick, THEN shed the weak single while you still control the table.",
                diagram: AnyView(Text("🩹").font(.system(size: 44))))),
        ])
    }
}

private struct CoDefenseDemo: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("❌ same lane").font(.heading(12)).foregroundStyle(Theme.coral)
                Text("you: pairs · partner: pairs → one bomb kills both")
                    .font(.body(12)).foregroundStyle(Theme.mint)
            }
            HStack(spacing: 8) {
                Text("✅ split lanes").font(.heading(12)).foregroundStyle(Theme.goldSoft)
                Text("you: full house tail · partner: pair tail")
                    .font(.body(12)).foregroundStyle(Theme.mint)
            }
        }
        .padding(14)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - L25 Tenpai Tricks (听牌干扰)

struct TenpaiLesson: View {
    var body: some View {
        PagedLessonView(lessonId: 25, pages: [
            AnyView(LessonPage(
                title: "Fake the pair",
                body: "An enemy sits at two cards, listening for a pair. You also hold two. Don't reveal yours — even when you COULD ride a single out, hold both and act like a pair. Now nobody dares lead pairs, the table freezes, and your partner gets time to run.",
                diagram: AnyView(Text("🎭 2 cards = 2 cards").font(.system(size: 24)).foregroundStyle(.white)))),
            AnyView(LessonPage(
                title: "Listen where they don't",
                body: "Flip side: when the player BEFORE you is listening, shape your own last cards into a DIFFERENT lane than theirs. Same-lane listening means their interference cuts you both ways, and your partner can't feed you safely.",
                diagram: AnyView(Text("🛣 ≠ 🛣").font(.system(size: 30)).foregroundStyle(.white)))),
        ])
    }
}

// MARK: - L27 Reading Opponents (对手风格)

struct ReadingOpponentsLesson: View {
    var body: some View {
        QuizLessonView(
            lessonId: 27,
            title: "Reading Opponents",
            intro: [
                AnyView(LessonPage(
                    title: "Two species of player",
                    body: "CONTROLLERS save big cards to ambush, wait for their exact lane, and almost never bomb the player before them. CHARGERS cap everything cappable, bomb on sight, and charge early. Your Arena bots now have real personalities — spot them by trick three.",
                    diagram: AnyView(StyleTable()))),
                AnyView(LessonPage(
                    title: "Counter each one",
                    body: "Against a CONTROLLER: don't feed the ambush — vary your lanes and make them spend. Against a CHARGER: bait early caps with small stuff, let them burn out, then collect. Dream team note: the best partnership is one controller + one charger.",
                    diagram: AnyView(Text("🪤 / 🧯").font(.system(size: 36)))),
                ),
            ],
            questions: [
                QuizQuestion(
                    prompt: "An opponent bombs your medium full house in trick two, with 20+ cards still in hand. What are they?",
                    options: ["A controller setting a trap", "A charger — pressure them with bait", "Impossible to tell"],
                    correct: 1,
                    explanation: "Bomb-on-sight that early is charger DNA. Feed them small caps; chargers burn themselves out by mid-hand."),
                QuizQuestion(
                    prompt: "An opponent has passed every single you led — then suddenly drops a big joker late. Their style, and the danger?",
                    options: ["Charger — they'll keep attacking", "Controller — the ambush is sprung; expect a clean exit behind it", "They just got lucky cards"],
                    correct: 1,
                    explanation: "Long patience then one decisive top card is the controller ambush. Behind that joker is usually a prepared run — block the FIRST follow-up at any cost."),
            ])
    }
}

private struct StyleTable: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("🧊 CONTROLLER").font(.heading(12)).foregroundStyle(Theme.mintBright)
                Text("hoards tops · waits · ambushes late").font(.body(12)).foregroundStyle(Theme.mint)
            }
            HStack(spacing: 8) {
                Text("🔥 CHARGER").font(.heading(12)).foregroundStyle(Theme.coral)
                Text("caps everything · bombs on sight · charges early").font(.body(12)).foregroundStyle(Theme.mint)
            }
        }
        .padding(14)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - L28 How to Review (复盘方法论)

struct HowToReviewLesson: View {
    var body: some View {
        PagedLessonView(lessonId: 28, pages: [
            AnyView(LessonPage(
                title: "The 3-move review",
                body: "After every Arena hand, tap Review and find exactly THREE moments: your first lead (did it match your hand score?), your biggest spend (was the trick worth it?), and any 🚩 flag. Don't replay everything — three moves, honestly examined, beat thirty skimmed.",
                diagram: AnyView(VStack(spacing: 6) {
                    Text("1️⃣ first lead").font(.body(13)).foregroundStyle(.white)
                    Text("2️⃣ biggest spend").font(.body(13)).foregroundStyle(.white)
                    Text("3️⃣ the 🚩 flag").font(.body(13)).foregroundStyle(.white)
                }))),
            AnyView(LessonPage(
                title: "One takeaway per hand",
                body: "Finish each review by naming ONE thing you'll do differently — out loud if you have to. Champions aren't built from talent (30% feel + 30% luck + 40% craft, says the textbook) — craft is the only part that compounds, and it compounds through review. Now graduate: beat a Hard table. 🎓",
                diagram: AnyView(Text("🎓").font(.system(size: 50)))),
            ),
        ])
    }
}
