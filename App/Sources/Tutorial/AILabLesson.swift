import SwiftUI
import GuandanCore

/// Course 29 — AI Lab Secrets: data-backed iron rules discovered while
/// training this app's own AI through thousands of self-play games.
struct AILabLesson: View {
    var body: some View {
        QuizLessonView(
            lessonId: 29,
            title: "AI Lab Secrets",
            intro: [
                AnyView(LessonPage(
                    title: "Rules forged in 10,000 games",
                    body: "We trained this app's AI by making different versions fight each other for thousands of matches — and by studying champion engines. Some 'obvious' strategies LOST badly; some boring ones dominated. These five questions are the survivors. Every answer comes with the win-rate data.",
                    diagram: AnyView(VStack(spacing: 8) {
                        GoldPlaque(top: "SELF-PLAY MATCHES", big: "10k+", bottom: "every rule battle-tested")
                    }))),
            ],
            questions: [
                QuizQuestion(
                    prompt: "Our lab gave one AI the habit of beating EVERYTHING it could beat. Against a twin that picked its battles, it won…",
                    options: ["About half the games", "About 1 game in 9", "It dominated — pressure wins"],
                    correct: 1,
                    explanation: "11% — the worst result in our entire lab. Beating every cheap trick burned its good cards by mid-hand, leaving zero late-game pivots. Passing is not weakness; it's ammunition management."),
                QuizQuestion(
                    prompt: "An early AI version sometimes played its WILDCARD (♥ level card) as a plain single. How costly was that habit?",
                    options: ["Minor — it's just one card", "Roughly half a bomb thrown away every hand", "Only matters in the endgame"],
                    correct: 1,
                    explanation: "A wildcard completes straight flushes and grows bombs — worth about half a bomb (~2 points). Our human tester beat that AI version every single game. The fixed rule: a wildcard leaves your hand only inside a bomb, a straight flush, or your final exit."),
                QuizQuestion(
                    prompt: "An enemy is down to exactly ONE card. The strongest lead, per both champion engines we studied:",
                    options: ["Your biggest single — outrank their last card", "Any PAIR — their single can never follow it", "A bomb — guarantee the stop"],
                    correct: 1,
                    explanation: "A pair walls them off completely: a lone card can't answer a pair, ever. Your big single might still lose to theirs — and a bomb is massive overpayment. At TWO cards left, flip it: lead singles to force them to break."),
                QuizQuestion(
                    prompt: "Both big jokers and all natural level cards have hit the table. Your ♠A single is now…",
                    options: ["Still risky — someone may hold A", "Unbeatable — and should be played MORE freely, not hoarded",
                              "Best saved for the last trick"],
                    correct: 1,
                    explanation: "Count the tops: with jokers and level cards gone, no hidden hand can beat an Ace. A crowned top costs you NOTHING to play — it wins the trick AND hands you the lead. Hoarding it is the real waste. (This is why the counting HUD exists.)"),
                QuizQuestion(
                    prompt: "When should you cap a running opponent with your absolute biggest cards (封到顶)?",
                    options: ["Whenever they drop below 7 cards", "Only when they're at ~3 cards or fewer — at 4–6, a firm middle beat is enough",
                              "Never — always block minimally"],
                    correct: 1,
                    explanation: "Our first 'block everything below 7 cards at maximum strength' AI collapsed to an 11% win rate — it shredded its own hand. The data said: go maximal only when they're genuinely one or two moves from out; otherwise make riding expensive, not impossible."),
            ])
    }
}
