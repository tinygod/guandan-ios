import SwiftUI

/// Lesson metadata + completion persistence (UserDefaults).
enum Lessons {
    struct Info: Identifiable {
        let id: Int
        let title: String
        let subtitle: String
        let icon: String
        let minutes: Int
    }

    static let all: [Info] = [
        .init(id: 1, title: "What is GuanDan?", subtitle: "Teams, decks and the race to Ace",
              icon: "person.2.fill", minutes: 1),
        .init(id: 2, title: "Card Combos", subtitle: "Every shape you can play",
              icon: "square.stack.fill", minutes: 2),
        .init(id: 3, title: "Your First Hand", subtitle: "Guided play — win a real trick",
              icon: "hand.draw.fill", minutes: 2),
        .init(id: 4, title: "Climb to Ace", subtitle: "Levels, wildcards and tribute",
              icon: "chart.line.uptrend.xyaxis", minutes: 1),
        .init(id: 5, title: "Bombs!", subtitle: "Break the rules, win the trick",
              icon: "flame.fill", minutes: 2),
    ]
}

@Observable
final class LessonProgress {
    private static let key = "completedLessons"

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

    var nextLesson: Lessons.Info? {
        Lessons.all.first { !completed.contains($0.id) }
    }

    var fractionComplete: Double {
        Double(completed.count) / Double(Lessons.all.count)
    }
}
