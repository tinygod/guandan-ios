import SwiftUI
import GuandanCore

/// Bridges GuandanCore to SwiftUI: the human sits south, bots play the other
/// three seats with a small delay so turns are readable.
@Observable
@MainActor
final class GameViewModel {
    private(set) var match = MatchSession()
    private(set) var engine: GameEngine?
    private(set) var selection = Set<Card>()
    private(set) var lastPlays: [Seat: PlayerAction] = [:]  // what each seat just did
    private(set) var handResult: [Seat]?                    // finish order when hand ends
    private(set) var tributeBanner: String?
    private(set) var lastHandRecord: HandRecord?            // for review (复盘)

    private var initialHands: [Seat: [Card]] = [:]
    private var firstLeader: Seat = .south
    private var actionLog: [(seat: Seat, action: PlayerAction)] = []

    private var bots: [Seat: any Bot] = [:]
    private var rng = SeededGenerator(seed: UInt64.random(in: 0...UInt64.max))
    private var seed = UInt64.random(in: 0...UInt64.max)
    private var previousFinishOrder: [Seat]?
    private var botTask: Task<Void, Never>?

    let difficulty: BotDifficultyChoice

    init(difficulty: BotDifficultyChoice) {
        self.difficulty = difficulty
        let botDifficulty: BotDifficulty = switch difficulty {
        case .easy: .easy
        case .normal: .normal
        case .hard: .hard
        }
        // each table gets personalities (taught in Reading Opponents)
        var styleRng = SeededGenerator(seed: seed)
        let styles: [BotStyle] = [.controller, .charger, .balanced].shuffled(using: &styleRng)
        for (i, seat) in [Seat.east, .north, .west].enumerated() {
            bots[seat] = HeuristicBot(difficulty: botDifficulty,
                                      style: botDifficulty == .easy ? .balanced : styles[i])
        }
        startHand()
    }

    var state: HandState? { engine?.state }
    var humanHand: [Card] {
        guard let engine else { return [] }
        return displaySorted(engine.state.hands[.south] ?? [], level: engine.state.level)
    }
    var isHumanTurn: Bool { engine?.state.turn == .south && handResult == nil }
    var mayPass: Bool { engine?.mayPass ?? false }

    /// The combo the current selection forms, if any.
    var selectionCombo: Combo? {
        guard let engine, !selection.isEmpty else { return nil }
        return Combo.detect(Array(selection), level: engine.state.level)
    }

    /// Whether the current selection is playable right now.
    var selectionPlayable: Bool {
        guard let engine, isHumanTurn, let combo = selectionCombo else { return false }
        if let table = engine.state.trick.tableCombo,
           engine.state.trick.tableOwner != .south {
            return combo.beats(table, level: engine.state.level)
        }
        return true
    }

    func toggle(_ card: Card) {
        if selection.contains(card) { selection.remove(card) } else { selection.insert(card) }
    }

    func playSelection() {
        guard let combo = selectionCombo, selectionPlayable else { return }
        apply(.play(combo), by: .south)
        selection = []
        hintIndex = 0
    }

    // MARK: manual organize (理牌锁组)

    struct HandGroup: Identifiable {
        let id = UUID()
        var cards: [Card]
        let kind: ComboKind
    }

    private(set) var customGroups: [HandGroup] = []

    /// Selection can be locked into a group when it forms a real combo.
    var canGroupSelection: Bool {
        selection.count >= 2 && selectionCombo != nil
    }

    func groupSelection() {
        guard let combo = selectionCombo, selection.count >= 2,
              let engine else { return }
        customGroups.append(HandGroup(
            cards: displaySorted(Array(selection), level: engine.state.level),
            kind: combo.kind))
        selection = []
    }

    func resetGroups() { customGroups = [] }

    /// Groups pruned to cards still in hand (played cards drop out).
    var displayGroups: [HandGroup] {
        let hand = Set(engine?.state.hands[.south] ?? [])
        return customGroups.compactMap { group in
            let remaining = group.cards.filter { hand.contains($0) }
            guard remaining.count >= 2 else { return nil }
            return HandGroup(cards: remaining, kind: group.kind)
        }
    }

    // MARK: hint (提示) — cycle through legal plays, weakest first

    private var hintIndex = 0

    var hintAvailable: Bool {
        guard let engine, isHumanTurn else { return false }
        return !engine.legalCombos(for: .south).isEmpty
    }

