import SwiftUI

/// Learning journey home — mirrors the lesson-list portions of the Stitch
/// "My Journey" design.
struct LearnHomeView: View {
    @Environment(Router.self) private var router
    @Environment(LessonProgress.self) private var progress

    var body: some View {
        ZStack {
            Theme.background

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Text("Learn GuanDan").font(.display(30)).foregroundStyle(.white)
                        Text("5 short lessons — then you're table-ready")
                            .font(.body(14)).foregroundStyle(Theme.mint)

                        ProgressView(value: progress.fractionComplete)
                            .tint(Theme.gold)
                            .padding(.top, 8)
                        Text("\(progress.completed.count) of \(Lessons.all.count) complete")
                            .font(.body(12)).foregroundStyle(Theme.mint)
                    }
                    .padding(.top, 8)

                    ForEach(Lessons.all) { lesson in
                        lessonRow(lesson)
                    }

                    if progress.completed.count == Lessons.all.count {
                        PrimaryButton(title: "Graduate — play a real match", icon: "checkmark.seal.fill") {
                            router.go(.game(.easy))
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private func lessonRow(_ lesson: Lessons.Info) -> some View {
        let done = progress.completed.contains(lesson.id)
        return Button {
            router.go(.lesson(lesson.id))
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(done ? Theme.gold.opacity(0.25) : .white.opacity(0.08))
                        .frame(width: 46, height: 46)
                    Image(systemName: done ? "checkmark" : lesson.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(done ? Theme.goldSoft : Theme.coral)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lesson \(lesson.id) · \(lesson.title)")
                        .font(.heading(16)).foregroundStyle(.white)
                    Text(lesson.subtitle).font(.body(13)).foregroundStyle(Theme.mint)
                }
                Spacer()
                Text("\(lesson.minutes) min")
                    .font(.body(12)).foregroundStyle(Theme.mint.opacity(0.8))
            }
            .padding(14)
            .background(.white.opacity(0.07),
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .strokeBorder(done ? Theme.gold.opacity(0.4) : .white.opacity(0.1)))
        }
    }
}
