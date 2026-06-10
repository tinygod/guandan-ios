import SwiftUI

/// Mirror of the Stitch "Game Lobby" screen (v1: practice modes live,
/// online modes shown as Coming Soon).
struct LobbyView: View {
    @Environment(Router.self) private var router
    @Environment(LessonProgress.self) private var progress
    @State private var comingSoonShown = false

    var body: some View {
        ZStack {
            Theme.background

            ScrollView {
                VStack(spacing: 16) {
                    header
                        .frame(maxWidth: 760)

                    Button { router.go(.learn) } label: {
                        PanelCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Label("Continue Learning", systemImage: "graduationcap.fill")
                                        .font(.heading(18))
                                        .foregroundStyle(Theme.goldSoft)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(Theme.mint)
                                }
                                if let next = progress.nextLesson {
                                    Text("Next: Lesson \(next.id) · \(next.title)")
                                        .font(.body(14)).foregroundStyle(Theme.mint)
                                } else {
                                    Text("All 5 lessons complete 🎓")
                                        .font(.body(14)).foregroundStyle(Theme.mint)
                                }
                                ProgressView(value: progress.fractionComplete)
                                    .tint(Theme.gold)
                            }
                        }
                    }
                    .frame(maxWidth: 760)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                        GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        modeButton("Practice vs Bots", icon: "cpu.fill",
                                   subtitle: "Easy bots — review every hand after") {
                            router.go(.game(.easy))
                        }
                        modeButton("Standard Match", icon: "bolt.fill",
                                   subtitle: "Normal bots, full rules") {
                            router.go(.game(.normal))
                        }
                        modeButton("Expert Table", icon: "flame.fill",
                                   subtitle: "Hard bots protect their bombs") {
                            router.go(.game(.hard))
                        }
                        modeButton("Quick Match", icon: "person.2.fill",
                                   subtitle: "Online — coming soon", dimmed: true) {
                            comingSoonShown = true
                        }
                    }
                    .frame(maxWidth: 760)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarHidden(true)
        .alert("Coming Soon", isPresented: $comingSoonShown) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Online play is on the roadmap. Practice vs bots for now!")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Game Lobby").font(.display(30)).foregroundStyle(.white)
                Text("Pick a table").font(.body(15)).foregroundStyle(Theme.mint)
            }
            Spacer()
            Image(systemName: "suit.spade.fill")
                .font(.system(size: 28))
                .foregroundStyle(Theme.goldSoft)
        }
        .padding(.top, 8)
    }

    private func modeButton(_ title: String, icon: String, subtitle: String,
                            dimmed: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(dimmed ? Theme.mint : Theme.coral)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.08), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.heading(17)).foregroundStyle(.white)
                    Text(subtitle).font(.body(13)).foregroundStyle(Theme.mint)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.mint)
            }
            .padding(16)
            .background(.white.opacity(dimmed ? 0.04 : 0.07),
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .strokeBorder(.white.opacity(0.1)))
            .opacity(dimmed ? 0.7 : 1)
        }
    }
}
