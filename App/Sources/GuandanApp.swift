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
                // dev shortcut: `simctl launch ... -route game|lobby|learn|lesson<N>`
                if let route = UserDefaults.standard.string(forKey: "route") {
                    if route == "game" { router.go(.game(.normal)) }
                    if route == "lobby" { router.go(.lobby) }
                    if route == "learn" { router.go(.learn) }
                    if route.hasPrefix("lesson"), let id = Int(route.dropFirst(6)) {
                        router.go(.lesson(id))
                    }
                }
                #if DEBUG
                for lesson in LessonScripts.allScripted {
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
        case 5: ClimbToAceLesson()
        case 6: TributeBasicsLesson()
        case 7: HandScoringLesson()
        case 8: HandPlanningLesson()
        case 11: CatchingWindLesson()
        case 13: WildcardMasteryLesson()
        case 14: RolesSignalsLesson()
        case 15: OpeningLeadsLesson()
        case 17: UpstreamLesson()
        case 18: DownstreamLesson()
        case 19: TributeCraftLesson()
        case 20: CardCountingLesson()
        case 21: SoftPowerLesson()
        case 24: CoDefenseLesson()
        case 25: TenpaiLesson()
        case 26: BombTimingLesson()
        case 27: ReadingOpponentsLesson()
        case 28: HowToReviewLesson()
        case 29: AILabLesson()
        default:
            if let script = LessonScripts.lesson(for: id) {
                ScriptedLessonView(lesson: script)
            } else if let info = Lessons.info(id) {
                ComingSoonLesson(info: info)
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
