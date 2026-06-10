import SwiftUI
import GuandanCore

// MARK: - Course 7: Wildcard Mastery

struct WildcardMasteryLesson: View {
    var body: some View {
        PagedLessonView(lessonId: 13, pages: [
            AnyView(TechPage(
                title: "Your two magic cards",
                body: "While playing level 8, the two HEART 8s are wildcards — each can stand in for ANY card except a joker. Spot them the second you pick up your hand.",
                diagram: AnyView(HStack(spacing: 10) {
                    CardView(card: Card(rank: .eight, suit: .hearts), width: 58, highlighted: true)
                    CardView(card: Card(rank: .eight, suit: .hearts, copy: 1), width: 58, highlighted: true)
                }))),
            AnyView(TechPage(
                title: "Spend them where they multiply",
                body: "Best to worst: ① complete a STRAIGHT FLUSH (a bomb from thin air) ② grow a bomb by one ③ finish a tube or plate ④ pair the level card itself (a 15-strength pair). Worst: padding a cheap pair.",
                diagram: AnyView(WildLadderDemo()))),
            AnyView(TechPage(
                title: "The mistake everyone makes",
                body: "Don't burn a wildcard early to win a meaningless trick. A held wildcard is a future bomb; a spent one is a 3 with makeup on. If in doubt, hold.",
                diagram: AnyView(HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("early cheap pair").font(.body(11)).foregroundStyle(Theme.coral)
                        Text("❌").font(.system(size: 32))
                    }
                    VStack(spacing: 4) {
                        Text("late straight flush").font(.body(11)).foregroundStyle(Theme.goldSoft)
                        Text("✅").font(.system(size: 32))
                    }
                }))),
        ])
    }
}

private struct WildLadderDemo: View {
    var body: some View {
        HStack(spacing: -14) {
            ForEach(Array([Card(rank: .four, suit: .clubs), Card(rank: .five, suit: .clubs),
                           Card(rank: .six, suit: .clubs), Card(rank: .seven, suit: .clubs)]
                .enumerated()), id: \.offset) { _, card in
                CardView(card: card, width: 44)
            }
            CardView(card: Card(rank: .eight, suit: .hearts), width: 44, highlighted: true)
        }
    }
}

// MARK: - Course 8: Bomb Timing

struct BombTimingLesson: View {
    var body: some View {
        PagedLessonView(lessonId: 23, pages: [
            AnyView(TechPage(
                title: "Bombs are tempo, not points",
                body: "A bomb doesn't score — it STEALS THE LEAD. Its whole value is choosing the moment the table resets to you. Spend it like money, not like fireworks.",
                diagram: AnyView(Text("💣 → 🎯").font(.system(size: 40))))),
            AnyView(TechPage(
                title: "Bomb these moments",
                body: "① An opponent is about to go out — stop the exit. ② A big table (full house of Aces) you can't otherwise answer AND you need the lead. ③ Your own hand exits cleanly right after the bomb.",
                diagram: AnyView(TimingTable(rows: [
                    ("Opponent at 1–3 cards", "BOMB", true),
                    ("You exit right after", "BOMB", true),
                    ("Big table + you need lead", "BOMB", true),
                ])))),
            AnyView(TechPage(
                title: "Hold through these",
                body: "① Cheap tricks — let them go. ② Your PARTNER is winning the trick. ③ Early game with no exit plan — a bomb without a follow-up just gifts everyone information.",
                diagram: AnyView(TimingTable(rows: [
                    ("Cheap single early", "HOLD", false),
                    ("Partner already winning", "HOLD", false),
                    ("No exit after bombing", "HOLD", false),
                ])))),
        ])
    }
}

private struct TimingTable: View {
    let rows: [(String, String, Bool)]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    Text(row.0).font(.body(14)).foregroundStyle(.white)
                    Spacer()
                    Text(row.1)
                        .font(.heading(13))
                        .foregroundStyle(row.2 ? Theme.ink : .white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(row.2 ? Theme.gold : Theme.coralDark, in: Capsule())
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: 340)
    }
}

// MARK: - Course 9: Card Counting

struct CardCountingLesson: View {
    var body: some View {
        PagedLessonView(lessonId: 20, pages: [
            AnyView(TechPage(
                title: "Count only what matters",
                body: "Nobody tracks 108 cards. Track FOUR things: the 2 big jokers, the 2 small jokers, the 8 level cards, and every bomb that explodes. That's it.",
                diagram: AnyView(HStack(spacing: 8) {
                    counter("JOKER", "2"); counter("joker", "2"); counter("LVL", "8"); counter("💣", "?")
                }))),
            AnyView(TechPage(
                title: "Jokers gone = your Aces rule",
                body: "Once both big jokers have hit the table, the strongest single left is a level card — and if those are gone too, your Ace is unbeatable. Singles you were scared to lead become winners.",
                diagram: AnyView(Text("🃏🃏 gone → A♠ = 👑").font(.system(size: 26)).foregroundStyle(.white)))),
            AnyView(TechPage(
                title: "Watch the card counters",
                body: "Every opponent's card count is on screen. At 5 cards or fewer, assume they hold an exit plan — stop leading the shapes they're waiting for, and save a bomb for their last play.",
                diagram: AnyView(HStack(spacing: 14) {
                    badge("Lena", "3", danger: true)
                    badge("Marco", "14", danger: false)
                }))),
        ])
    }

    private func counter(_ label: String, _ n: String) -> some View {
        VStack(spacing: 3) {
            Text(n).font(.display(22)).foregroundStyle(Theme.goldSoft)
            Text(label).font(.body(10)).foregroundStyle(Theme.mint)
        }
        .frame(width: 56, height: 56)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func badge(_ name: String, _ count: String, danger: Bool) -> some View {
        VStack(spacing: 4) {
            Circle().fill(danger ? Theme.coral : Theme.feltLight)
                .frame(width: 40, height: 40)
                .overlay(Text(String(name.prefix(1))).font(.display(17)).foregroundStyle(.white))
            Text("\(name) · \(count)")
                .font(.body(12)).foregroundStyle(danger ? Theme.coral : Theme.mint)
            if danger {
                Text("about to exit!").font(.body(10)).foregroundStyle(Theme.coral)
            }
        }
    }
}

// MARK: shared page

struct TechPage: View {
    let title: String
    let body_: String
    let diagram: AnyView

    init(title: String, body: String, diagram: AnyView) {
        self.title = title
        self.body_ = body
        self.diagram = diagram
    }

    var body: some View {
        HStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.display(26)).foregroundStyle(Theme.goldSoft)
                Text(body_).font(.body(15)).foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(4)
            }
            .frame(maxWidth: 380, alignment: .leading)
            diagram
        }
    }
}
