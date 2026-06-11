import SwiftUI
import GuandanCore

// MARK: - L14 Roles & Signals (主攻/助攻 + 首攻信号)

struct RolesSignalsLesson: View {
    var body: some View {
        QuizLessonView(
            lessonId: 14,
            title: "Roles & Signals",
            intro: [
                AnyView(LessonPage(
                    title: "Striker or support?",
                    body: "Every hand, your team has ONE striker chasing 1st place and ONE support player. The STRIKER clears weak lanes, trims moves and saves muscle. The SUPPORT blocks the player before the striker, jams the one after, and feeds the partner. Strong hand strikes; weak hand supports; equal hands — the better player supports.",
                    diagram: AnyView(RoleCard()))),
                AnyView(LessonPage(
                    title: "The first lead is a message",
                    body: "There's no bidding in GuanDan — the OPENING LEAD is the signal. A small single, a full house or a ragged straight says: strong hand, I'm striking. A tube, plate or bare triple says: decent hand, testing. A pair or high single says: weak-ish, I'll support. When in doubt — \"lead pairs to ask questions.\"",
                    diagram: AnyView(SignalTable()))),
            ],
            questions: [
                QuizQuestion(
                    prompt: "Your partner opens the hand with a small single 3. What does it mean?",
                    options: ["A throwaway card — means nothing",
                              "Strong hand: partner wants to strike — switch to support",
                              "Partner is weak and asking for help"],
                    correct: 1,
                    explanation: "A confident small single says \"I can win this race.\" Even if your own hand is strong, yield the striker role first — two strikers on one team lose to one organized pair."),
                QuizQuestion(
                    prompt: "Your partner opens with a middling PAIR. Your hand scores 13 points. Who strikes?",
                    options: ["Partner led first, so partner strikes",
                              "You do — a pair opening signals a support hand, and yours is strong",
                              "Nobody — play it safe"],
                    correct: 1,
                    explanation: "A pair opening usually means a so-so hand asking questions. With 13 points you take the striker role at your first lead — make it loud (small single or a ragged straight)."),
                QuizQuestion(
                    prompt: "Both you and your partner hold roughly equal, decent hands. Who should support?",
                    options: ["The stronger card holder", "Whoever is losing the match", "The more skilled player"],
                    correct: 2,
                    explanation: "Stacking your strength onto a partner's run is HARDER than running yourself — the textbook rule is: equal hands, the better player supports."),
            ])
    }
}

private struct RoleCard: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("⚔️ STRIKER").font(.heading(13)).foregroundStyle(Theme.goldSoft)
                Text("clear weak lanes · save muscle · finish 1st")
                    .font(.body(12)).foregroundStyle(Theme.mint)
            }
            HStack(spacing: 8) {
                Text("🛡 SUPPORT").font(.heading(13)).foregroundStyle(Theme.mintBright)
                Text("block upstream · jam downstream · feed partner")
                    .font(.body(12)).foregroundStyle(Theme.mint)
            }
        }
        .padding(14)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct SignalTable: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            row("small single · 3+2 · ragged straight", "I'M STRIKING", Theme.gold)
            row("tube · plate · bare triple", "testing waters", Theme.goldSoft)
            row("pair · high single", "supporting", Theme.mintBright)
        }
    }

    private func row(_ lead: String, _ meaning: String, _ color: Color) -> some View {
        HStack {
            Text(lead).font(.body(12)).foregroundStyle(.white.opacity(0.85))
            Spacer()
            Text(meaning).font(.heading(11)).foregroundStyle(color)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 9))
        .frame(maxWidth: 360)
    }
}

// MARK: - L15 Opening Leads (开局领出)

struct OpeningLeadsLesson: View {
    var body: some View {
        PagedLessonView(lessonId: 15, pages: [
            AnyView(LessonPage(
                title: "Lead what you can reclaim",
                body: "The classic opening: lead your STRONG lanes — shapes you can play AND win back. \"Who leads it, reclaims it\": your partner trusts your lane and won't waste cards guarding it. Know your numbers: a hand averages 38 total moves, and 1st place uses only about 10.",
                diagram: AnyView(StatPlaques()))),
            AnyView(LessonPage(
                title: "Or hide your strength",
                body: "The reverse works too: open with your WEAK lanes and bank the muscle — \"hiding the edge.\" Only do it when you're sure you can seize the lead later AND your hand flows once you have it. Otherwise you're just donating tempo.",
                diagram: AnyView(Text("🎭").font(.system(size: 44))))),
            AnyView(LessonPage(
                title: "When in doubt, pairs first",
                body: "Unclear hand, unclear table? \"Situation unknown — pairs go first.\" Pairs are the probing shape: cheap, informative, and they ask your partner a question without overcommitting.",
                diagram: AnyView(HStack(spacing: -12) {
                    CardView(card: Card(rank: .seven, suit: .spades), width: 46)
                    CardView(card: Card(rank: .seven, suit: .hearts), width: 46)
                }))),
        ])
    }
}

