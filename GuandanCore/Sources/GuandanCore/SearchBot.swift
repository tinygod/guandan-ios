import Foundation

/// Determinized Monte-Carlo search bot: for each candidate move, imagine the
/// hidden hands N different ways, roll each world out to the end of the hand
/// with a fast policy, and pick the move with the best average team result.
/// This gives the AI what pure heuristics never have — multi-trick planning.
public struct SearchBot: Bot {
    public let rollouts: Int
    private let advisor = HeuristicBot(difficulty: .hard)
    /// Rollout quality is the soul of the search: weak rollouts evaluate
    /// noise. Full heuristics are affordable after the Card.id speedup.
    private let rolloutPolicy = HeuristicBot(difficulty: .normal)

    public init(rollouts: Int = 8) {
        self.rollouts = rollouts
    }

    public func decide(engine: GameEngine, seat: Seat,
                       rng: inout SeededGenerator) -> PlayerAction {
        let state = engine.state
        let hand = state.hands[seat] ?? []
        let combos = engine.legalCombos(for: seat)

        // trivial cases
        if combos.isEmpty { return .pass }
        if let out = combos.first(where: { $0.cards.count == hand.count }) {
            return .play(out)
        }

        // HYBRID: heuristics carry the midgame; search takes over where
        // lookahead actually decides hands — the endgame. Short endgame
        // rollouts are cheap, so we afford many more of them.
        let oppShort = Seat.allCases.contains {
            $0.team != seat.team && state.isActive($0)
                && (state.hands[$0]?.count ?? 99) <= 6
        }
        let endgame = hand.count <= 12 || oppShort
        if !endgame {
            return advisor.decide(engine: engine, seat: seat, rng: &rng)
        }

        // ---- candidate shortlist (cap the branching factor) ----
        var candidates: [PlayerAction] = []
        if engine.mayPass { candidates.append(.pass) }
        var seenKinds = Set<String>()
        var plays: [Combo] = []
        for combo in combos {        // weakest-first
            let key = "\(combo.kind)-\(combo.rankValue)"
            if seenKinds.insert(key).inserted { plays.append(combo) }
        }
        var shortlist = Array(plays.prefix(3))
        if let strongestNonBomb = plays.last(where: { !$0.kind.isBomb }),
           !shortlist.contains(where: { $0.cards == strongestNonBomb.cards }) {
            shortlist.append(strongestNonBomb)
        }
        if let bomb = plays.first(where: { $0.kind.isBomb }),
           !shortlist.contains(where: { $0.cards == bomb.cards }) {
            shortlist.append(bomb)
        }
        candidates += shortlist.map { .play($0) }
        // always consider what the heuristic master would do
        let advice = advisor.decide(engine: engine, seat: seat, rng: &rng)
        if !candidates.contains(where: { sameAction($0, advice) }) {
            candidates.append(advice)
        }
        if candidates.count == 1 { return candidates[0] }

        // ---- evaluate every candidate on the SAME set of imagined worlds
        // (common random numbers — without this, world luck drowns out move
        // quality and the argmax degenerates to noise) ----
        // endgame worlds are short — triple the sample size for free
        let worldCount = rollouts * 3
        var worlds: [HandState] = []
        for _ in 0..<worldCount {
            let worldHands = determinize(state, me: seat, rng: &rng)
            var world = HandState(level: state.level, hands: worldHands,
                                  turn: state.turn)
            world.finished = state.finished
            world.trick = state.trick
            world.passedSinceLastPlay = state.passedSinceLastPlay
            world.played = state.played
            worlds.append(world)
        }

        var best = advice
        var bestScore = -Double.infinity
        for candidate in candidates {
            var total = 0.0
            for world in worlds {
                var sim = GameEngine(resuming: world)
                guard (try? sim.apply(candidate, by: seat)) != nil else {
                    total -= 10; continue
                }
                // identical rollout randomness per world across candidates
                var rolloutRng = SeededGenerator(seed: 0xC0FFEE)
                total += rollout(&sim, myTeam: seat.team, rng: &rolloutRng)
            }
            let avg = total / Double(worldCount)
            if avg > bestScore {
                bestScore = avg
                best = candidate
            }
        }
        return best
    }

    private func sameAction(_ a: PlayerAction, _ b: PlayerAction) -> Bool {
        switch (a, b) {
        case (.pass, .pass): return true
        case (.play(let x), .play(let y)): return Set(x.cards) == Set(y.cards)
        default: return false
        }
    }

    /// Deal every card we cannot see randomly to the other three seats.
    private func determinize(_ state: HandState, me: Seat,
                             rng: inout SeededGenerator) -> [Seat: [Card]] {
        let visible = Set((state.played + (state.hands[me] ?? [])).map(\.id))
        var unseen = Deck.standard().filter { !visible.contains($0.id) }
        unseen.shuffle(using: &rng)
        var hands: [Seat: [Card]] = [me: state.hands[me] ?? []]
        var index = 0
        for seat in Seat.allCases where seat != me {
            let n = state.hands[seat]?.count ?? 0
            hands[seat] = Array(unseen[index..<(index + n)])
            index += n
        }
        return hands
    }

    /// Fast rollout to the end of the hand; returns the team result on the
    /// classic +3…−3 scale (Danzero reward shaping).
    private func rollout(_ sim: inout GameEngine, myTeam: Team,
                         rng: inout SeededGenerator) -> Double {
        var steps = 0
        while !sim.state.isOver && steps < 400 {
            steps += 1
            let seat = sim.state.turn
            let action = rolloutPolicy.decide(engine: sim, seat: seat, rng: &rng)
            guard (try? sim.apply(action, by: seat)) != nil else { break }
        }
        guard sim.state.isOver else { return 0 }
        let order = sim.state.finishOrder
        let winner = order[0].team
        let partnerIndex = order.firstIndex(of: order[0].partner) ?? 3
        let delta = [0, 3, 2, 1][partnerIndex]
        return winner == myTeam ? Double(delta) : -Double(delta)
    }

    /// Cheap-but-sane policy for rollouts: exit when possible, respect the
    /// partner, otherwise cheapest answer; lead the weakest combo.
    private func fastPolicy(_ engine: GameEngine, seat: Seat) -> PlayerAction {
        let state = engine.state
        let combos = engine.legalCombos(for: seat)
        guard !combos.isEmpty else { return .pass }
        let hand = state.hands[seat] ?? []
        if let out = combos.first(where: { $0.cards.count == hand.count }) {
            return .play(out)
        }
        if let owner = state.trick.tableOwner, owner == seat.partner,
           let table = state.trick.tableCombo,
           table.rankValue >= 11 || table.kind.isBomb {
            return .pass
        }
        // avoid burning wildcards/bombs casually even in rollouts
        let level = state.level
        if let cheap = combos.first(where: { combo in
            !combo.kind.isBomb && !combo.cards.contains { $0.isWildcard(level: level) }
        }) {
            return .play(cheap)
        }
        return engine.mayPass ? .pass : .play(combos[0])
    }
}
