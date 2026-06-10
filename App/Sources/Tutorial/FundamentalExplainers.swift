import SwiftUI
import GuandanCore

// MARK: - Lesson 8: Hand Planning (理牌与拆牌)

struct HandPlanningLesson: View {
    var body: some View {
        PagedLessonView(lessonId: 8, pages: [
            AnyView(LessonPage(
                title: "Three kinds of loners",
                body: "Singles come from three places: BORN single (nothing connects), LEFTOVER single (you built a straight and one card fell out), and BROKEN single (you split a set to answer a trick). Plan to have as few as possible.",
                diagram: AnyView(LonersDemo()))),
            AnyView(LessonPage(
                title: "Good split vs bad split",
                body: "The same 27 cards can be 9 tidy moves or 13 ragged ones. Keep bombs whole, build the longest runs, and let pairs stay pairs. Count your moves: a winner plays out in about 10.",
                diagram: AnyView(SplitDemo()))),
            AnyView(LessonPage(
                title: "A straight isn't free",
                body: "Building a low straight that strands 3 extra singles is a bad trade — you removed one move and added three. Build runs to SHRINK your single count, not to admire the shape.",
                diagram: AnyView(HStack(spacing: -12) {
                    ForEach(Array([Card(rank: .two, suit: .clubs), Card(rank: .three, suit: .clubs),
                                   Card(rank: .four, suit: .hearts), Card(rank: .five, suit: .spades),
                                   Card(rank: .six, suit: .diamonds)].enumerated()), id: \.offset) { _, card in
                        CardView(card: card, width: 42)
                    }
                }))),
        ])
    }
}

private struct LonersDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            row("Born", "a lone 6 with no neighbours")
            row("Leftover", "built 2-3-4-5-6, the spare 4 fell out")
            row("Broken", "split AAA to beat a pair, one A left")
        }
    }

    private func row(_ kind: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Text(kind).font(.heading(13)).foregroundStyle(Theme.goldSoft)
                .frame(width: 76, alignment: .leading)
            Text(text).font(.body(13)).foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct SplitDemo: View {
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text("✅ 9 moves").font(.heading(13)).foregroundStyle(Theme.goldSoft)
                Text("bomb · run · run · 3 pairs · 3 singles")
                    .font(.body(12)).foregroundStyle(Theme.mint)
            }
            HStack(spacing: 8) {
                Text("❌ 13 moves").font(.heading(13)).foregroundStyle(Theme.coral)
                Text("bomb split into pairs, runs never built")
                    .font(.body(12)).foregroundStyle(Theme.mint)
            }
        }
        .padding(14)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Lesson 11: Catching the Wind (接风与让牌)

struct CatchingWindLesson: View {
    var body: some View {
        PagedLessonView(lessonId: 11, pages: [
            AnyView(LessonPage(
                title: "The free lead",
                body: "When a player goes out and nobody beats their final play, the next lead doesn't go around the table — it lands on their PARTNER. That's catching the wind: a whole free turn.",
                diagram: AnyView(WindDemo()))),
            AnyView(LessonPage(
                title: "Earn it on purpose",
                body: "When your partner is down to a few cards, stop competing — clear small shapes for them and let their last play stand. Engineering a caught wind is one of the cheapest wins in GuanDan.",
                diagram: AnyView(Text("🤝 → 🍃 → 🏆").font(.system(size: 36)))),
            ),
        ])
    }
}

private struct WindDemo: View {
    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                Circle().fill(Theme.feltLight).frame(width: 40, height: 40)
                    .overlay(Text("P").font(.display(16)).foregroundStyle(.white))
                Text("partner out").font(.body(11)).foregroundStyle(Theme.mint)
            }
            Image(systemName: "wind").font(.system(size: 22)).foregroundStyle(Theme.gold)
            VStack(spacing: 4) {
                Circle().fill(Theme.gold).frame(width: 40, height: 40)
                    .overlay(Text("U").font(.display(16)).foregroundStyle(Theme.ink))
                Text("you lead, free").font(.body(11)).foregroundStyle(Theme.goldSoft)
            }
        }
    }
}
