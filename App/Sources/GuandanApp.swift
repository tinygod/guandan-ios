import SwiftUI

@main
struct GuandanApp: App {
    @State private var router = Router()
    @State private var progress = LessonProgress()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                WelcomeView()
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .lobby: LobbyView()
                        case .game(let difficulty): GameTableView(difficulty: difficulty)
                        case .learn: LearnHomeView()
                        case .lesson(let id): lessonView(id)
                        }
                    }
            }
            .environment(router)
            .environment(progress)
            .preferredColorScheme(.dark)
            .onAppear {
                // dev shortcut: `simctl launch ... -route game|lobby|learn|lesson3|lesson5`
                if let route = UserDefaults.standard.string(forKey: "route") {
                    if route == "game" { router.go(.game(.normal)) }
                    if route == "lobby" { router.go(.lobby) }
                    if route == "learn" { router.go(.learn) }
                    if route == "lesson3" { router.go(.lesson(3)) }
                    if route == "lesson5" { router.go(.lesson(5)) }
                }
                #if DEBUG
                for lesson in [LessonScripts.firstHand, LessonScripts.bombs] {
                    if let problem = ScriptRunner.validate(lesson) {
                        print("SCRIPT-INVALID [\(lesson.title)]: \(problem)")
                    } else {
                        print("SCRIPT-OK [\(lesson.title)]")
                    }
                }
                #endif
            }
        }
    }

    @ViewBuilder
    private func lessonView(_ id: Int) -> some View {
        switch id {
        case 1: WhatIsGuandanLesson()
        case 2: CombosLessonView()
        case 4: ClimbToAceLesson()
        default:
            if let script = LessonScripts.lesson(for: id) {
                ScriptedLessonView(lesson: script)
            } else {
                LearnHomeView()
            }
        }
    }
}

enum Route: Hashable {
    case lobby
    case game(BotDifficultyChoice)
    case learn
    case lesson(Int)
}

enum BotDifficultyChoice: String, Hashable, CaseIterable {
    case easy = "Easy", normal = "Normal", hard = "Hard"
}

@Observable
final class Router {
    var path = NavigationPath()

    func go(_ route: Route) { path.append(route) }
    func home() { path = NavigationPath() }
    func popOne() { if !path.isEmpty { path.removeLast() } }
}