private struct StatPlaques: View {
    var body: some View {
        VStack(spacing: 10) {
            GoldPlaque(top: "MOVES PER HAND", big: "38", bottom: "all four players")
            GoldPlaque(top: "MOVES TO FINISH 1st", big: "~10", bottom: "plan yours")
        }
    }
}

// MARK: - L17 Taming the Upstream (上家控制)

struct UpstreamLesson: View {
    var body: some View {
        QuizLessonView(
            lessonId: 17,
            title: "Taming the Upstream",
            intro: [
                AnyView(LessonPage(
                    title: "Upstream is your supply line",
                    body: "A third of all moves are free rides — and over half of those ride on the player BEFORE you. If their leads suit you, wave them through (even help them). If their shape blocks you, cut it down immediately. And never casually beat your PARTNER's table — blocking it is the enemy's job, not yours.",
                    diagram: AnyView(GoldPlaque(top: "FREE RIDES", big: "33.6%", bottom: "half via upstream")))),
                AnyView(LessonPage(
                    title: "Don't fight the four",
                    body: "When an opponent is down to 4 cards: if it's a bomb, fighting is pointless; if it's not, they can't escape anyway. So \"never fight a four\"… except: you're guarding a bigger bomb behind a finished run; you're mid-charge with dead leftovers; or their 4 splits into two moves that would unlock their partner. One in five fours IS fought — know why.",
                    diagram: AnyView(GoldPlaque(top: "FOURS THAT GET FOUGHT", big: "20.8%", bottom: "the exceptions matter")))),
                AnyView(LessonPage(
                    title: "Fight the nine, not the ten",
                    body: "9 cards left usually means a 5-card shape plus a small 4-bomb — weak fire, worth pressuring. 10 cards splits 5+5: the bomb behind it is bigger, often a straight flush. Pressure the 9, respect the 10.",
                    diagram: AnyView(NineTenDemo()))),
            ],
            questions: [
                QuizQuestion(
                    prompt: "An opponent has exactly 4 cards left and just lost the lead. Your move?",
                    options: ["Spend big cards hunting their four",
                              "Usually ignore it — bomb or trapped either way",
                              "Bomb them immediately"],
                    correct: 1,
                    explanation: "\"Never fight a four\": a bomb beats your effort, a non-bomb can't escape without winning a trick. Save your strength for the player who can actually run."),
                QuizQuestion(
                    prompt: "Two opponents: one holds 9 cards, one holds 10. Who gets your pressure?",
                    options: ["The 9 — their backup fire is small", "The 10 — fewer moves to freedom", "Both equally"],
                    correct: 0,
                    explanation: "9 ≈ 5-shape + 4-bomb (weak escort). 10 ≈ 5+5 — the escort is real fire, maybe a straight flush. Pressure where the guard is thin."),
            ])
    }
}

private struct NineTenDemo: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("9 cards").font(.heading(13)).foregroundStyle(Theme.gold)
                Text("= 5-shape + small bomb → pressure").font(.body(12)).foregroundStyle(Theme.mint)
            }
            HStack {
                Text("10 cards").font(.heading(13)).foregroundStyle(Theme.coral)
                Text("= 5 + 5 → real fire, respect it").font(.body(12)).foregroundStyle(Theme.mint)
            }
        }
        .padding(14)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - L18 Blocking Downstream (下家控制)

struct DownstreamLesson: View {
    var body: some View {
        PagedLessonView(lessonId: 18, pages: [
            AnyView(LessonPage(
                title: "Deny the free ride",
                body: "Your real job is the player AFTER you: deny their cheap discards. When the enemy passes cards toward a teammate — BLOCK, every time, even if it costs you a comfortable discard. \"A delivery must be jammed\" — one hesitation can hand over the whole hand.",
                diagram: AnyView(Text("🚧").font(.system(size: 44))))),
            AnyView(LessonPage(
                title: "Cap to the very top",
                body: "Blocking a straight? Don't nudge it — CAP IT. Equal straights are 20× more common than equal full houses and 500× more common than equal plates. Cap low and they ride a higher straight over you; cap to the top and their only answer is a bomb — expensive for them, perfect for you.",
                diagram: AnyView(CapDemo()))),
            AnyView(LessonPage(
                title: "Block by the numbers",
                body: "Lab-tested thresholds: at 3 cards or fewer, cap with your best whole unit — they're one move from out, nothing is too expensive. At 4–6 cards, a FIRM middle beat makes riding costly without shredding your hand. Blanket max-blocking below 7 cards collapsed our test AI to an 11% win rate.",
                diagram: AnyView(VStack(spacing: 8) {
                    GoldPlaque(top: "≤3 CARDS", big: "CAP", bottom: "best whole unit")
                    GoldPlaque(top: "4–6 CARDS", big: "FIRM", bottom: "make riding costly")
                }))),
            AnyView(LessonPage(
                title: "Fire for fire",
                body: "When someone plays huge to FORCE a bomb out of you — give it, instantly. More than half of all bomb-forcing plays are bluffs propping up a mediocre hand. The exception: a true 诱火 trap from a skilled player. Judge the player; when unsure against a strong one, hold.",
                diagram: AnyView(Text("🔥 ⇄ 🔥").font(.system(size: 36))))),
        ])
    }
}

