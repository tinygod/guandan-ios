import SwiftUI
import GuandanCore

/// Mirror of the Stitch "Round Won" celebration, shown over the table.
struct RoundResultOverlay: View {
    let order: [Seat]
    let model: GameViewModel
    let onNext: () -> Void
    let onExit: () -> Void

    private var humanTeamWon: Bool { order[0].team == .northSouth }
    private var matchOver: Bool { model.match.matchWinner != nil }

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: 18) {
                Text(headline)
                    .font(.display(34))
                    .foregroundStyle(humanTeamWon ? Theme.goldSoft : Theme.mintBright)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    ForEach(Array(order.enumerated()), id: \.offset) { i, seat in
                        HStack {
                            Text(medal(i)).font(.body(18))
                            Text(model.seatName(seat))
                                .font(.heading(16)).foregroundStyle(.white)
                            Spacer()
                            Text(seat.team == .northSouth ? "Your team" : "Opponents")
                                .font(.body(13))
                                .foregroundStyle(seat.team == .northSouth ? Theme.goldSoft : Theme.mint)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(.white.opacity(0.07),
                                    in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                Text(levelLine)
                    .font(.body(15)).foregroundStyle(Theme.mint)
                    .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    if !matchOver {
                        PrimaryButton(title: "Next Hand", icon: "arrow.right") { onNext() }
                    }
                    SecondaryButton(title: matchOver ? "Back to Lobby" : "Leave Table") { onExit() }
                }
            }
            .padding(24)
            .frame(maxWidth: 360)
            .background(Theme.felt, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.15)))
            .padding(24)
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
                ? "Your team conquered the Ace level!"
                : "Opponents took the match at Ace level."
        }
        return "Levels — your team: \(us) · opponents: \(them)\nNext hand plays \(model.match.activeLevel.shortName)s"
    }
}
