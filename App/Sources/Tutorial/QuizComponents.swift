import SwiftUI
import GuandanCore

/// Reusable scenario quiz: explainer pages first (optional), then questions.
struct QuizQuestion {
    let prompt: String
    var cards: [Card] = []           // optional cards to display
    let options: [String]
    let correct: Int
    let explanation: String
}

struct QuizLessonView: View {
    let lessonId: Int
    let title: String
    let intro: [AnyView]             // explainer pages shown before the quiz
    let questions: [QuizQuestion]

    @Environment(Router.self) private var router
    @Environment(LessonProgress.self) private var progress
    @State private var page = 0      // 0..<intro.count = intro; then questions
    @State private var picked: Int?

    private var questionIndex: Int { page - intro.count }
    private var inQuiz: Bool { questionIndex >= 0 }

    var body: some View {
        ZStack {
            Theme.background
            VStack(spacing: 10) {
                Text(tr(title)).font(.heading(17)).foregroundStyle(Theme.goldSoft)
                    .padding(.top, 10)

                if inQuiz {
                    quiz(questions[questionIndex])
                } else {
                    intro[page]
                        .frame(maxHeight: .infinity)
                    PrimaryButton(title: "Next", icon: "arrow.right") {
                        withAnimation { page += 1 }
                    }
                    .frame(maxWidth: 320)
                    .padding(.bottom, 14)
                }
            }
            .padding(.horizontal, 24)
        }
        .navigationBarHidden(true)
    }

    private func quiz(_ q: QuizQuestion) -> some View {
        VStack(spacing: 10) {
            Text("Question \(questionIndex + 1) of \(questions.count)")
                .font(.body(12)).foregroundStyle(Theme.mint)
            Text(tr(q.prompt))
                .font(.heading(16)).foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 640)

            if !q.cards.isEmpty {
                HStack(spacing: -14) {
                    ForEach(q.cards) { card in CardView(card: card, width: 44) }
                }
            }

            VStack(spacing: 8) {
                ForEach(q.options.indices, id: \.self) { i in
                    Button {
                        guard picked == nil else { return }
                        picked = i
                    } label: {
                        Text(tr(q.options[i]))
                            .font(.body(14))
                            .foregroundStyle(optionFG(i, q))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(optionBG(i, q), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .frame(maxWidth: 560)

            if picked != nil {
                HStack(alignment: .top, spacing: 6) {
                    Text("🐼")
                    Text((picked == q.correct ? tr("Right! ") : tr("Not quite. ")) + tr(q.explanation))
                        .font(.body(13)).foregroundStyle(Theme.ink)
                        .padding(10)
                        .background(Theme.ivory, in: RoundedRectangle(cornerRadius: 12))
                }
                .frame(maxWidth: 560)

                PrimaryButton(title: questionIndex == questions.count - 1
                              ? "Finish Lesson" : "Next Question", icon: "arrow.right") {
                    if questionIndex == questions.count - 1 {
                        progress.markComplete(lessonId)
                        router.popOne()
                    } else {
                        withAnimation { page += 1; picked = nil }
                    }
                }
                .frame(maxWidth: 320)
            }
            Spacer(minLength: 4)
        }
    }

    private func optionFG(_ i: Int, _ q: QuizQuestion) -> Color {
        guard picked != nil else { return .white }
        return i == q.correct ? Theme.ink : .white.opacity(0.5)
    }

    private func optionBG(_ i: Int, _ q: QuizQuestion) -> Color {
        guard picked != nil else { return .white.opacity(0.08) }
        if i == q.correct { return Theme.gold }
        if i == picked { return Theme.coralDark.opacity(0.6) }
        return .white.opacity(0.04)
    }
}
