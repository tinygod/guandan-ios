import SwiftUI

/// Course catalog + completion persistence (UserDefaults).
enum Lessons {
    enum Section: String, CaseIterable {
        case basics = "Basics"
        case techniques = "Techniques"
    }

    struct Info: Identifiable {
        let id: Int
        let title: String
        let subtitle: String
        let icon: String
        let minutes: Int
        let section: Section
    }

    static let all: [Info] = [
        // Basics — get table-ready
        .init(id: 1, title: "What is GuanDan?", subtitle: "Teams, decks and the race to Ace",
              icon: "person.2.fill", minutes: 1, section: .basics),
        .init(id: 2, title: "Card Combos", subtitle: "Every shape you can play",
              icon: "square.stack.fill", minutes: 2, section: .basics),
        .init(id: 3, title: "Your First Hand", subtitle: "Guided play — win a real trick",
              icon: "hand.draw.fill", minutes: 2, section: .basics),
        .init(id: 4, title: "Climb to Ace", subtitle: "Levels, wildcards and tribute",
              icon: "chart.line.uptrend.xyaxis", minutes: 1, section: .basics),
        .init(id: 5, title: "Bombs!", subtitle: "Break the rules, win the trick",
              icon: "flame.fill", minutes: 2, section: .basics),
        // Techniques — play well
        .init(id: 6, title: "Partner Play", subtitle: "Feed your partner, never fight them",
              icon: "heart.fill", minutes: 2, section: .techniques),
        .init(id: 7, title: "Wildcard Mastery", subtitle: "Squeeze the most from your ♥ level cards",
              icon: "sparkles", minutes: 2, section: .techniques),
        .init(id: 8, title: "Bomb Timing", subtitle: "A bomb saved is a bomb earned",
              icon: "clock.fill", minutes: 2, section: .techniques),
        .init(id: 9, title: "Card Counting", subtitle: "Track what's gone, know what's left",
              icon: "brain.head.profile", minutes: 2, section: .techniques),
        .init(id: 10, title: "Endgame Lines", subtitle: "Sequence your exit perfectly",
              icon: "flag.checkered", minutes: 2, section: .techniques),
    ]

    static func info(_ id: Int) -> Info? { all.first { $0.id == id } }

    static func inSection(_ section: Section) -> [Info] {
        all.filter { $0.section == section }
    }
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

    func fraction(of section: Lessons.Section) -> Double {
        let lessons = Lessons.inSection(section)
        let done = lessons.filter { completed.contains($0.id) }.count
        return Double(done) / Double(lessons.count)
    }
}
