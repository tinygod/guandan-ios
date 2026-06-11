import SwiftUI

/// Course catalog: 4 stages × 28 courses (Teaching Guide v3).
enum Lessons {
    enum Stage: Int, CaseIterable {
        case onboarding = 1, fundamentals, control, endgame

        var title: String {
            switch self {
            case .onboarding: return "Onboarding"
            case .fundamentals: return "Fundamentals"
            case .control: return "Control & Teamwork"
            case .endgame: return "Endgame Mastery"
            }
        }
        var emoji: String {
            switch self {
            case .onboarding: return "📖"
            case .fundamentals: return "🧱"
            case .control: return "🎯"
            case .endgame: return "👑"
            }
        }
        var tagline: String {
            switch self {
            case .onboarding: return "play your first match in 30 minutes"
            case .fundamentals: return "score your hand, make zero blunders"
            case .control: return "own the tempo, feed your partner"
            case .endgame: return "win the hands that matter"
            }
        }
    }

    struct Info: Identifiable {
        let id: Int
        let title: String
        let subtitle: String
        let icon: String
        let minutes: Int
        let stage: Stage
    }

    static let all: [Info] = [
        // S1 Onboarding
        .init(id: 1, title: "What is GuanDan?", subtitle: "Teams, decks and the race to Ace",
              icon: "person.2.fill", minutes: 1, stage: .onboarding),
        .init(id: 2, title: "Card Combos", subtitle: "Every shape you can play",
              icon: "square.stack.fill", minutes: 2, stage: .onboarding),
        .init(id: 3, title: "Your First Hand", subtitle: "Guided play — win a real trick",
              icon: "hand.draw.fill", minutes: 2, stage: .onboarding),
        .init(id: 4, title: "Follow or Pass", subtitle: "Beating is optional — passing is a weapon",
              icon: "arrow.uturn.left", minutes: 2, stage: .onboarding),
        .init(id: 5, title: "Climb to Ace", subtitle: "Levels, wildcards, winning the match",
              icon: "chart.line.uptrend.xyaxis", minutes: 1, stage: .onboarding),
        .init(id: 6, title: "Tribute Basics", subtitle: "The loser pays — and sometimes refuses",
              icon: "gift.fill", minutes: 1, stage: .onboarding),
        // S2 Fundamentals
        .init(id: 7, title: "Hand Scoring", subtitle: "Rate your 27 cards like a pro",
              icon: "number.circle.fill", minutes: 2, stage: .fundamentals),
        .init(id: 8, title: "Hand Planning", subtitle: "Split your hand the right way",
              icon: "square.grid.3x1.below.line.grid.1x2", minutes: 2, stage: .fundamentals),
        .init(id: 9, title: "The Tail Card", subtitle: "Park your smallest card LAST",
              icon: "arrow.left.to.line", minutes: 2, stage: .fundamentals),
        .init(id: 10, title: "Partner Discipline", subtitle: "Feed your partner, never fight them",
              icon: "heart.fill", minutes: 2, stage: .fundamentals),
        .init(id: 11, title: "Catching the Wind", subtitle: "The free lead and how to earn it",
              icon: "wind", minutes: 1, stage: .fundamentals),
        .init(id: 12, title: "Bomb Value", subtitle: "Break the rules, win the trick",
              icon: "flame.fill", minutes: 2, stage: .fundamentals),
        .init(id: 13, title: "Wildcard Basics", subtitle: "Squeeze your ♥ level cards",
              icon: "sparkles", minutes: 2, stage: .fundamentals),
        // S3 Control & Teamwork (P1)
        .init(id: 14, title: "Roles & Signals", subtitle: "Striker or support? Decide in one trick",
              icon: "antenna.radiowaves.left.and.right", minutes: 2, stage: .control),
        .init(id: 15, title: "Opening Leads", subtitle: "Lead strength — or hide it",
              icon: "play.circle.fill", minutes: 2, stage: .control),
        .init(id: 16, title: "Feeding Your Partner", subtitle: "Deliver exactly what they need",
              icon: "arrow.right.arrow.left", minutes: 2, stage: .control),
        .init(id: 17, title: "Taming the Upstream", subtitle: "Never bomb a four — except when you must",
              icon: "arrow.up.circle.fill", minutes: 3, stage: .control),
        .init(id: 18, title: "Blocking Downstream", subtitle: "Cap to the top, answer fire with fire",
              icon: "hand.raised.fill", minutes: 3, stage: .control),
        .init(id: 19, title: "Tribute Craft", subtitle: "Half of all returns build a bomb",
              icon: "gift.circle.fill", minutes: 2, stage: .control),
        .init(id: 20, title: "Counting & New Tops", subtitle: "When your Ace becomes a king",
              icon: "brain.head.profile", minutes: 2, stage: .control),
        .init(id: 21, title: "Soft Power", subtitle: "Win without showing your strength",
              icon: "wand.and.stars", minutes: 2, stage: .control),
        // S4 Endgame Mastery (P2)
        .init(id: 22, title: "Four Ways to First", subtitle: "Bomb, charge, listen or ambush",
              icon: "flag.checkered", minutes: 2, stage: .endgame),
        .init(id: 23, title: "Forcing the Bomb", subtitle: "Make them burn their fire",
              icon: "burst.fill", minutes: 3, stage: .endgame),
        .init(id: 24, title: "Co-Defense", subtitle: "Cover the lanes your partner can't",
              icon: "shield.lefthalf.filled", minutes: 2, stage: .endgame),
        .init(id: 25, title: "Tenpai Tricks", subtitle: "Fake a pair, freeze the table",
              icon: "theatermasks.fill", minutes: 2, stage: .endgame),
        .init(id: 26, title: "Patience", subtitle: "Big bomb? Sit still and wait",
              icon: "hourglass", minutes: 2, stage: .endgame),
        .init(id: 27, title: "Reading Opponents", subtitle: "Controllers vs chargers",
              icon: "eye.fill", minutes: 2, stage: .endgame),
        .init(id: 28, title: "How to Review", subtitle: "Three key moves, one takeaway",
              icon: "magnifyingglass", minutes: 1, stage: .endgame),
        .init(id: 29, title: "AI Lab Secrets", subtitle: "Five iron rules from 10,000 games",
              icon: "flask.fill", minutes: 3, stage: .endgame),
    ]

    static func info(_ id: Int) -> Info? { all.first { $0.id == id } }

    static func inStage(_ stage: Stage) -> [Info] {
        all.filter { $0.stage == stage }
    }
}

@Observable
final class LessonProgress {
    private static let key = "completedLessonsV3"

    private(set) var completed: Set<Int>

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.key) ?? ""
        completed = Set(raw.split(separator: ",").compactMap { Int($0) })
    }

    func markComplete(_ id: Int) {
        completed.insert(id)
        UserDefaults.standard.set(completed.sorted().map(String.init).joined(separator: ","),
                                  forKey: Self.key)
    }

    func isStageUnlocked(_ stage: Lessons.Stage) -> Bool {
        guard let prev = Lessons.Stage(rawValue: stage.rawValue - 1) else { return true }
        return Lessons.inStage(prev).allSatisfy { completed.contains($0.id) }
    }

    var nextLesson: Lessons.Info? {
        Lessons.all.first { !completed.contains($0.id) && isStageUnlocked($0.stage) }
    }

    var fractionComplete: Double {
        Double(completed.count) / Double(Lessons.all.count)
    }

    func fraction(of stage: Lessons.Stage) -> Double {
        let lessons = Lessons.inStage(stage)
        let done = lessons.filter { completed.contains($0.id) }.count
        return Double(done) / Double(lessons.count)
    }
}
