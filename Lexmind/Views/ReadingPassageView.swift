//
//  ReadingPassageView.swift
//  Lexmind
//

import SwiftUI
import SwiftData

struct ReadingPassageView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var words: [Word]
    @Query private var storedPassages: [DailyReadingPassage]

    @State private var generator = ReadingPassageGenerator()
    @State private var analyzer = WordAnalyzer()
    @State private var verifier = RelationVerifier()
    @State private var lookup: QuickLookupService?
    @State private var activePopoverTerm: String?
    @State private var isAddingFromPopover = false

    @State private var isGenerating = false
    @State private var partial: ReadingPassageGeneration.PartiallyGenerated?
    @State private var error: String?
    @State private var confirmRegenerate = false
    @State private var existingTerms: Set<String> = []

    private var todayStart: Date { Calendar.current.startOfDay(for: .now) }

    private var todaysPassage: DailyReadingPassage? {
        storedPassages.first { Calendar.current.isDate($0.date, inSameDayAs: todayStart) }
    }

    private var studiedToday: [Word] {
        let cal = Calendar.current
        return words.filter { w in
            w.reviewLogs.contains { cal.isDateInToday($0.reviewedAt) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let unavailable = generator.availabilityMessage {
                    unavailableCard(message: unavailable)
                } else if let stored = todaysPassage {
                    passageCard(stored: stored)
                } else if studiedToday.isEmpty {
                    emptyStudiedCard
                } else if isGenerating {
                    generatingCard
                } else if let error {
                    errorCard(error)
                } else {
                    Color.clear.frame(height: 1)
                }
            }
            .padding()
        }
        .navigationTitle("Bugünün Okuma Metni")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Kapat") { dismiss() }
            }
        }
        .task {
            purgeStaleRows()
            if lookup == nil {
                lookup = QuickLookupService(analyzer: analyzer)
            }
            existingTerms = Set(words.map { $0.term })
            if todaysPassage == nil,
               !studiedToday.isEmpty,
               generator.availabilityMessage == nil,
               !isGenerating {
                await generateAndPersist()
            }
        }
        .task(id: words.count) {
            existingTerms = Set(words.map { $0.term })
        }
        .confirmationDialog(
            "Yeni bir metin oluşturulsun mu?",
            isPresented: $confirmRegenerate,
            titleVisibility: .visible
        ) {
            Button("Tekrar Oluştur", role: .destructive) {
                Task { await regenerate() }
            }
            Button("Vazgeç", role: .cancel) { }
        } message: {
            Text("Mevcut metin silinecek ve günün kelimelerinden yenisi üretilecek.")
        }
        .popover(
            item: Binding(
                get: { activePopoverTerm.map(ReadingLookupTerm.init) },
                set: { activePopoverTerm = $0?.value }
            ),
            attachmentAnchor: .point(.top),
            arrowEdge: .top
        ) { wrapper in
            lookupCard(for: wrapper.value)
                .presentationCompactAdaptation(.popover)
        }
    }

    // MARK: - Cards

    @ViewBuilder
    private func passageCard(stored: DailyReadingPassage) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            header(title: stored.title,
                   cefr: stored.cefrLevel,
                   showRegenerate: true)

            TappableText(
                text: stored.passageText,
                highlightedTerm: nil,
                highlightedTerms: Set(stored.wordTermsRaw.map { $0.lowercased() }),
                baseColor: .label,
                onTokenTap: { term in handleTokenTap(term) }
            )

            footerChips(terms: presentTerms(in: stored.passageText,
                                            from: stored.wordTermsRaw))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    @ViewBuilder
    private var generatingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ProgressView()
                Text("Metin yazılıyor…")
                    .font(.subheadline.bold())
                Spacer()
            }
            if let p = partial {
                if let title = p.title, !title.isEmpty {
                    Text(title).font(.title3.bold())
                }
                if let body = p.passage, !body.isEmpty {
                    Text(body)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            } else {
                Text("Bugün çalıştığın kelimelerden bir paragraf hazırlanıyor.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    @ViewBuilder
    private var emptyStudiedCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Henüz bugün kelime çalışmadın")
                .font(.headline)
            Text("Önce birkaç kelime çalış, sonra metnin hazır olsun.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    @ViewBuilder
    private func unavailableCard(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles.slash")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text("Yapay zeka kullanılamıyor")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    @ViewBuilder
    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Metin oluşturulamadı", systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button {
                Task {
                    self.error = nil
                    await generateAndPersist()
                }
            } label: {
                Label("Tekrar Dene", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    @ViewBuilder
    private func header(title: String, cefr: String, showRegenerate: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(title)
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !cefr.isEmpty {
                    Text(cefr)
                        .font(.caption.bold())
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
            }
            if showRegenerate {
                Button {
                    confirmRegenerate = true
                } label: {
                    Label("Tekrar Oluştur", systemImage: "arrow.clockwise")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isGenerating)
            }
        }
    }

    @ViewBuilder
    private func footerChips(terms: [String]) -> some View {
        if !terms.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Bugünün Kelimeleri")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(terms, id: \.self) { term in
                            Button {
                                handleTokenTap(term)
                            } label: {
                                Text(term)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                                    .foregroundStyle(Color.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Lookup popover

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
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Generation

    private func generateAndPersist() async {
        guard !isGenerating else { return }
        isGenerating = true
        partial = nil
        error = nil
        defer { isGenerating = false }

        let words = studiedToday
        do {
            var finalSnapshot: ReadingPassageGeneration.PartiallyGenerated?
            for try await snap in generator.stream(words: words) {
                finalSnapshot = snap
                partial = snap
            }
            guard
                let snap = finalSnapshot,
                let title = snap.title, !title.isEmpty,
                let passage = snap.passage, !passage.isEmpty
            else {
                error = "Metin oluşturulamadı."
                return
            }
            let cefr = snap.cefrLevel ?? ""
            let usedTerms = ReadingPassageGenerator
                .sampleRecent(words: words, limit: ReadingPassageGenerator.maxWords)
                .map { $0.term }

            let model = DailyReadingPassage(
                date: .now,
                title: title,
                passageText: passage,
                cefrLevel: cefr,
                wordTerms: usedTerms
            )
            context.insert(model)
            try? context.save()
            partial = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func regenerate() async {
        if let existing = todaysPassage {
            context.delete(existing)
            try? context.save()
        }
        await generateAndPersist()
    }

    private func purgeStaleRows() {
        let stale = storedPassages.filter {
            !Calendar.current.isDate($0.date, inSameDayAs: todayStart)
        }
        guard !stale.isEmpty else { return }
        for row in stale { context.delete(row) }
        try? context.save()
    }

    // MARK: - Helpers

    private func presentTerms(in text: String, from candidates: [String]) -> [String] {
        let tokens = Tokenizer.tokenize(text)
        var normalized = Set<String>()
        for token in tokens {
            if case .word(let n) = token.kind {
                normalized.insert(n)
            }
        }
        return candidates
            .map { $0.lowercased() }
            .filter { normalized.contains($0) }
            .uniqued()
    }
}

private struct ReadingLookupTerm: Identifiable, Hashable {
    let value: String
    var id: String { value }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

#Preview {
    NavigationStack {
        ReadingPassageView()
    }
    .modelContainer(PreviewData.container)
}
