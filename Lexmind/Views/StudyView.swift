//
//  StudyView.swift
//  Lexmind
//
//  Top-level Study tab. Holds @Query data and ambient services
//  (analyzer/verifier/lookup) and delegates queue + grade logic to
//  `StudySession`, card chrome to `StudyPromptCard`/`StudyAnswerCard`,
//  and bottom actions to `StudyRatingControls`.
//

import SwiftUI
import SwiftData
import StoreKit
import os

struct StudyView: View {
    var onRequestReading: (() -> Void)? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var words: [Word]
    @Query private var goals: [DailyGoal]
    @Query(sort: \WordDeck.sortOrder) private var decks: [WordDeck]

    /// Empty string = "Tümü"; otherwise a `WordDeck.id` UUID string.
    @AppStorage("activeDeckID") private var activeDeckIDRaw: String = ""

    @State private var session = StudySession()
    @State private var analyzer = WordAnalyzer()
    @State private var verifier = RelationVerifier()
    @State private var lookup: QuickLookupService?
    @State private var activePopoverTerm: String?
    @State private var isAddingFromPopover = false
    @State private var recentlyAddedTerm: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var popoverError: String?
    @State private var existingTerms: Set<String> = []

    private var goal: DailyGoal { goals.first ?? DailyGoal() }

    private var activeDeck: WordDeck? {
        guard !activeDeckIDRaw.isEmpty,
              let uuid = UUID(uuidString: activeDeckIDRaw) else { return nil }
        return decks.first { $0.id == uuid }
    }

    /// Word pool that feeds the study queue. When a deck is active,
    /// only its members are eligible — otherwise the full library is.
    private var scopedWords: [Word] {
        if let deck = activeDeck { return deck.words }
        return words
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if let word = session.current {
                    studyCard(for: word)
                } else if session.queue.isEmpty {
                    StudyEmptyState(
                        sessionReviewed: session.sessionReviewed,
                        activeDeck: activeDeck,
                        onRequestReading: onRequestReading,
                        onDismiss: { dismiss() },
                        deckPicker: deckPicker
                    )
                }
            }
            .navigationTitle("Çalış")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear {
                session.buildQueue(from: scopedWords, reviewLimit: goal.reviewsPerDay)
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
            .onChange(of: session.current == nil) { _, isFinished in
                // Session just ended (queue drained after the last grade).
                // Don't ask if the user just dismissed early — only if
                // they actually graded something this run.
                guard isFinished, session.sessionReviewed > 0 else { return }
                if ReviewPromptManager.registerCompletedSession(reviewedCount: session.sessionReviewed) {
                    requestReview()
                }
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Kapat") { dismiss() }
        }
        ToolbarItem(placement: .principal) {
            VStack {
                Text("\(session.sessionReviewed) tekrar")
                    .font(.caption.bold())
                Text("\(session.queue.count) kaldı")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Study card

    private func studyCard(for word: Word) -> some View {
        VStack(spacing: 16) {
            deckPicker()
            progressBar

            ScrollView {
                VStack(spacing: 20) {
                    StudyPromptCard(word: word, revealed: session.revealed)
                    if session.revealed {
                        StudyAnswerCard(
                            word: word,
                            termExists: termExists,
                            onTokenTap: handleTokenTap
                        )
                    }
                }
                .padding()
            }

            StudyRatingControls(
                word: word,
                revealed: session.revealed,
                session: session,
                onReveal: { withAnimation(.spring) { session.reveal() } },
                onRate: { rating in
                    withAnimation { session.grade(rating, in: context) }
                }
            )
        }
        .task(id: word.term) {
            await enrichFamilyIfNeeded(for: word)
        }
    }

    private var progressBar: some View {
        let total = max(session.queue.count + session.sessionReviewed, 1)
        return ProgressView(value: Double(session.sessionReviewed),
                            total: Double(total))
            .tint(.accentColor)
            .padding(.horizontal)
    }

    private func deckPicker() -> StudyDeckPicker {
        StudyDeckPicker(
            decks: decks,
            activeDeck: activeDeck,
            onSelect: setActiveDeck
        )
    }

    // MARK: - Token lookup popover

    private func lookupCard(for term: String) -> some View {
        LookupPopoverContent(
            lookup: lookup,
            isAlreadyInLibrary: termExists(term),
            isAdding: isAddingFromPopover,
            words: words,
            onAdd: { await addFromPopover($0) }
        )
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
            .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Family enrichment

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
        } catch is CancellationError {
            // Expected when the user advances to the next card mid-flight.
        } catch {
            Log.ai.error("lazyEnrichIfNeeded(\(word.term, privacy: .public)) failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Deck selection

    private func setActiveDeck(_ deck: WordDeck?) {
        activeDeckIDRaw = deck?.id.uuidString ?? ""
        session.rebuildQueue(from: scopedWords, reviewLimit: goal.reviewsPerDay)
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
