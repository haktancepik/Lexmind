//
//  StudyView.swift
//  Lexmind
//

import SwiftUI
import SwiftData

struct StudyView: View {
    var onRequestReading: (() -> Void)? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var words: [Word]
    @Query private var goals: [DailyGoal]

    @State private var queue: [Word] = []
    @State private var current: Word?
    @State private var revealed = false
    @State private var sessionReviewed = 0
    @State private var sessionStartedAt: Date = .now

    @State private var analyzer = WordAnalyzer()
    @State private var verifier = RelationVerifier()
    @State private var lookup: QuickLookupService?
    @State private var activePopoverTerm: String?
    @State private var isAddingFromPopover = false
    @State private var recentlyAddedTerm: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var popoverError: String?
    @State private var existingTerms: Set<String> = []

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
            .onAppear {
                buildQueue()
                if lookup == nil {
                    lookup = QuickLookupService(analyzer: analyzer)
                }
            }
            .task {
                async let common: Void = CommonWordsLibrary.preload()
                async let oxford: Void = OxfordWordsLibrary.preload()
                _ = await common
                _ = await oxford
            }
            .task(id: words.count) {
                existingTerms = Set(words.map { $0.term })
            }
            .overlay(alignment: .top) { addedToast }
            .popover(
                item: Binding(
                    get: { activePopoverTerm.map(StudyLookupTerm.init) },
                    set: { activePopoverTerm = $0?.value }
                ),
                attachmentAnchor: .point(.top),
                arrowEdge: .top
            ) { wrapper in
                lookupCard(for: wrapper.value)
                    .presentationCompactAdaptation(.popover)
            }
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

            if sessionReviewed > 0, onRequestReading != nil {
                Button {
                    let action = onRequestReading
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        action?()
                    }
                } label: {
                    Label("Okuma Metni Oluştur", systemImage: "book.pages")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

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
        .task(id: word.term) {
            await enrichFamilyIfNeeded(for: word)
        }
    }

    private func enrichFamilyIfNeeded(for word: Word) async {
        guard analyzer.isAvailable else { return }
        let needsFamily = word.familyRoot == nil
            && word.familyMembers.isEmpty
            && word.relations.isEmpty
        guard needsFamily else { return }
        do {
            let result = try await analyzer.analyze(term: word.term)
            try Task.checkCancellation()
            word.familyRoot = result.familyRoot.isEmpty ? nil : result.familyRoot.lowercased()
            word.familyMembers = result.familyMembers.map { $0.lowercased() }
            word.inflectionExamples = result.inflectionExamples
            await verifier.applyVerifiedRelations(to: word, from: result)
            try? context.save()
        } catch {
            // Silent — bir sonraki kart açılışında tekrar denenir.
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
                tappable(text: word.definition, baseUIColor: .secondaryLabel)
            }

            if !word.examples.isEmpty {
                Divider().padding(.vertical, 4)
                Text("Örnekler").font(.headline)
                ForEach(Array(word.examples.enumerated()), id: \.offset) { idx, line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        tappable(text: line,
                                 highlightedTerm: word.term.lowercased(),
                                 baseUIColor: .label)
                    }
                    .font(.callout)
                }
            }

