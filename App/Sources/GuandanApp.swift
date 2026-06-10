import SwiftUI

@main
struct GuandanApp: App {
    @State private var router = Router()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                WelcomeView()
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .lobby: LobbyView()
                        case .game(let difficulty): GameTableView(difficulty: difficulty)
                        }
                    }
            }
            .environment(router)
            .preferredColorScheme(.dark)
            .onAppear {
                // dev shortcut: `simctl launch ... -route game|lobby`
                if let route = UserDefaults.standard.string(forKey: "route") {
                    if route == "game" { router.go(.game(.normal)) }
                    if route == "lobby" { router.go(.lobby) }
                }
            }
        }
    }
}

enum Route: Hashable {
    case lobby
    case game(BotDifficultyChoice)
}

enum BotDifficultyChoice: String, Hashable, CaseIterable {
    case easy = "Easy", normal = "Normal", hard = "Hard"
}

@Observable
final class Router {
    var path = NavigationPath()

    func go(_ route: Route) { path.append(route) }
    func home() { path = NavigationPath() }
}
