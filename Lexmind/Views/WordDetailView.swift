//
//  WordDetailView.swift
//  Lexmind
//
//  Top-level Word detail screen. Owns @Query/@Bindable state and the
//  cross-card services (analyzer, verifier, lookup), and composes
//  Header / Phonetics / Meaning / Examples / Inflection / Relations /
//  Family / Notes / Schedule subviews. The lookup popover and the
//  "add this term" confirmation flow live here because they straddle
//  the whole screen.
//

import SwiftUI
import SwiftData

struct WordDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var word: Word
    @Query private var allWords: [Word]

    @State private var analyzer = WordAnalyzer()
    @State private var verifier = RelationVerifier()
    @State private var isRegenerating = false
    @State private var error: String?
    @State private var pendingAddTerm: String? = nil
    @State private var navigationTerm: String? = nil
    @State private var isAddingFromChip = false

    @State private var lookup: QuickLookupService?
    @State private var activePopoverTerm: String? = nil
    @State private var isAddingFromPopover = false
    @State private var recentlyAddedTerm: String? = nil
    @State private var toastTask: Task<Void, Never>?
    @State private var existingTerms: Set<String> = []

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                WordDetailHeader(
                    word: word,
                    isRegenerating: isRegenerating,
                    error: error
                )
                WordDetailPhoneticsCard(word: word)
                WordDetailMeaningCard(word: word, onTokenTap: handleTokenTap)
                WordDetailExamplesCard(word: word, onTokenTap: handleTokenTap)
                WordDetailInflectionExamplesCard(word: word, onTokenTap: handleTokenTap)
                WordDetailRelationsCard(
                    word: word,
                    isRegenerating: isRegenerating,
                    isVerifying: verifier.isVerifying,
                    verifierError: verifier.lastError,
                    termExists: termExists,
                    onTermTap: handleTermTap,
                    onRetryVerification: {
                        Task { await verifier.retryVerification(for: word) }
                    }
                )
                WordDetailFamilyCard(
                    word: word,
                    isRegenerating: isRegenerating,
                    isVerifying: verifier.isVerifying,
                    hasVerifierError: verifier.lastError != nil,
                    termExists: termExists,
                    onTermTap: handleTermTap
                )
                notesCard
                if let card = word.card {
                    WordDetailScheduleCard(card: card)
                }
            }
            .padding()
        }
        .navigationTitle(word.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) { addedToast }
        .onAppear {
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
        .task(id: allWords.count) {
            existingTerms = Set(allWords.map { $0.term })
        }
        .task(id: word.term) {
            await lazyEnrichIfNeeded()
        }
        .popover(
            item: Binding(
                get: { activePopoverTerm.map(LookupTerm.init) },
                set: { activePopoverTerm = $0?.value }
            ),
            attachmentAnchor: .point(.top),
            arrowEdge: .top
        ) { wrapper in
            lookupCard(for: wrapper.value)
                .presentationCompactAdaptation(.popover)
        }
        .navigationDestination(item: $navigationTerm) { term in
            if let target = allWords.first(where: { $0.term == term }) {
                WordDetailView(word: target)
            } else {
                Text("Kelime bulunamadı").foregroundStyle(.secondary)
            }
        }
        .confirmationDialog(
            "Bu kelimeyi kütüphanene eklemek ister misin?",
            isPresented: Binding(
                get: { pendingAddTerm != nil },
                set: { if !$0 { pendingAddTerm = nil } }
            ),
            presenting: pendingAddTerm
        ) { term in
            Button("Ekle ve Aç") {
                Task { await addWordFromTerm(term) }
            }
            Button("Vazgeç", role: .cancel) {
                pendingAddTerm = nil
            }
        } message: { term in
            Text("\"\(term)\" kelimesi AI ile analiz edilip kütüphanene eklenecek.")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { regenerate() } label: {
                        Label("AI ile Yeniden Analiz", systemImage: "sparkles")
                    }
                    Button(role: .destructive) { delete() } label: {
                        Label("Sil", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var notesCard: some View {
        WordDetailSectionCard(title: "Notlar", icon: "note.text") {
            TextField("Kendi notunu yaz…", text: $word.notes, axis: .vertical)
                .lineLimit(2...8)
        }
    }

    // MARK: - Lookup popover

    private func lookupCard(for term: String) -> some View {
        LookupPopoverContent(
            lookup: lookup,
            isAlreadyInLibrary: termExists(term),
            isAdding: isAddingFromPopover,
            words: allWords,
            onOpenDetail: { t in
                activePopoverTerm = nil
                navigationTerm = t
            },
            onAdd: { await addFromPopover($0) }
        )
    }

    private func handleTokenTap(_ term: String) {
        guard let lookup else { return }
        let resolvedSync = lookup.prime(term: term, in: allWords)
        if !resolvedSync {
            Task { await lookup.fetchFromAI(term: term) }
        }
        activePopoverTerm = term
    }

    private func termExists(_ term: String) -> Bool {
        existingTerms.contains(term.lowercased())
    }

    private func handleTermTap(_ term: String) {
        let normalized = term.lowercased()
        if termExists(normalized) {
            navigationTerm = normalized
        } else {
            pendingAddTerm = normalized
        }
    }

    private func addFromPopover(_ term: String) async {
        await addWordFromTerm(term, openAfterAdd: false)
        if error == nil {
            activePopoverTerm = nil
            lookup?.invalidate(term: term)
            withAnimation { recentlyAddedTerm = term }
            toastTask?.cancel()
            toastTask = Task {
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation { recentlyAddedTerm = nil }
                }
            }
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

    // MARK: - Add / enrich / regenerate / delete

    private func addWordFromTerm(_ term: String, openAfterAdd: Bool = true) async {
        if openAfterAdd {
            guard !isAddingFromChip else { return }
            isAddingFromChip = true
        } else {
            guard !isAddingFromPopover else { return }
            isAddingFromPopover = true
        }
        defer {
            if openAfterAdd { isAddingFromChip = false }
            else { isAddingFromPopover = false }
        }

        let normalized = term.lowercased()
        guard !allWords.contains(where: { $0.term == normalized }) else {
            pendingAddTerm = nil
            if openAfterAdd { navigationTerm = normalized }
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
            pendingAddTerm = nil
            if openAfterAdd { navigationTerm = normalized }
        } catch {
            self.error = error.localizedDescription
            pendingAddTerm = nil
        }
    }

    private func lazyEnrichIfNeeded() async {
        guard !isRegenerating, analyzer.isAvailable else { return }
        let needsCore = word.definition.isEmpty && word.turkishMeaning.isEmpty
        let needsFamily = word.familyRoot == nil
            && word.familyMembers.isEmpty
            && word.relations.isEmpty
        guard needsCore || needsFamily else { return }

        isRegenerating = true
        defer { isRegenerating = false }
        let preservedLevel = word.level
        let preservedTopics = word.topics
        do {
            let result = try await analyzer.analyze(term: word.term)
            if needsCore {
                word.partOfSpeech = result.partOfSpeech
                word.ipa = WordAnalyzer.sanitizeIPA(result.ipa)
                word.countability = result.countability
                word.definition = result.definition
                word.turkishMeaning = result.turkishMeaning
                word.examples = result.examples
                if preservedLevel == nil,
                   let lv = CEFRLevel(rawValue: result.cefrLevel.uppercased()) {
                    word.level = lv
                }
                let onlyGeneric = preservedTopics.isEmpty || preservedTopics == [.general]
                if onlyGeneric {
                    let parsed = result.topics.compactMap { WordTopic(rawValue: $0.lowercased()) }
                    if !parsed.isEmpty { word.topics = parsed }
                }
            }
            if needsFamily {
                word.familyRoot = result.familyRoot.isEmpty ? nil : result.familyRoot.lowercased()
                word.familyMembers = result.familyMembers.map { $0.lowercased() }
                word.inflectionExamples = result.inflectionExamples
                await verifier.applyVerifiedRelations(to: word, from: result)
            }
            try? context.save()
        } catch {
            // Silent fail — stub stays, user can tap Regenerate or come back later.
        }
    }

    private func regenerate() {
        error = nil
        isRegenerating = true
        Task {
            defer { isRegenerating = false }
            do {
                let result = try await analyzer.analyze(term: word.term)
                word.partOfSpeech = result.partOfSpeech
                word.ipa = WordAnalyzer.sanitizeIPA(result.ipa)
                word.countability = result.countability
                word.definition = result.definition
                word.turkishMeaning = result.turkishMeaning
                word.examples = result.examples
                if let lv = CEFRLevel(rawValue: result.cefrLevel.uppercased()) {
                    word.level = lv
                }
                let parsedTopics = result.topics.compactMap { WordTopic(rawValue: $0.lowercased()) }
                if !parsedTopics.isEmpty {
                    word.topics = parsedTopics
                }
                word.familyRoot = result.familyRoot.isEmpty ? nil : result.familyRoot.lowercased()
                word.familyMembers = result.familyMembers.map { $0.lowercased() }
                word.inflectionExamples = result.inflectionExamples

                for relation in word.relations {
                    context.delete(relation)
                }
                await verifier.applyVerifiedRelations(to: word, from: result)

                try context.save()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func delete() {
        context.delete(word)
        try? context.save()
        dismiss()
    }
}

private struct LookupTerm: Identifiable, Hashable {
    let value: String
    var id: String { value }
}

#Preview {
    NavigationStack {
        if let sample = try? PreviewData.container.mainContext.fetch(FetchDescriptor<Word>()).first {
            WordDetailView(word: sample)
        }
    }
    .modelContainer(PreviewData.container)
}
