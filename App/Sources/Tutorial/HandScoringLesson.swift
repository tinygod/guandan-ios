import SwiftUI
import GuandanCore

/// Lesson 7 — Hand Scoring (丁华·科学计点法).
/// Interactive: rate three sample hands, pick a strategy, see the math.
struct HandScoringLesson: View {
    @Environment(Router.self) private var router
    @Environment(LessonProgress.self) private var progress

    enum Strategy: String, CaseIterable {
        case strong = "Go for 1st"
        case medium = "Play it by ear"
        case weak = "Support my partner"
    }

    struct Sample {
        let label: String
        let cards: [Card]
        let answer: Strategy
        let math: String
    }

    @State private var index = -1            // -1 = intro page
    @State private var picked: Strategy?
    @State private var solved = 0

    private let samples = HandScoringLesson.makeSamples()

    var body: some View {
        ZStack {
            Theme.background
            if index < 0 { intro } else { quiz(samples[index]) }
        }
        .navigationBarHidden(true)
    }

    // MARK: intro

    private var intro: some View {
        HStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Score your hand in 10 seconds")
                    .font(.display(26)).foregroundStyle(Theme.goldSoft)
                Text("Before playing a single card, rate your 27:\n\n💣  each bomb = +4 points\n👑  each top card (big joker, level pair…) = +1\n🪨  each dead small card = −1\n\n12+ → fight for 1st.  6–11 → stay flexible.  Under 6 → your job is feeding your partner.")
                    .font(.body(15)).foregroundStyle(.white.opacity(0.9)).lineSpacing(4)
            }
            .frame(maxWidth: 420, alignment: .leading)
            VStack(spacing: 14) {
                GoldPlaque(top: "STRONG", big: "12+", bottom: "go for 1st")
                GoldPlaque(top: "MEDIUM", big: "6–11", bottom: "play it by ear")
                GoldPlaque(top: "WEAK", big: "<6", bottom: "support partner")
                PrimaryButton(title: "Rate 3 hands", icon: "arrow.right") {
                    withAnimation { index = 0 }
                }
            }
            .frame(width: 230)
        }
        .padding(28)
    }

    // MARK: quiz

    private func quiz(_ sample: Sample) -> some View {
        VStack(spacing: 10) {
            Text("Hand \(index + 1) of \(samples.count) — what's your strategy?")
                .font(.heading(17)).foregroundStyle(Theme.goldSoft)
                .padding(.top, 10)

            HandFanView(cards: displaySorted(sample.cards, level: .two),
                        selection: [], cardWidth: 46) { _ in }

            HStack(spacing: 10) {
                ForEach(Strategy.allCases, id: \.self) { strategy in
                    Button {
                        guard picked == nil else { return }
                        picked = strategy
                        if strategy == sample.answer { solved += 1 }
                    } label: {
                        Text(strategy.rawValue)
                            .font(.heading(14))
                            .foregroundStyle(buttonFG(strategy, sample))
                            .frame(maxWidth: .infinity).padding(.vertical, 11)
                            .background(buttonBG(strategy, sample),
                                        in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .frame(maxWidth: 640)

            if let picked {
                HStack(alignment: .top, spacing: 8) {
                    Text("🐼")
                    Text((picked == sample.answer ? "Right! " : "Not quite — ") + sample.math)
                        .font(.body(13)).foregroundStyle(Theme.ink)
                        .padding(10)
                        .background(Theme.ivory, in: RoundedRectangle(cornerRadius: 12))
                }
                .frame(maxWidth: 640)

                PrimaryButton(title: index == samples.count - 1 ? "Finish Lesson" : "Next Hand",
                              icon: "arrow.right") {
                    if index == samples.count - 1 {
                        progress.markComplete(7)
                        router.popOne()
                    } else {
                        withAnimation { index += 1; self.picked = nil }
                    }
                }
                .frame(maxWidth: 320)
            }
            Spacer(minLength: 6)
        }
        .padding(.horizontal, 20)
    }

    private func buttonFG(_ s: Strategy, _ sample: Sample) -> Color {
        guard picked != nil else { return .white }
        return s == sample.answer ? Theme.ink : .white.opacity(0.5)
    }

    private func buttonBG(_ s: Strategy, _ sample: Sample) -> Color {
        guard picked != nil else { return .white.opacity(0.1) }
        if s == sample.answer { return Theme.gold }
        if s == picked { return Theme.coralDark.opacity(0.6) }
        return .white.opacity(0.05)
    }

    // MARK: sample hands (level 2; exact 27-card constructions)

    private static func makeSamples() -> [Sample] {
        func c(_ r: Rank, _ s: Suit?, _ copy: UInt8 = 0) -> Card { Card(rank: r, suit: s, copy: copy) }

        // STRONG ≈ 13: two bombs (+8), 2 big jokers (+2), level pair (+1),
        // AAA (+1 as near-top trio), structured rest, ~1 dead card (−1) ⇒ ~13
        let strong: [Card] = [
            c(.six, .spades), c(.six, .hearts), c(.six, .clubs), c(.six, .diamonds),
            c(.nine, .spades), c(.nine, .hearts), c(.nine, .clubs), c(.nine, .diamonds),
            c(.bigJoker, nil), c(.bigJoker, nil, 1),
            c(.two, .spades), c(.two, .clubs),
            c(.ace, .spades), c(.ace, .hearts), c(.ace, .clubs),
            c(.ten, .spades), c(.jack, .spades), c(.queen, .spades), c(.king, .spades),
            c(.ten, .hearts), c(.jack, .hearts), c(.queen, .hearts), c(.king, .hearts),
            c(.eight, .clubs), c(.eight, .hearts), c(.seven, .clubs), c(.four, .diamonds),
        ]

        // MEDIUM ≈ 7: one bomb (+4), small joker pair (+1ish), KK (+1),
        // scattered smalls (−2) and decent middles
        let medium: [Card] = [
            c(.jack, .spades), c(.jack, .hearts), c(.jack, .clubs), c(.jack, .diamonds),
            c(.smallJoker, nil), c(.smallJoker, nil, 1),
            c(.king, .spades), c(.king, .hearts),
            c(.queen, .clubs), c(.ten, .diamonds),
            c(.nine, .spades), c(.eight, .hearts), c(.seven, .clubs), c(.six, .diamonds),
            c(.five, .spades), c(.five, .hearts),
            c(.four, .clubs), c(.four, .diamonds),
            c(.three, .spades), c(.three, .hearts),
            c(.eight, .spades), c(.nine, .diamonds), c(.ten, .clubs),
            c(.seven, .diamonds), c(.six, .clubs), c(.queen, .diamonds), c(.ace, .diamonds),
        ]

        // WEAK ≈ 2: no bomb, one Ace pair as only muscle, many dead smalls
        let weak: [Card] = [
            c(.ace, .spades), c(.ace, .hearts),
            c(.queen, .clubs), c(.jack, .diamonds),
            c(.ten, .spades), c(.nine, .hearts), c(.eight, .clubs),
            c(.seven, .diamonds), c(.seven, .spades),
            c(.six, .hearts), c(.six, .clubs),
            c(.five, .diamonds), c(.five, .spades),
            c(.four, .hearts), c(.four, .clubs),
            c(.three, .diamonds), c(.three, .spades),
            c(.ten, .hearts), c(.nine, .clubs), c(.eight, .diamonds),
            c(.queen, .spades), c(.jack, .clubs),
            c(.three, .clubs, 1), c(.four, .spades, 1), c(.five, .clubs, 1),
            c(.six, .diamonds, 1), c(.eight, .hearts, 1),
        ]

        return [
            Sample(label: "strong", cards: strong, answer: .strong,
                   math: "Two bombs (+8), both big jokers (+2), the level pair (+1), triple Aces and two royal runs — about 13 points. Plant the flag: this hand fights for 1st."),
            Sample(label: "medium", cards: medium, answer: .medium,
                   math: "One bomb (+4), small-joker pair and Kings (+2)… but four dead small cards (−4ish). Around 6–7 points: stay flexible, watch one trick before committing."),
            Sample(label: "weak", cards: weak, answer: .weak,
                   math: "No bomb, one Ace pair, and a swamp of dead smalls — barely 2 points. A pro doesn't fight this: block enemies, feed your partner, take the assist."),
        ]
    }
}

/// Placeholder for courses arriving in the next stages.
struct ComingSoonLesson: View {
    let info: Lessons.Info
    @Environment(Router.self) private var router

    var body: some View {
        ZStack {
            Theme.background
            VStack(spacing: 14) {
                Image(systemName: info.icon)
                    .font(.system(size: 40)).foregroundStyle(Theme.gold)
                Text(info.title).font(.display(26)).foregroundStyle(.white)
                Text("This course is being polished by Coach Pan 🐼 — arriving in the next update.")
                    .font(.body(15)).foregroundStyle(Theme.mint)
                SecondaryButton(title: "Back") { router.popOne() }
                    .frame(width: 200)
            }
        }
        .navigationBarHidden(true)
    }
}
