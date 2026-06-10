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

            VStack(spacing: 2) {
                topBar
                HStack(alignment: .top, spacing: 6) {
                    VStack(spacing: 2) {
                        seatBadge(.west)
                        seatPlay(.west)
                    }
                    VStack(spacing: 2) {
                        HStack(alignment: .top, spacing: 8) {
                            Spacer()
                            seatBadge(.north)
                            seatPlay(.north)
                            Spacer()
                        }
                        tableCenter
                    }
                    VStack(spacing: 2) {
                        seatBadge(.east)
                        seatPlay(.east)
                    }
                }
                actionRow
                GroupedHandView(cards: model.humanHand,
                                level: model.state?.level ?? .two,
                                mode: sortMode,
                                selection: model.selection,
                                lockedGroups: model.displayGroups) { model.toggle($0) }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 2)

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
        return VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(seat.team == .northSouth ? Theme.feltLight : Theme.coralDark)
                    .frame(width: 40, height: 40)
                Text(String(model.seatName(seat).prefix(1)))
                    .font(.display(17)).foregroundStyle(.white)
                if isTurn {
                    Circle().strokeBorder(Theme.gold, lineWidth: 2.5)
                        .frame(width: 45, height: 45)
                }
            }
            Text(finished ? "🎉" : "\(count)")
                .font(.heading(10))
                .foregroundStyle(finished ? Theme.goldSoft : .white)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(.black.opacity(0.3), in: Capsule())
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
                    .padding(.vertical, 14)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56)
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

    // MARK: per-seat last play (出牌驻留)

    @ViewBuilder
    private func seatPlay(_ seat: Seat) -> some View {
        switch model.lastPlays[seat] {
        case .play(let combo):
            VStack(spacing: 1) {
                HStack(spacing: -14) {
                    ForEach(combo.cards) { card in CardView(card: card, width: 28) }
                }
                Text(comboName(combo))
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Theme.gold, in: Capsule())
            }
        case .pass:
            Text("Pass")
                .font(.heading(12)).foregroundStyle(Theme.mint.opacity(0.85))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(.black.opacity(0.3), in: Capsule())
        case nil:
            EmptyView()
        }
    }

    // MARK: action row — Pass / Hint / Play pills above the hand

    @State private var sortMode: HandSortMode = .byRank

    private var actionRow: some View {
        HStack(spacing: 10) {
            // sort toggle, left
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    sortMode = sortMode == .byRank ? .combos : .byRank
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: sortMode == .byRank ? "wand.and.stars" : "list.number")
                        .font(.system(size: 10))
                    Text(sortMode == .byRank ? "Smart Sort" : "By Rank").font(.heading(11))
                }
                .foregroundStyle(Theme.goldSoft)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.white.opacity(0.1), in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.35)))
            }

            // organize (理牌) — lock the selected combo into an edge group
            if model.canGroupSelection {
                Button { model.groupSelection() } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill").font(.system(size: 9))
                        Text("Organize").font(.heading(11))
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Theme.goldSoft, in: Capsule())
                }
            }
            if !model.displayGroups.isEmpty {
                Button { model.resetGroups() } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.uturn.backward").font(.system(size: 9))
                        Text("Reset").font(.heading(11))
                    }
                    .foregroundStyle(Theme.mint)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.white.opacity(0.1), in: Capsule())
                }
            }

            Spacer()

            Group {
                if let combo = model.selectionCombo {
                    Text(comboName(combo))
                        .foregroundStyle(model.selectionPlayable ? Theme.goldSoft : Theme.coral)
                } else if !model.selection.isEmpty {
                    Text("Not a combo").foregroundStyle(Theme.coral)
                }
            }
            .font(.heading(12)).lineLimit(1)

            if model.isHumanTurn {
                if model.mayPass {
                    pill("Pass", color: .white.opacity(0.16), textColor: .white) {
                        model.pass()
                    }
                }
                if model.hintAvailable {
                    pill("Hint 💡", color: Theme.feltLight, textColor: Theme.mintBright) {
                        model.hint()
                    }
                }
                pill("Play ▸", color: model.selectionPlayable ? Theme.coral : Theme.coral.opacity(0.3),
                     textColor: .white) {
                    model.playSelection()
                }
                .disabled(!model.selectionPlayable)
            }
        }
        .frame(height: 36)
    }

    private func pill(_ title: String, color: Color, textColor: Color,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.heading(14)).foregroundStyle(textColor)
                .padding(.horizontal, 18).padding(.vertical, 8)
                .background(color, in: Capsule())
        }
    }
}

