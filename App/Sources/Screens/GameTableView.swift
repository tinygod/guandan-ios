import SwiftUI
import GuandanCore

/// Mirror of the Stitch "Playing 5s" game table screen.
struct GameTableView: View {
    @Environment(Router.self) private var router
    @State private var model: GameViewModel

    init(difficulty: BotDifficultyChoice) {
        _model = State(initialValue: GameViewModel(difficulty: difficulty))
    }

    @State private var reviewRecord: HandRecord?
    @State private var hudOn = false

    var body: some View {
        ZStack {
            Theme.background

            VStack(spacing: 4) {
                topBar
                HStack(spacing: 10) {
                    seatBadge(.west)
                    VStack(spacing: 6) {
                        seatBadge(.north)
                        tableCenter
                    }
                    seatBadge(.east)
                }
                humanArea
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 4)

            // counting HUD (记牌) — toggleable practice aid
            VStack {
                HStack {
                    Spacer()
                    countingHUD
                }
                Spacer()
            }
            .padding(.trailing, 10).padding(.top, 6)

            if let order = model.handResult {
                RoundResultOverlay(order: order, model: model) {
                    model.startHand()
                } onExit: {
                    router.home()
                } onReview: {
                    reviewRecord = model.lastHandRecord
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $reviewRecord) { record in
            ReviewView(record: record, seatName: { model.seatName($0) })
        }
    }

    // MARK: top bar

    private var topBar: some View {
        HStack {
            Button { router.home() } label: {
                Image(systemName: "xmark")
                    .font(.heading(15))
                    .foregroundStyle(Theme.mint)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.08), in: Circle())
            }
            Spacer()
            GoldPlaque(top: "CURRENT LEVEL", big: levelName,
                       bottom: "us \(rankName(model.match.levels[.northSouth])) · them \(rankName(model.match.levels[.eastWest]))")
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.top, 2)
    }

    private var levelName: String { rankName(model.state?.level) }

    /// Key-card tracker (taught in Counting & New Tops).
    private var countingHUD: some View {
        Button { withAnimation { hudOn.toggle() } } label: {
            if hudOn {
                let counts = model.keyCounts
                HStack(spacing: 10) {
                    hudItem("JOKER", counts.bigJokersLeft, max: 2)
                    hudItem("joker", counts.smallJokersLeft, max: 2)
                    hudItem("LVL", counts.levelCardsLeft, max: 8)
                    hudItem("💣", counts.bombsSeen, max: nil)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.black.opacity(0.5), in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.4)))
            } else {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14)).foregroundStyle(Theme.mint)
                    .frame(width: 32, height: 32)
                    .background(.black.opacity(0.35), in: Circle())
            }
        }
    }

    private func hudItem(_ label: String, _ n: Int, max: Int?) -> some View {
        VStack(spacing: 0) {
            Text("\(n)")
                .font(.heading(14))
                .foregroundStyle(max != nil && n == 0 ? Theme.coral : Theme.goldSoft)
            Text(label).font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Theme.mint)
        }
    }

    private func rankName(_ rank: Rank?) -> String {
        guard let rank else { return "–" }
        return rank.shortName + "s"
    }

    // MARK: opponents

    private func seatBadge(_ seat: Seat) -> some View {
        let isTurn = model.state?.turn == seat && model.handResult == nil
        let count = model.state?.hands[seat]?.count ?? 0
        let finished = model.state?.finished.contains(seat) ?? false
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(seat.team == .northSouth ? Theme.feltLight : Theme.coralDark)
                    .frame(width: 52, height: 52)
                Text(String(model.seatName(seat).prefix(1)))
                    .font(.display(22)).foregroundStyle(.white)
                if isTurn {
                    Circle().strokeBorder(Theme.gold, lineWidth: 3)
                        .frame(width: 58, height: 58)
                }
            }
            Text(model.seatName(seat)).font(.body(12)).foregroundStyle(Theme.mint)
            Text(finished ? "Done 🎉" : "\(count) cards")
                .font(.heading(11))
                .foregroundStyle(finished ? Theme.goldSoft : .white)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(.black.opacity(0.3), in: Capsule())

            if case .pass = model.lastPlays[seat], model.state?.trick.tableOwner != seat {
                Text("Pass").font(.body(11)).foregroundStyle(Theme.mint.opacity(0.8))
            }
        }
    }

    // MARK: table center

    private var tableCenter: some View {
        VStack(spacing: 10) {
            if let banner = model.tributeBanner {
                Text(banner)
                    .font(.body(12)).foregroundStyle(Theme.goldSoft)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.black.opacity(0.35), in: Capsule())
            }
            if let table = model.state?.trick.tableCombo,
               let owner = model.state?.trick.tableOwner {
                Text("\(model.seatName(owner)) · \(comboName(table))")
                    .font(.body(13)).foregroundStyle(Theme.mint)
                HStack(spacing: -22) {
                    ForEach(table.cards) { card in
                        CardView(card: card, width: 48)
                    }
                }
            } else {
                Text(model.isHumanTurn ? "Your lead — play anything" : "New trick")
                    .font(.body(14)).foregroundStyle(Theme.mint.opacity(0.8))
                    .padding(.vertical, 26)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 104)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 20))
    }

    private func comboName(_ combo: Combo) -> String {
        switch combo.kind {
        case .single: return "Single"
        case .pair: return "Pair"
        case .triple: return "Triple"
        case .fullHouse: return "Full House"
        case .straight: return "Straight"
        case .tube: return "Tube"
        case .plate: return "Plate"
        case .bomb(let size): return "\(size)-Bomb 💥"
        case .straightFlush: return "Straight Flush 💥"
        case .jokerBomb: return "FOUR JOKERS 👑"
        }
    }

    // MARK: human area — hand strip with action buttons docked right

    private var humanArea: some View {
        HStack(alignment: .center, spacing: 12) {
            HandFanView(cards: model.humanHand,
                        selection: model.selection,
                        cardWidth: 56) { model.toggle($0) }

            VStack(spacing: 8) {
                Group {
                    if let combo = model.selectionCombo {
                        Text(comboName(combo))
                            .foregroundStyle(model.selectionPlayable ? Theme.goldSoft : Theme.coral)
                    } else if !model.selection.isEmpty {
                        Text("Not a combo").foregroundStyle(Theme.coral)
                    } else {
                        Text(" ").foregroundStyle(.clear)
                    }
                }
                .font(.heading(12))
                .lineLimit(1)

                Button {
                    model.playSelection()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill").font(.system(size: 12))
                        Text("Play Combo")
                    }
                    .font(.heading(15)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 11)
                    .background(model.selectionPlayable ? Theme.coral : Theme.coral.opacity(0.3),
                                in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .shadow(color: model.selectionPlayable ? Theme.coral.opacity(0.4) : .clear,
                            radius: 8, y: 3)
                }
                .disabled(!model.selectionPlayable)

                Button {
                    model.pass()
                } label: {
                    Text("Pass")
                        .font(.heading(15)).foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity).padding(.vertical, 9)
                        .background(.white.opacity(model.isHumanTurn && model.mayPass ? 0.14 : 0.05),
                                    in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                }
                .disabled(!(model.isHumanTurn && model.mayPass))
            }
            .frame(width: 130)
        }
    }
}

