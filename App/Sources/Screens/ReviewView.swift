import SwiftUI
import GuandanCore

/// 复盘 — step through a finished hand with all cards face-up. Where the
/// human's move differs from the hard bot's choice, the coach shows their
/// alternative. Landscape layout: hands on the left, controls on the right.
struct ReviewView: View {
    let record: HandRecord
    let seatName: (Seat) -> String
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0   // actions applied so far

    private var engine: GameEngine { record.engineState(afterSteps: step) }

    /// The action about to happen at this position (nil at the very end).
    private var upcoming: (seat: Seat, action: PlayerAction)? {
        step < record.actions.count ? record.actions[step] : nil
    }

    var body: some View {
        ZStack {
            Theme.background

            HStack(spacing: 14) {
                handsColumn
                    .frame(maxWidth: .infinity)
                rightPanel
                    .frame(width: 320)
            }
            .padding(14)
        }
    }

    // MARK: all four hands, face up

    private var handsColumn: some View {
        VStack(spacing: 8) {
            ForEach([Seat.north, .west, .east, .south], id: \.self) { seat in
                seatRow(seat)
            }
        }
    }

    private func seatRow(_ seat: Seat) -> some View {
        let state = engine.state
        let cards = displaySorted(state.hands[seat] ?? [], level: record.level)
        let isNext = upcoming?.seat == seat
        let finishedIndex = state.finished.firstIndex(of: seat)

        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(seatName(seat))
                    .font(.heading(13))
                    .foregroundStyle(seat == .south ? Theme.goldSoft : .white)
                if seat == .south {
                    Text("YOU").font(.body(10)).foregroundStyle(Theme.ink)
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(Theme.gold, in: Capsule())
                }
                if let i = finishedIndex {
                    Text(["1st 🥇", "2nd 🥈", "3rd 🥉", "4th"][i])
                        .font(.body(11)).foregroundStyle(Theme.goldSoft)
                }
                if isNext {
                    Text("→ plays next").font(.body(11)).foregroundStyle(Theme.coral)
                }
                Spacer()
            }
            if cards.isEmpty {
                Text("out").font(.body(11)).foregroundStyle(Theme.mint.opacity(0.6))
                    .frame(height: 44)
            } else {
                HStack(spacing: -22) {
                    ForEach(cards) { card in
                        CardView(card: card, width: 34)
                    }
                }
                .frame(height: 50, alignment: .leading)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.white.opacity(isNext ? 0.1 : 0.05),
                    in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: right panel — table, move, coach, controls

    private var rightPanel: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Review · move \(step)/\(record.actions.count)")
                    .font(.heading(15)).foregroundStyle(Theme.goldSoft)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.heading(13)).foregroundStyle(Theme.mint)
                        .frame(width: 30, height: 30)
                        .background(.white.opacity(0.08), in: Circle())
                }
            }

            // table state
            VStack(spacing: 6) {
                if let table = engine.state.trick.tableCombo,
                   let owner = engine.state.trick.tableOwner {
                    Text("Table · \(seatName(owner))")
                        .font(.body(12)).foregroundStyle(Theme.mint)
                    HStack(spacing: -16) {
                        ForEach(table.cards) { card in CardView(card: card, width: 36) }
                    }
                } else {
                    Text("table empty").font(.body(12))
                        .foregroundStyle(Theme.mint.opacity(0.6))
                        .padding(.vertical, 16)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))

            // upcoming move + coach note
            if let next = upcoming {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(seatName(next.seat)): \(next.action.reviewDescription)")
                        .font(.heading(14)).foregroundStyle(.white)
                    if next.seat == .south, let note = coachNote(at: step) {
                        HStack(alignment: .top, spacing: 6) {
                            Text("🐼")
                            Text(note).font(.body(13)).foregroundStyle(Theme.goldSoft)
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            } else {
                Text("Hand over — \(seatName(record.finishOrder[0])) finished 1st")
                    .font(.heading(14)).foregroundStyle(Theme.goldSoft)
                    .padding(10)
            }

            Spacer()

            // transport controls
            HStack(spacing: 10) {
                control("backward.end.fill") { step = 0 }
                control("chevron.left") { if step > 0 { step -= 1 } }
                control("chevron.right") { if step < record.actions.count { step += 1 } }
                control("forward.end.fill") { step = record.actions.count }
            }
            Slider(value: Binding(get: { Double(step) },
                                  set: { step = Int($0.rounded()) }),
                   in: 0...Double(max(record.actions.count, 1)), step: 1)
                .tint(Theme.gold)
        }
    }

    private func control(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.heading(16)).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 40)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    /// Coach annotation: what the hard bot would do instead, when different.
    private func coachNote(at index: Int) -> String? {
        guard let actual = upcoming?.action,
              let coach = record.coachChoice(beforeStep: index) else { return nil }
        switch (actual, coach) {
        case (.pass, .pass):
            return nil
        case (.play(let a), .play(let b)) where Set(a.cards) == Set(b.cards):
            return "Good — exactly what I'd play."
        case (_, .pass):
            return "I'd PASS here — no need to spend cards on this trick."
        case (_, .play(let b)):
            return "I'd play \(b.cards.map(\.displayName).joined(separator: " ")) instead."
        }
    }
}
