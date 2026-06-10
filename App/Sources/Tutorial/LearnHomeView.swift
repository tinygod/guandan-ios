import SwiftUI

/// The app's home: learning journey (Basics + Techniques) with the Practice
/// Arena attached. Landscape: two-column course grid.
struct LearnHomeView: View {
    @Environment(Router.self) private var router
    @Environment(LessonProgress.self) private var progress

    private let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

    @State private var lockedAlert = false

    var body: some View {
        ZStack {
            Theme.background

            ScrollView {
                VStack(spacing: 18) {
                    header

                    ForEach(Lessons.Stage.allCases, id: \.self) { stage in
                        stageView(stage)
                    }

                    arenaCard
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .frame(maxWidth: 860)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert("Stage locked", isPresented: $lockedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Finish every course in the previous stage to unlock this one.")
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("GuanDan Academy").font(.display(28)).foregroundStyle(.white)
            HStack(spacing: 10) {
                ProgressView(value: progress.fractionComplete)
                    .tint(Theme.gold)
                    .frame(width: 220)
                Text("\(progress.completed.count)/\(Lessons.all.count)")
                    .font(.body(13)).foregroundStyle(Theme.mint)
            }
        }
    }

    private func stageView(_ stage: Lessons.Stage) -> some View {
        let unlocked = progress.isStageUnlocked(stage)
        let stageDone = progress.fraction(of: stage) >= 1.0
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("\(stage.emoji) Stage \(stage.rawValue) · \(stage.title)")
                    .font(.heading(18))
                    .foregroundStyle(unlocked ? Theme.goldSoft : Theme.mint.opacity(0.6))
                if stageDone {
                    Text("🏅").font(.system(size: 16))
                } else if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13)).foregroundStyle(Theme.mint.opacity(0.6))
                }
                Text(stage.tagline).font(.body(13)).foregroundStyle(Theme.mint.opacity(0.8))
                Spacer()
                ProgressView(value: progress.fraction(of: stage))
                    .tint(Theme.gold).frame(width: 80)
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Lessons.inStage(stage)) { lesson in
                    lessonCard(lesson, unlocked: unlocked)
                }
            }
        }
    }

    private func lessonCard(_ lesson: Lessons.Info, unlocked: Bool) -> some View {
        let done = progress.completed.contains(lesson.id)
        return Button {
            if unlocked { router.go(.lesson(lesson.id)) } else { lockedAlert = true }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(done ? Theme.gold.opacity(0.25) : .white.opacity(0.08))
                        .frame(width: 42, height: 42)
                    Image(systemName: done ? "checkmark" : (unlocked ? lesson.icon : "lock.fill"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(done ? Theme.goldSoft
                                         : (unlocked ? Theme.coral : Theme.mint.opacity(0.5)))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(lesson.id) · \(lesson.title)")
                        .font(.heading(15)).foregroundStyle(.white.opacity(unlocked ? 1 : 0.55))
                        .lineLimit(1)
                    Text(lesson.subtitle).font(.body(12))
                        .foregroundStyle(Theme.mint.opacity(unlocked ? 1 : 0.55))
                        .lineLimit(1)
                }
                Spacer()
                Text("\(lesson.minutes)m")
                    .font(.body(11)).foregroundStyle(Theme.mint.opacity(0.8))
            }
            .padding(12)
            .background(.white.opacity(unlocked ? 0.07 : 0.04),
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .strokeBorder(done ? Theme.gold.opacity(0.4) : .white.opacity(0.1)))
        }
    }

    private var arenaCard: some View {
        Button { router.go(.lobby) } label: {
            HStack(spacing: 14) {
                Image(systemName: "flag.2.crossed.fill")
                    .font(.system(size: 24)).foregroundStyle(Theme.ink)
                    .frame(width: 48, height: 48)
                    .background(Theme.gold, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("Practice Arena").font(.heading(17)).foregroundStyle(.white)
                    Text("Apply your lessons vs AI — every hand can be reviewed move-by-move with the coach")
                        .font(.body(13)).foregroundStyle(Theme.mint)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.mint)
            }
            .padding(16)
            .background(Theme.gold.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .strokeBorder(Theme.gold.opacity(0.4)))
        }
    }
}
