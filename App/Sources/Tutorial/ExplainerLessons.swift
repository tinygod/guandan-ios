import SwiftUI
import GuandanCore

/// Shared paged explainer container (lessons 1 & 4) — mirrors the Stitch
/// onboarding screens: pages, progress dots, Next/Done.
struct PagedLessonView<Page: View>: View {
    let lessonId: Int
    let pages: [Page]
    @Environment(Router.self) private var router
    @Environment(LessonProgress.self) private var progress
    @State private var index = 0

    var body: some View {
        ZStack {
            Theme.background

            VStack(spacing: 20) {
                TabView(selection: $index) {
                    ForEach(pages.indices, id: \.self) { i in
                        pages[i].tag(i).padding(.horizontal, 24)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                PrimaryButton(title: index == pages.count - 1 ? "Finish Lesson" : "Next",
                              icon: index == pages.count - 1 ? "checkmark" : "arrow.right") {
                    if index < pages.count - 1 {
                        withAnimation { index += 1 }
                    } else {
                        progress.markComplete(lessonId)
                        router.popOne()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Lesson 1: What is GuanDan?

struct WhatIsGuandanLesson: View {
    var body: some View {
        PagedLessonView(lessonId: 1, pages: [
            AnyView(explainPage(
                title: "What is GuanDan?",
                emoji: "🀄️",
                body: "GuanDan (掼蛋, \"throwing eggs\") is China's most-played card game — over 100 million players. It's a climbing game: shed all your cards before the others do.",
                diagram: AnyView(TeamDiagram()))),
            AnyView(explainPage(
                title: "Two decks, four players",
                emoji: "🃏",
                body: "108 cards: two full decks plus four jokers. You and your partner sit ACROSS from each other and win or lose together — 2 vs 2.",
                diagram: AnyView(DeckFan()))),
            AnyView(explainPage(
                title: "Race from 2 to Ace",
                emoji: "🏔️",
                body: "Your team starts at level 2. Win hands to climb — first team to win a hand while playing their Ace level wins the match.",
                diagram: AnyView(MiniLadder()))),
        ])
    }

    private func explainPage(title: String, emoji: String, body bodyText: String,
                             diagram: AnyView) -> some View {
        HStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 12) {
                Text(emoji).font(.system(size: 44))
                Text(title).font(.display(26)).foregroundStyle(Theme.goldSoft)
                Text(bodyText).font(.body(15)).foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(4)
            }
            .frame(maxWidth: 360, alignment: .leading)
            diagram
        }
    }
}

/// 4 avatars around a table, partners connected.
private struct TeamDiagram: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.25))
                .frame(width: 190, height: 130)
            seat("You", Theme.gold, x: 0, y: 55)
            seat("Partner", Theme.gold, x: 0, y: -55)
            seat("Rival", Theme.coral, x: -85, y: 0)
            seat("Rival", Theme.coral, x: 85, y: 0)
            Rectangle().fill(Theme.gold.opacity(0.5)).frame(width: 2, height: 76)
        }
        .frame(height: 160)
    }

    private func seat(_ label: String, _ color: Color, x: CGFloat, y: CGFloat) -> some View {
        VStack(spacing: 2) {
            Circle().fill(color).frame(width: 34, height: 34)
            Text(label).font(.body(11)).foregroundStyle(Theme.mint)
        }
        .offset(x: x, y: y)
    }
}

private struct DeckFan: View {
    var body: some View {
        HStack(spacing: -30) {
            CardView(card: Card(rank: .ace, suit: .spades), width: 56)
                .rotationEffect(.degrees(-10))
            CardView(card: Card(rank: .ace, suit: .spades, copy: 1), width: 56)
                .rotationEffect(.degrees(0))
            CardView(card: Card(rank: .bigJoker, suit: nil), width: 56)
                .rotationEffect(.degrees(10))
        }
        .frame(height: 100)
    }
}

private struct MiniLadder: View {
    var body: some View {
        HStack(spacing: 6) {
            ForEach(["2", "5", "8", "J", "A"], id: \.self) { step in
                Text(step)
                    .font(.heading(16))
                    .foregroundStyle(step == "A" ? Theme.ink : .white)
                    .frame(width: 40, height: 40)
                    .background(step == "A" ? Theme.gold : .white.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 10))
                if step != "A" {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11)).foregroundStyle(Theme.mint)
                }
            }
        }
    }
}

// MARK: - Lesson 4: Climb to Ace (levels, wildcard, tribute)

struct ClimbToAceLesson: View {
    var body: some View {
        PagedLessonView(lessonId: 4, pages: [
            AnyView(page(
                title: "Winning moves you up",
                body: "Finish 1st and your team climbs. The further your partner gets, the bigger the jump.",
                diagram: AnyView(DeltaTable()))),
            AnyView(page(
                title: "The level card is special",
                body: "While your team plays level 8, all 8s outrank even Aces. And the two HEART 8s are wildcards — they can stand in for any card you need.",
                diagram: AnyView(WildcardDemo()))),
            AnyView(page(
                title: "Tribute — the loser pays",
                body: "Lose badly and you owe tribute: your single highest card goes to the winner, who hands back any card of 10 or below. Hold both big jokers to refuse!",
                diagram: AnyView(TributeDemo()))),
        ])
    }

    private func page(title: String, body bodyText: String, diagram: AnyView) -> some View {
        HStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.display(26)).foregroundStyle(Theme.goldSoft)
                Text(bodyText).font(.body(15)).foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(4)
            }
            .frame(maxWidth: 360, alignment: .leading)
            diagram
        }
    }
}

private struct DeltaTable: View {
    var body: some View {
        VStack(spacing: 8) {
            row("Partner finishes 2nd", "+3 levels", strong: true)
            row("Partner finishes 3rd", "+2 levels", strong: false)
            row("Partner finishes last", "+1 level", strong: false)
        }
        .frame(maxWidth: 300)
    }

    private func row(_ left: String, _ right: String, strong: Bool) -> some View {
        HStack {
            Text(left).font(.body(14)).foregroundStyle(.white)
            Spacer()
            Text(right).font(.heading(14))
                .foregroundStyle(strong ? Theme.goldSoft : Theme.mint)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct WildcardDemo: View {
    var body: some View {
        HStack(spacing: 10) {
            CardView(card: Card(rank: .eight, suit: .hearts), width: 60, highlighted: true)
            Image(systemName: "arrow.right").foregroundStyle(Theme.mint)
            Text("any\ncard")
                .font(.heading(13)).foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .frame(width: 60, height: 84)
                .background(Theme.goldSoft, in: RoundedRectangle(cornerRadius: 9))
        }
    }
}

private struct TributeDemo: View {
    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                CardView(card: Card(rank: .ace, suit: .spades), width: 52)
                Text("loser pays").font(.body(11)).foregroundStyle(Theme.mint)
            }
            Image(systemName: "arrow.left.arrow.right").foregroundStyle(Theme.gold)
            VStack(spacing: 4) {
                CardView(card: Card(rank: .six, suit: .clubs), width: 52)
                Text("winner returns").font(.body(11)).foregroundStyle(Theme.mint)
            }
        }
    }
}