private struct CapDemo: View {
    var body: some View {
        HStack(spacing: -12) {
            ForEach(Array([Card(rank: .ten, suit: .spades), Card(rank: .jack, suit: .hearts),
                           Card(rank: .queen, suit: .clubs), Card(rank: .king, suit: .diamonds),
                           Card(rank: .ace, suit: .spades)].enumerated()), id: \.offset) { _, card in
                CardView(card: card, width: 42, highlighted: true)
            }
        }
    }
}

// MARK: - L19 Tribute Craft (回贡技术)

struct TributeCraftLesson: View {
    var body: some View {
        QuizLessonView(
            lessonId: 19,
            title: "Tribute Craft",
            intro: [
                AnyView(LessonPage(
                    title: "The return is a weapon",
                    body: "Tribute data nobody tells beginners: HALF of all returned cards complete a bomb for the payer. Another 6% patch their straight. A careless return doesn't soften the loser — it arms them. The pros call it \"the reversal\": the payer often profits more than the winner.",
                    diagram: AnyView(ReturnStats()))),
            ],
            questions: [
                QuizQuestion(
                    prompt: "You must return a card after receiving tribute. Which is safest?",
                    options: ["A card left over from building your straight",
                              "One card from a small pair",
                              "Your lowest card, whatever it is"],
                    correct: 0,
                    explanation: "Straight leftovers are the statistically safest — the ranks around them are thin. Splitting a small pair is plan B. \"Lowest whatever\" is how you gift a 4th bomb card."),
                QuizQuestion(
                    prompt: "You owe tribute and hold TWO equal biggest cards (♠A and ♣A). Your spades run long. Which Ace do you pay?",
                    options: ["♠A — pay from your long suit", "♣A — keep the suit you're long in", "Either, they're equal"],
                    correct: 0,
                    explanation: "Pay the Ace from YOUR long suit: the receiver now holds a card whose suit-mates sit in your hand, so their straight-flush odds collapse."),
                QuizQuestion(
                    prompt: "You can't read the receiver's hand at all. Which SUIT should your return lean toward?",
                    options: ["Spades", "Hearts", "Clubs"],
                    correct: 1,
                    explanation: "Hearts — returns near the level rank in hearts keep wildcard mechanics on YOUR side of the table and rarely complete their suited runs."),
                QuizQuestion(
                    prompt: "Tribute paid TO YOUR PARTNER — do the same defensive rules apply?",
                    options: ["Yes, always return safe cards", "No — flip every rule: now you WANT to arm them"],
                    correct: 1,
                    explanation: "Everything reverses for your own team: feed the suit they're long in, complete their shapes. The textbook's exact words: think in mirror image."),
            ])
    }
}

private struct ReturnStats: View {
    var body: some View {
        HStack(spacing: 10) {
            GoldPlaque(top: "RETURN COMPLETES", big: "50%", bottom: "a bomb!")
            GoldPlaque(top: "PATCHES A RUN", big: "6.3%", bottom: "almost as bad")
        }
    }
}

// MARK: - L21 Soft Power (反向控制)

struct SoftPowerLesson: View {
    var body: some View {
        PagedLessonView(lessonId: 21, pages: [
            AnyView(LessonPage(
                title: "Build a gradient",
                body: "Holding 2 triples and 4 pairs? Attach the MIDDLE pairs to the triples and keep one big + one small pair. The big one reclaims the lead after the small one probes — a self-sustaining loop. Keep two adjacent big pairs instead and the loop dies.",
                diagram: AnyView(GradientDemo()))),
            AnyView(LessonPage(
                title: "Muddy the water",
                body: "When a clean fight doesn't favor you, follow tricks you don't strictly need — without breaking your shapes. Opponents lose the thread of what you hold, and confusion is cover for an escape.",
                diagram: AnyView(Text("🌊").font(.system(size: 44))))),
            AnyView(LessonPage(
                title: "Small bait, big fish",
                body: "Lead a small shape ON PURPOSE to lure their big block — clearing the sky for your real run in that lane next time. You traded a pawn for their queen's attention.",
                diagram: AnyView(Text("🎣").font(.system(size: 44))))),
        ])
    }
}

private struct GradientDemo: View {
    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                HStack(spacing: -10) {
                    CardView(card: Card(rank: .king, suit: .spades), width: 38)
                    CardView(card: Card(rank: .king, suit: .hearts), width: 38)
                }
                Text("reclaims").font(.body(11)).foregroundStyle(Theme.goldSoft)
            }
            Image(systemName: "arrow.left.arrow.right").foregroundStyle(Theme.mint)
            VStack(spacing: 4) {
                HStack(spacing: -10) {
                    CardView(card: Card(rank: .four, suit: .spades), width: 38)
                    CardView(card: Card(rank: .four, suit: .hearts), width: 38)
                }
                Text("probes").font(.body(11)).foregroundStyle(Theme.mintBright)
            }
        }
    }
}
