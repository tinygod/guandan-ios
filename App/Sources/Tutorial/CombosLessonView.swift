import SwiftUI
import GuandanCore

/// Lesson 2 — mirrors the Stitch "Card Combos" reference screen.
struct CombosLessonView: View {
    @Environment(Router.self) private var router
    @Environment(LessonProgress.self) private var progress
    @State private var learned = Set<String>()

    private struct ComboRow: Identifiable {
        let id: String
        let detail: String
        let cards: [Card]
        var flame: Bool = false

        var name: String { id }
    }

    private let rows: [ComboRow] = [
        .init(id: "Single", detail: "Any one card",
              cards: [Card(rank: .ace, suit: .spades)]),
        .init(id: "Pair", detail: "Two of the same rank",
              cards: [Card(rank: .eight, suit: .spades), Card(rank: .eight, suit: .hearts)]),
        .init(id: "Triple", detail: "Three of a kind",
              cards: [Card(rank: .king, suit: .spades), Card(rank: .king, suit: .hearts),
                      Card(rank: .king, suit: .clubs)]),
        .init(id: "Full House", detail: "Triple + pair",
              cards: [Card(rank: .nine, suit: .spades), Card(rank: .nine, suit: .hearts),
                      Card(rank: .nine, suit: .clubs), Card(rank: .four, suit: .spades),
                      Card(rank: .four, suit: .hearts)]),
        .init(id: "Straight", detail: "5 cards in a row, any suits",
              cards: [Card(rank: .five, suit: .spades), Card(rank: .six, suit: .hearts),
                      Card(rank: .seven, suit: .clubs), Card(rank: .eight, suit: .diamonds),
                      Card(rank: .nine, suit: .spades)]),
        .init(id: "Tube", detail: "3 consecutive pairs",
              cards: [Card(rank: .seven, suit: .spades), Card(rank: .seven, suit: .hearts),
                      Card(rank: .eight, suit: .spades), Card(rank: .eight, suit: .hearts),
                      Card(rank: .nine, suit: .spades), Card(rank: .nine, suit: .hearts)]),
        .init(id: "Plate", detail: "2 consecutive triples",
              cards: [Card(rank: .queen, suit: .spades), Card(rank: .queen, suit: .hearts),
                      Card(rank: .queen, suit: .clubs), Card(rank: .king, suit: .spades),
                      Card(rank: .king, suit: .hearts), Card(rank: .king, suit: .clubs)]),
        .init(id: "Bomb", detail: "4+ of a kind — beats any shape",
              cards: [Card(rank: .queen, suit: .spades), Card(rank: .queen, suit: .hearts),
                      Card(rank: .queen, suit: .clubs), Card(rank: .queen, suit: .diamonds)],
              flame: true),
        .init(id: "Straight Flush", detail: "Straight in one suit — big bomb",
              cards: [Card(rank: .three, suit: .clubs), Card(rank: .four, suit: .clubs),
                      Card(rank: .five, suit: .clubs), Card(rank: .six, suit: .clubs),
                      Card(rank: .seven, suit: .clubs)],
              flame: true),
        .init(id: "Four Jokers", detail: "The unbeatable king bomb",
              cards: [Card(rank: .bigJoker, suit: nil), Card(rank: .bigJoker, suit: nil, copy: 1),
                      Card(rank: .smallJoker, suit: nil), Card(rank: .smallJoker, suit: nil, copy: 1)],
              flame: true),
    ]

    var body: some View {
        ZStack {
            Theme.background

            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Card Combos").font(.display(28)).foregroundStyle(.white)
                    Text("Tap each combo once you've got it (\(learned.count)/\(rows.count))")
                        .font(.body(13)).foregroundStyle(Theme.mint)
                }
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(rows) { row in rowView(row) }
                    }
                    .padding(16)
                }

                PrimaryButton(title: learned.count == rows.count ? "Finish Lesson" : "Got them all?",
                              icon: "checkmark") {
                    guard learned.count == rows.count else { return }
                    progress.markComplete(2)
                    router.popOne()
                }
                .opacity(learned.count == rows.count ? 1 : 0.4)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            }
        }
    }

    private func rowView(_ row: ComboRow) -> some View {
        let done = learned.contains(row.id)
        return Button {
            withAnimation(.spring(duration: 0.25)) {
                if done { learned.remove(row.id) } else { learned.insert(row.id) }
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(row.name).font(.heading(15))
                            .foregroundStyle(row.flame ? Theme.coral : .white)
                        if row.flame { Text("🔥").font(.system(size: 12)) }
                        if done {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14)).foregroundStyle(Theme.gold)
                        }
                    }
                    Text(row.detail).font(.body(12)).foregroundStyle(Theme.mint)
                }
                Spacer()
                HStack(spacing: -14) {
                    ForEach(row.cards) { card in
                        CardView(card: card, width: 30)
                    }
                }
            }
            .padding(12)
            .background(.white.opacity(done ? 0.1 : 0.06),
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(done ? Theme.gold.opacity(0.5) : .white.opacity(0.08)))
        }
    }
}
