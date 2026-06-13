import SwiftUI
import GuandanCore

/// Round result celebration — landscape: standings left, actions right.
struct RoundResultOverlay: View {
    let order: [Seat]
    let model: GameViewModel
    let onNext: () -> Void
    let onExit: () -> Void
    let onReview: () -> Void

    private var humanTeamWon: Bool { order[0].team == .northSouth }
    private var matchOver: Bool { model.match.matchWinner != nil }

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            HStack(spacing: 20) {
                // standings
                VStack(spacing: 8) {
                    ForEach(Array(order.enumerated()), id: \.offset) { i, seat in
                        HStack {
                            Text(medal(i)).font(.body(16))
                            Text(tr(model.seatName(seat)))
                                .font(.heading(15)).foregroundStyle(.white)
                            Spacer()
                            Text(tr(seat.team == .northSouth ? "Your team" : "Opponents"))
                                .font(.body(12))
                                .foregroundStyle(seat.team == .northSouth ? Theme.goldSoft : Theme.mint)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .frame(width: 270)

                // headline + actions
                VStack(spacing: 12) {
                    Text(tr(headline))
                        .font(.display(28))
                        .foregroundStyle(humanTeamWon ? Theme.goldSoft : Theme.mintBright)
                        .multilineTextAlignment(.center)

                    Text(levelLine)
                        .font(.body(13)).foregroundStyle(Theme.mint)
                        .multilineTextAlignment(.center)

                    SecondaryButton(title: "Review Hand 🔍") { onReview() }

                    if !matchOver {
                        PrimaryButton(title: "Next Hand", icon: "arrow.right") { onNext() }
                    }
                    SecondaryButton(title: matchOver ? "Back to Home" : "Leave Table") { onExit() }
                }
                .frame(width: 250)
            }
            .padding(22)
            .background(Theme.felt, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.15)))
            .padding(20)
        }
    }

    private var headline: String {
        if matchOver {
            return humanTeamWon ? "Match Won! 🏆" : "Match Lost"
        }
        return humanTeamWon ? "Round Won! 🎉" : "Round Lost"
    }

    private func medal(_ i: Int) -> String {
        ["🥇", "🥈", "🥉", "4th"][i]
    }

    private var levelLine: String {
        let us = model.match.levels[.northSouth]!.shortName
        let them = model.match.levels[.eastWest]!.shortName
        if let winner = model.match.matchWinner {
            return winner == .northSouth
                ? tr("Your team conquered the Ace level!")
                : tr("Opponents took the match at Ace level.")
        }
        return String(format: tr("Your team: %@ · Opponents: %@ — next hand plays %@s"), us, them, model.match.activeLevel.shortName)
    }
}