            if !word.inflectionExamples.isEmpty {
                Divider().padding(.vertical, 4)
                Text("Çekim Örnekleri").font(.headline)
                ForEach(Array(word.inflectionExamples.enumerated()), id: \.offset) { idx, line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        tappable(text: line,
                                 highlightedTerm: word.familyRoot?.lowercased() ?? word.term.lowercased(),
                                 baseUIColor: .label)
                    }
                    .font(.callout)
                }
            }

            familySection(word: word)
            relationsSection(word: word)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    @ViewBuilder
    private func familySection(word: Word) -> some View {
        let hasRoot = (word.familyRoot?.isEmpty == false)
        let hasMembers = !word.familyMembers.isEmpty
        if hasRoot || hasMembers {
            Divider().padding(.vertical, 4)
            Text("Kelime Ailesi").font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                if let root = word.familyRoot, !root.isEmpty {
                    HStack(spacing: 6) {
                        Text("Kök:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            handleTokenTap(root)
                        } label: {
                            Text(root)
                                .font(.caption.bold())
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.15), in: Capsule())
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if hasMembers {
                    let verifiedSet = Set(word.familyMembersVerifiedRaw)
                    relationChipsRow(items: word.familyMembers.map {
                        (term: $0,
                         origin: verifiedSet.contains($0.lowercased()) ? RelationSource.verified : .ai)
                    })
                }
            }
        }
    }

    @ViewBuilder
    private func relationsSection(word: Word) -> some View {
        if !word.relations.isEmpty {
            Divider().padding(.vertical, 4)
            Text("Kelime Ağı").font(.headline)
            let grouped = Dictionary(grouping: word.relations, by: { $0.kind })
            VStack(alignment: .leading, spacing: 10) {
                ForEach(RelationKind.allCases) { kind in
                    if let items = grouped[kind], !items.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(kind.label, systemImage: kind.symbol)
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            relationChipsRow(items: sortedItems(items))
                        }
                    }
                }
            }
        }
    }

    private func sortedItems(_ relations: [WordRelation]) -> [(term: String, origin: RelationSource)] {
        relations
            .map { (term: $0.targetTerm, origin: $0.origin) }
            .sorted { ($0.origin == .verified ? 0 : 1) < ($1.origin == .verified ? 0 : 1) }
    }

    private func relationChipsRow(items: [(term: String, origin: RelationSource)]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items, id: \.term) { item in
                    Button {
                        handleTokenTap(item.term)
                    } label: {
                        HStack(spacing: 4) {
                            Text(item.term)
                                .font(.caption.weight(.medium))
                            Image(systemName: item.origin.symbol)
                                .font(.caption2)
                                .foregroundStyle(item.origin == .verified ? .green : .orange)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                        .overlay(
                            Capsule().stroke(
                                item.origin == .verified
                                    ? Color.green.opacity(0.5)
                                    : Color.orange.opacity(0.35),
                                style: StrokeStyle(
                                    lineWidth: 1,
                                    dash: item.origin == .verified ? [] : [3, 2]
                                )
                            )
                        )
                        .foregroundStyle(termExists(item.term) ? Color.accentColor : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func tappable(text: String,
                          highlightedTerm: String? = nil,
                          baseUIColor: UIColor) -> some View {
        TappableText(
            text: text,
            highlightedTerm: highlightedTerm,
            baseColor: baseUIColor,
            onTokenTap: { term in handleTokenTap(term) }
        )
    }

    @ViewBuilder
    private func lookupCard(for term: String) -> some View {
        if let lookup {
            WordQuickLookupCard(
                phase: lookup.phase,
                isAlreadyInLibrary: termExists(term),
                isAdding: isAddingFromPopover,
                onAddToLibrary: { t in
                    Task { await addFromPopover(t) }
                },
                onRetry: { t in
                    Task { await lookup.lookup(term: t, in: words) }
                }
            )
        }
    }

    private func handleTokenTap(_ term: String) {
        guard let lookup else { return }
        let resolvedSync = lookup.prime(term: term, in: words)
        if !resolvedSync {
            Task { await lookup.fetchFromAI(term: term) }
        }
        activePopoverTerm = term
    }

    private func termExists(_ term: String) -> Bool {
        existingTerms.contains(term.lowercased())
    }

    private func addFromPopover(_ term: String) async {
        guard !isAddingFromPopover else { return }
        isAddingFromPopover = true
        defer { isAddingFromPopover = false }

        let normalized = term.lowercased()
        guard !words.contains(where: { $0.term == normalized }) else {
            activePopoverTerm = nil
            return
        }

        do {
            let result = try await analyzer.analyze(term: normalized)
            let newWord = Word(
                term: normalized,
                partOfSpeech: result.partOfSpeech,
                ipa: WordAnalyzer.sanitizeIPA(result.ipa),
                countability: result.countability,
                definition: result.definition,
                turkishMeaning: result.turkishMeaning,
                examples: result.examples,
                level: CEFRLevel(rawValue: result.cefrLevel.uppercased()),
                topics: result.topics.compactMap { WordTopic(rawValue: $0.lowercased()) },
                familyRoot: result.familyRoot.isEmpty ? nil : result.familyRoot.lowercased(),
                familyMembers: result.familyMembers.map { $0.lowercased() },
                inflectionExamples: result.inflectionExamples
            )
            let card = FSRSCard()
            card.word = newWord
            newWord.card = card
            context.insert(newWord)
            await verifier.applyVerifiedRelations(to: newWord, from: result)
            try context.save()

            activePopoverTerm = nil
            lookup?.invalidate(term: normalized)
            withAnimation { recentlyAddedTerm = normalized }
            toastTask?.cancel()
            toastTask = Task {
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation { recentlyAddedTerm = nil }
                }
            }
        } catch {
            popoverError = error.localizedDescription
        }
    }

    @ViewBuilder
    private var addedToast: some View {
        if let term = recentlyAddedTerm {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("\"\(term)\" listene eklendi")
                    .font(.subheadline.bold())
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.green.opacity(0.4), lineWidth: 1))
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
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

private struct StudyLookupTerm: Identifiable, Hashable {
    let value: String
    var id: String { value }
}

#Preview {
    StudyView()
        .modelContainer(PreviewData.container)
}
