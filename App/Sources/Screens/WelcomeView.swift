import SwiftUI
import GuandanCore

/// Mirror of the Stitch "Welcome to GuanDan!" screen.
struct WelcomeView: View {
    @Environment(Router.self) private var router

    private let heroCards: [Card] = [
        Card(rank: .bigJoker, suit: nil),
        Card(rank: .smallJoker, suit: nil),
        Card(rank: .ace, suit: .hearts),
        Card(rank: .king, suit: .spades),
        Card(rank: .queen, suit: .diamonds),
    ]

    var body: some View {
        ZStack {
            Theme.background

            VStack(spacing: 28) {
                Spacer()

                Text("GuanDan!")
                    .font(.display(52))
                    .foregroundStyle(Theme.goldSoft)
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                Text("The card game 100 million people\nplay in China")
                    .font(.body(17))
                    .foregroundStyle(Theme.mint)
                    .multilineTextAlignment(.center)

                // fanned hero hand
                ZStack {
                    ForEach(Array(heroCards.enumerated()), id: \.element.id) { i, card in
                        CardView(card: card, width: 86)
                            .rotationEffect(.degrees(Double(i - 2) * 9))
                            .offset(x: CGFloat(i - 2) * 34,
                                    y: abs(CGFloat(i - 2)) * 10)
                    }
                }
                .padding(.vertical, 24)

                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(title: "Learn in 5 minutes", icon: "graduationcap.fill") {
                        router.go(.lobby)   // tutorial lands in Sprint 5; lobby for now
                    }
                    SecondaryButton(title: "I already know how to play") {
                        router.go(.lobby)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
}
