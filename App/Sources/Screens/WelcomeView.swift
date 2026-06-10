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

            HStack(spacing: 30) {
                // left: brand + actions
                VStack(spacing: 16) {
                    Spacer()
                    Text("GuanDan!")
                        .font(.display(48))
                        .foregroundStyle(Theme.goldSoft)
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    Text("The card game 100 million people\nplay in China — learn it in minutes")
                        .font(.body(15))
                        .foregroundStyle(Theme.mint)
                        .multilineTextAlignment(.center)
                    Spacer()
                    PrimaryButton(title: "Start Learning", icon: "graduationcap.fill") {
                        router.go(.learn)
                    }
                    SecondaryButton(title: "I already know how to play") {
                        router.go(.lobby)
                    }
                    Spacer()
                }
                .frame(maxWidth: 340)

                // right: hero fan
                ZStack {
                    ForEach(Array(heroCards.enumerated()), id: \.element.id) { i, card in
                        CardView(card: card, width: 96)
                            .rotationEffect(.degrees(Double(i - 2) * 10))
                            .offset(x: CGFloat(i - 2) * 40,
                                    y: abs(CGFloat(i - 2)) * 12)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 40)
        }
        .navigationBarHidden(true)
    }
}
