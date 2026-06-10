import SwiftUI
import GuandanCore

// MARK: - Script model

enum ScriptStep {
    case coach(String)                                   // text + Next
    case botPlays(Seat, [Card]?, String?)                // nil cards = pass
    case humanPlay([Card], String)                       // exact cards required
    case humanPass(String)
    case finish(String)                                  // closing message
}

struct ScriptedLesson {
    let lessonId: Int
    let title: String
    let level: Rank
    let hands: [Seat: [Card]]
    let firstLeader: Seat
    let steps: [ScriptStep]
}

// MARK: - Runner

@Observable
@MainActor
final class ScriptRunner {
    let lesson: ScriptedLesson
    private(set) var engine: GameEngine
    private(set) var stepIndex = 0
    private(set) var selection = Set<Card>()
    private(set) var done = false
    private var botTask: Task<Void, Never>?

    init(lesson: ScriptedLesson) {
        self.lesson = lesson
        engine = GameEngine(level: lesson.level, hands: lesson.hands,
                            firstLeader: lesson.firstLeader)
        runBotsIfNeeded()
    }

    var step: ScriptStep? {
        stepIndex < lesson.steps.count ? lesson.steps[stepIndex] : nil
    }

    var coachText: String {
        switch step {
        case .coach(let t), .humanPlay(_, let t), .humanPass(let t), .finish(let t):
            return t
        case .botPlays(_, _, let t):
            return t ?? ""
        case nil:
            return ""
        }
    }

    /// Cards to spotlight in the human hand.
    var highlight: Set<Card> {
        if case .humanPlay(let cards, _) = step { return Set(cards) }
        return []
    }

    var humanHand: [Card] {
        displaySorted(engine.state.hands[.south] ?? [], level: engine.state.level)
    }

    var awaitingNext: Bool {
        if case .coach = step { return true }
        if case .finish = step { return true }
        return false
    }

    var awaitingHumanPlay: Bool {
        if case .humanPlay = step { return true }
        return false
    }

    var awaitingHumanPass: Bool {
        if case .humanPass = step { return true }
        return false
    }

    var selectionMatchesRequired: Bool {
        if case .humanPlay(let cards, _) = step { return Set(cards) == selection }
        return false
    }

    func toggle(_ card: Card) {
        guard awaitingHumanPlay else { return }
        if selection.contains(card) { selection.remove(card) } else { selection.insert(card) }
    }

    func tapNext() {
        guard awaitingNext else { return }
        if case .finish = step { done = true; return }
        advance()
    }

    func tapPlay() {
        guard case .humanPlay(let cards, _) = step, selectionMatchesRequired else { return }
        let combo = Combo.detect(cards, level: engine.state.level)!
        applyChecked(.play(combo), by: .south)
        selection = []
        advance()
    }

    func tapPass() {
        guard awaitingHumanPass else { return }
        applyChecked(.pass, by: .south)
        advance()
    }

    /// Script moves must always be legal — a failure is a script bug.
    private func applyChecked(_ action: PlayerAction, by seat: Seat) {
        do { try engine.apply(action, by: seat) }
        catch { assertionFailure("script illegal move by \(seat): \(error)") }
    }

    private func advance() {
        stepIndex += 1
        runBotsIfNeeded()
    }

    /// Bot steps execute automatically with a beat of delay.
    private func runBotsIfNeeded() {
        guard case .botPlays(let seat, let cards, _) = step else { return }
        botTask?.cancel()
        botTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(900))
            guard let self, !Task.isCancelled else { return }
            guard case .botPlays = self.step else { return }
            if let cards {
                let combo = Combo.detect(cards, level: self.engine.state.level)!
                self.applyChecked(.play(combo), by: seat)
            } else {
                self.applyChecked(.pass, by: seat)
            }
            self.advance()
        }
    }

    /// Dev validation: run every action of a script straight through the
    /// engine. Returns nil when legal, else a description of the bad step.
    static func validate(_ lesson: ScriptedLesson) -> String? {
        var engine = GameEngine(level: lesson.level, hands: lesson.hands,
                                firstLeader: lesson.firstLeader)
        for (i, step) in lesson.steps.enumerated() {
            do {
                switch step {
                case .coach, .finish:
                    continue
                case .botPlays(let seat, let cards, _):
                    if let cards {
                        guard let combo = Combo.detect(cards, level: lesson.level) else {
                            return "step \(i): bot cards form no combo"
                        }
                        try engine.apply(.play(combo), by: seat)
                    } else {
                        try engine.apply(.pass, by: seat)
                    }
                case .humanPlay(let cards, _):
                    guard let combo = Combo.detect(cards, level: lesson.level) else {
                        return "step \(i): human cards form no combo"
                    }
                    try engine.apply(.play(combo), by: .south)
                case .humanPass:
                    try engine.apply(.pass, by: .south)
                }
            } catch {
                return "step \(i) (\(step)): \(error)"
            }
        }
        return nil
    }
}