    func hint() {
        guard let engine, isHumanTurn else { return }
        let candidates = engine.legalCombos(for: .south)
        guard !candidates.isEmpty else { return }
        let pick = candidates[hintIndex % candidates.count]
        hintIndex += 1
        selection = Set(pick.cards)
    }

    func pass() {
        guard isHumanTurn, mayPass else { return }
        apply(.pass, by: .south)
        selection = []
    }

    func startHand() {
        botTask?.cancel()
        seed &+= 0x9E37
        var hands: [Seat: [Card]]
        let dealt = Deck.deal(seed: seed)
        hands = [.south: dealt[0], .east: dealt[1], .north: dealt[2], .west: dealt[3]]
        var leader = Seat.south
        tributeBanner = nil

        if let prev = previousFinishOrder {
            let level = match.activeLevel
            let resolution = Tribute.resolve(finishOrder: prev, hands: hands, level: level)
            if resolution.antiTribute {
                tributeBanner = "Anti-tribute! The losers hold both big jokers."
            } else if !resolution.transfers.isEmpty {
                Tribute.apply(resolution.transfers, to: &hands)
                let returns = resolution.transfers.map { t in
                    Tribute.Transfer(from: t.to, to: t.from,
                                     card: MatchRunner.returnCard(from: hands[t.to]!,
                                                                  level: level))
                }
                Tribute.apply(returns, to: &hands)
                let summary = resolution.transfers
                    .map { "\(seatName($0.from)) pays \($0.card.displayName)" }
                    .joined(separator: ", ")
                tributeBanner = "Tribute: \(summary)"
            }
            leader = resolution.firstLeader
        }

        engine = GameEngine(level: match.activeLevel, hands: hands, firstLeader: leader)
        handResult = nil
        lastPlays = [:]
        selection = []
        initialHands = hands
        firstLeader = leader
        actionLog = []
        scheduleBotsIfNeeded()
    }

    private func apply(_ action: PlayerAction, by seat: Seat) {
        guard var e = engine else { return }
        do {
            try e.apply(action, by: seat)
            engine = e
            // new trick: clear the per-seat play display
            if e.state.trick.tableCombo == nil {
                lastPlays = [:]
            } else {
                lastPlays[seat] = action
            }
            actionLog.append((seat, action))
            if e.state.isOver {
                finishHand()
            } else {
                scheduleBotsIfNeeded()
            }
        } catch {
            assertionFailure("illegal action reached engine: \(error)")
        }
    }

    private func finishHand() {
        guard let e = engine else { return }
        let order = e.state.finishOrder
        handResult = order
        previousFinishOrder = order
        lastHandRecord = HandRecord(level: e.state.level, initialHands: initialHands,
                                    firstLeader: firstLeader, actions: actionLog,
                                    finishOrder: order)
        match.recordHand(finishOrder: order)
    }

    private func scheduleBotsIfNeeded() {
        guard let e = engine, e.state.turn != .south, !e.state.isOver else { return }
        botTask?.cancel()
        botTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(700))
            guard let self, !Task.isCancelled else { return }
            guard let engine = self.engine, engine.state.turn != .south,
                  self.handResult == nil else { return }
            let seat = engine.state.turn
            let action = self.bots[seat]!.decide(engine: engine, seat: seat, rng: &self.rng)
            self.apply(action, by: seat)
        }
    }

    func seatName(_ seat: Seat) -> String {
        switch seat {
        case .south: return "You"
        case .east: return "Lena"
        case .north: return "Coach Wu"
        case .west: return "Marco"
        }
    }

    // MARK: counting HUD (记牌)

    struct KeyCardCounts {
        var bigJokersLeft = 2
        var smallJokersLeft = 2
        var levelCardsLeft = 8
        var bombsSeen = 0
    }

    /// Key cards you CANNOT see: total minus played minus your own hand —
    /// i.e. what the other three players still hold.
    var keyCounts: KeyCardCounts {
        var counts = KeyCardCounts()
        var seen: [Card] = engine?.state.hands[.south] ?? []
        for entry in actionLog {
            if case .play(let combo) = entry.action {
                seen += combo.cards
                if combo.kind.isBomb { counts.bombsSeen += 1 }
            }
        }
        let level = engine?.state.level
        for card in seen {
            if card.rank == .bigJoker { counts.bigJokersLeft -= 1 }
            if card.rank == .smallJoker { counts.smallJokersLeft -= 1 }
            if card.rank == level { counts.levelCardsLeft -= 1 }
        }
        return counts
    }
}
