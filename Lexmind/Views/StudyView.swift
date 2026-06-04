//
//  StudyView.swift
//  Lexmind
//

import SwiftUI
import SwiftData

struct StudyView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var words: [Word]
    @Query private var goals: [DailyGoal]

    @State private var queue: [Word] = []
    @State private var current: Word?
    @State private var revealed = false
    @State private var sessionReviewed = 0
    @State private var sessionStartedAt: Date = .now

    private let scheduler = FSRSScheduler()

    private var goal: DailyGoal {
        goals.first ?? DailyGoal()
    }

    var body: some View {
        NavigationStack {
            Group {
                if let word = current {
                    studyCard(for: word)
                } else if queue.isEmpty {
                    emptyState
                }
            }
            .navigationTitle("Çalış")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("\(sessionReviewed) tekrar")
                            .font(.caption.bold())
                        Text("\(queue.count) kaldı")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear(perform: buildQueue)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Harika iş! 🎉")
                .font(.title2.bold())
            Text(sessionReviewed > 0
                 ? "Bu oturumda \(sessionReviewed) kelime gözden geçirdin."
                 : "Şu an çalışılacak bir şey yok.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Bitir") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func studyCard(for word: Word) -> some View {
        VStack(spacing: 16) {
            progressBar

            ScrollView {
                VStack(spacing: 20) {
                    promptCard(word: word)
                    if revealed {
                        answerCard(word: word)
                    }
                }
                .padding()
            }

            controls(for: word)
        }
    }

    private var progressBar: some View {
        let total = max(queue.count + sessionReviewed, 1)
        return ProgressView(value: Double(sessionReviewed),
                            total: Double(total))
            .tint(.accentColor)
            .padding(.horizontal)
    }

    private func promptCard(word: Word) -> some View {
        VStack(spacing: 12) {
            Text(word.term)
                .font(.system(size: 44, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
            if revealed && !word.ipa.isEmpty {
                Text(word.ipa)
                    .font(.system(.title3, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    private func answerCard(word: Word) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                if !word.partOfSpeech.isEmpty {
                    badge(word.partOfSpeech, color: .blue)
                }
                if !word.countability.isEmpty,
                   word.countability.lowercased() != "n/a" {
                    badge(word.countability, color: .purple)
                }
            }

            if !word.turkishMeaning.isEmpty {
                Text(word.turkishMeaning)
                    .font(.title2.bold())
            }
            if !word.definition.isEmpty {
                Text(word.definition)
                    .foregroundStyle(.secondary)
            }

            if !word.examples.isEmpty {
                Divider().padding(.vertical, 4)
                Text("Örnekler").font(.headline)
                ForEach(Array(word.examples.enumerated()), id: \.offset) { idx, line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text(highlight(line, term: word.term))
                    }
                    .font(.callout)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private func highlight(_ text: String, term: String) -> AttributedString {
        var attr = AttributedString(text)
        if let range = text.range(of: term, options: .caseInsensitive),
           let attrRange = Range(NSRange(range, in: text), in: attr) {
            attr[attrRange].font = .callout.bold()
            attr[attrRange].foregroundColor = .accentColor
        }
        return attr
    }

    @ViewBuilder
    private func controls(for word: Word) -> some View {
        if revealed {
            HStack(spacing: 10) {
                ForEach(ReviewRating.allCases, id: \.self) { rating in
                    Button {
                        grade(word: word, rating: rating)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: rating.symbol)
                            Text(rating.label).font(.caption.bold())
                            Text(previewInterval(for: word, rating: rating))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                    .tint(color(for: rating))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        } else {
            Button {
                withAnimation(.spring) { revealed = true }
            } label: {
                Label("Cevabı Göster", systemImage: "eye")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }

    private func color(for rating: ReviewRating) -> Color {
        switch rating {
        case .again: return .red
        case .hard: return .orange
        case .good: return .green
        case .easy: return .blue
        }
    }

    private func previewInterval(for word: Word, rating: ReviewRating) -> String {
        guard let card = word.card else { return "" }
        let result = scheduler.schedule(card: card, rating: rating)
        if result.scheduledDays <= 0 {
            return previewMinutes(for: rating)
        } else if result.scheduledDays < 1 {
            return "<1g"
        } else if result.scheduledDays < 30 {
            return "\(Int(result.scheduledDays))g"
        } else if result.scheduledDays < 365 {
            return "\(Int(result.scheduledDays / 30))ay"
        } else {
            return "\(Int(result.scheduledDays / 365))y"
        }
    }

    private func previewMinutes(for rating: ReviewRating) -> String {
        switch rating {
        case .again: return "1dk"
        case .hard: return "6dk"
        case .good: return "10dk"
        case .easy: return "1g"
        }
    }

    private func grade(word: Word, rating: ReviewRating) {
        guard let card = word.card else { return }
        let result = scheduler.schedule(card: card, rating: rating)
        let log = ReviewLog(
            rating: rating,
            scheduledDays: result.scheduledDays,
            elapsedDays: result.elapsedDays,
            state: result.state
        )
        log.word = word
        word.reviewLogs.append(log)
        scheduler.apply(result: result, to: card)
        word.lastStudiedAt = result.lastReview
        sessionReviewed += 1
        try? context.save()
        advance()
    }

    private func advance() {
        revealed = false
        let finished = current
        queue.removeAll { $0 === finished }
        // Re-queue cards that are still due within the next 15 minutes (learning steps).
        if let finished, let card = finished.card,
           card.due <= Date().addingTimeInterval(15 * 60) {
            queue.append(finished)
        }
        withAnimation {
            current = queue.first
        }
    }

    private func buildQueue() {
        guard queue.isEmpty else { return }
        let reviewLimit = max(goal.reviewsPerDay, 1)

        let due = words
            .filter { ($0.card?.state ?? .new) != .new && ($0.card?.isDue ?? false) }
            .sorted { ($0.card?.due ?? .now) < ($1.card?.due ?? .now) }
            .prefix(reviewLimit)

        let news = words
            .filter { ($0.card?.state ?? .new) == .new }
            .sorted { $0.createdAt < $1.createdAt }

        queue = Array(due) + Array(news)
        sessionStartedAt = .now
        current = queue.first
    }
}

#Preview {
    StudyView()
        .modelContainer(PreviewData.container)
}