// MARK: - View

struct ScriptedLessonView: View {
    @Environment(Router.self) private var router
    @Environment(LessonProgress.self) private var progress
    @State private var runner: ScriptRunner

    init(lesson: ScriptedLesson) {
        _runner = State(initialValue: ScriptRunner(lesson: lesson))
    }

    var body: some View {
        ZStack {
            Theme.background

            VStack(spacing: 0) {
                header
                Spacer(minLength: 6)
                opponents
                Spacer(minLength: 6)
                tableCenter
                Spacer(minLength: 6)
                coachBubble
                handArea
            }
            .padding(.horizontal, 12)
        }
        .navigationBarHidden(true)
        .onChange(of: runner.done) { _, isDone in
            if isDone {
                progress.markComplete(runner.lesson.lessonId)
                router.popOne()
            }
        }
    }

    private var header: some View {
        HStack {
            Button { router.popOne() } label: {
                Image(systemName: "xmark")
                    .font(.heading(14)).foregroundStyle(Theme.mint)
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.08), in: Circle())
            }
            Spacer()
            Text(runner.lesson.title)
                .font(.heading(17)).foregroundStyle(Theme.goldSoft)
            Spacer()
            Text("\(min(runner.stepIndex + 1, runner.lesson.steps.count))/\(runner.lesson.steps.count)")
                .font(.body(13)).foregroundStyle(Theme.mint)
                .frame(width: 34)
        }
        .padding(.top, 6)
    }

    private var opponents: some View {
        HStack {
            seatBadge(.west, "Marco")
            Spacer()
            seatBadge(.north, "Coach Wu").offset(y: -10)
            Spacer()
            seatBadge(.east, "Lena")
        }
        .padding(.horizontal, 8)
    }

    private func seatBadge(_ seat: Seat, _ name: String) -> some View {
        let isTurn = runner.engine.state.turn == seat
        let count = runner.engine.state.hands[seat]?.count ?? 0
        return VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(seat.team == .northSouth ? Theme.feltLight : Theme.coralDark)
                    .frame(width: 46, height: 46)
                Text(String(name.prefix(1))).font(.display(19)).foregroundStyle(.white)
                if isTurn {
                    Circle().strokeBorder(Theme.gold, lineWidth: 3)
                        .frame(width: 52, height: 52)
                }
            }
            Text(name).font(.body(11)).foregroundStyle(Theme.mint)
            Text("\(count)")
                .font(.heading(11)).foregroundStyle(.white)
                .padding(.horizontal, 7).padding(.vertical, 2)
                .background(.black.opacity(0.3), in: Capsule())
        }
    }

    private var tableCenter: some View {
        VStack(spacing: 8) {
            if let table = runner.engine.state.trick.tableCombo {
                HStack(spacing: -20) {
                    ForEach(table.cards) { card in
                        CardView(card: card, width: 44)
                    }
                }
            } else {
                Text("·  ·  ·")
                    .font(.body(15)).foregroundStyle(Theme.mint.opacity(0.5))
                    .padding(.vertical, 20)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 18))
    }

    private var coachBubble: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("🐼")
                .font(.system(size: 30))
                .padding(6)
                .background(.white.opacity(0.1), in: Circle())
            Text(runner.coachText)
                .font(.body(15))
                .foregroundStyle(Theme.ink)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.ivory, in: RoundedRectangle(cornerRadius: 14))
        }
        .padding(.vertical, 10)
        .animation(.easeInOut(duration: 0.2), value: runner.stepIndex)
    }

    private var handArea: some View {
        VStack(spacing: 10) {
            HandFanView(cards: runner.humanHand,
                        selection: runner.selection,
                        highlightedCards: runner.highlight,
                        cardWidth: 50) { runner.toggle($0) }

            Group {
                if runner.awaitingNext {
                    PrimaryButton(title: runner.stepIndex == runner.lesson.steps.count - 1
                                  ? "Finish Lesson" : "Next", icon: "arrow.right") {
                        runner.tapNext()
                    }
                } else if runner.awaitingHumanPass {
                    PrimaryButton(title: "Pass", icon: "hand.raised.fill") {
                        runner.tapPass()
                    }
                } else {
                    HStack(spacing: 12) {
                        Button {} label: {
                            Text("Pass")
                                .font(.heading(16)).foregroundStyle(.white.opacity(0.4))
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(.white.opacity(0.05),
                                            in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                        }
                        .disabled(true)

                        Button { runner.tapPlay() } label: {
                            Text("Play")
                                .font(.heading(16)).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(runner.selectionMatchesRequired
                                            ? Theme.coral : Theme.coral.opacity(0.3),
                                            in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                        }
                        .disabled(!runner.selectionMatchesRequired)
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }
}
