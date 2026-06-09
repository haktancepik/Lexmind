//
//  WordDetailView.swift
//  Lexmind
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                phoneticsCard
                meaningCard
                examplesCard
                inflectionExamplesCard
                relationsCard
                familyCard
                notesCard
                if let card = word.card {
                    scheduleCard(card: card)
                }
            }
            .padding()
        }
        .navigationTitle(word.term)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) { addedToast }
        .onAppear {
            if lookup == nil {
                lookup = QuickLookupService(analyzer: analyzer)
            }
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
                    Button {
                        regenerate()
                    } label: {
                        Label("AI ile Yeniden Analiz", systemImage: "sparkles")
                    }
                    Button(role: .destructive) {
                        delete()
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(word.term)
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                Spacer()
                if isRegenerating {
                    ProgressView()
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if !word.partOfSpeech.isEmpty {
                        tag(word.partOfSpeech, color: .blue)
                    }
                    if !word.countability.isEmpty,
                       word.countability.lowercased() != "n/a" {
                        tag(word.countability, color: .purple)
                    }
                    if let state = word.card?.state {
                        tag(state.label, color: .green)
                    }
                    if let lv = word.level {
                        tag(lv.label, color: cefrColor(lv))
                    }
                    ForEach(word.topics) { tp in
                        Label(tp.label, systemImage: tp.symbol)
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(.tertiary, in: Capsule())
                    }
                }
            }
            if let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var phoneticsCard: some View {
        sectionCard(title: "Telaffuz", icon: "waveform") {
            if word.ipa.isEmpty {
                Text("Henüz IPA eklenmedi.").foregroundStyle(.secondary)
            } else {
                Text(word.ipa)
                    .font(.system(.title3, design: .monospaced))
            }
        }
    }

    private var meaningCard: some View {
        sectionCard(title: "Anlam", icon: "text.bubble") {
            if !word.turkishMeaning.isEmpty {
                Text(word.turkishMeaning)
                    .font(.title3.bold())
            }
            if !word.definition.isEmpty {
                tappable(text: word.definition, baseUIColor: .secondaryLabel)
                    .padding(.top, 4)
            }
            if word.turkishMeaning.isEmpty, word.definition.isEmpty {
                Text("Anlam henüz eklenmedi.").foregroundStyle(.secondary)
            }
        }
    }

    private var examplesCard: some View {
        sectionCard(title: "Örnek Cümleler", icon: "quote.bubble") {
            if word.examples.isEmpty {
                Text("Örnek cümle yok.").foregroundStyle(.secondary)
            } else {
                ForEach(Array(word.examples.enumerated()), id: \.offset) { idx, line in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(idx + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 18, alignment: .leading)
                        tappable(text: line, highlightedTerm: word.term.lowercased(), baseUIColor: .label)
                    }
                    if idx < word.examples.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var inflectionExamplesCard: some View {
        if !word.inflectionExamples.isEmpty {
            sectionCard(title: "Çekim Örnekleri", icon: "arrow.triangle.branch") {
                ForEach(Array(word.inflectionExamples.enumerated()), id: \.offset) { idx, line in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(idx + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 18, alignment: .leading)
                        tappable(text: line, highlightedTerm: word.familyRoot?.lowercased() ?? word.term.lowercased(), baseUIColor: .label)
                    }
                    if idx < word.inflectionExamples.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tappable(text: String, highlightedTerm: String? = nil, baseUIColor: UIColor) -> some View {
        TappableText(
            text: text,
            highlightedTerm: highlightedTerm,
            baseColor: baseUIColor,
            onTokenTap: { term in
                handleTokenTap(term)
            }
        )
    }

    @ViewBuilder
    private func lookupCard(for term: String) -> some View {
        if let lookup {
            WordQuickLookupCard(
                phase: lookup.phase,
                isAlreadyInLibrary: termExists(term),
                isAdding: isAddingFromPopover,
                onOpenDetail: { t in
                    activePopoverTerm = nil
                    navigationTerm = t
                },
                onAddToLibrary: { t in
                    Task { await addFromPopover(t) }
                },
                onRetry: { t in
                    Task { await lookup.lookup(term: t, in: allWords) }
                }
            )
        }
    }

    private func handleTokenTap(_ term: String) {
        guard let lookup else { return }
        let resolvedSync = lookup.prime(term: term, in: allWords)
        if !resolvedSync {
            Task { await lookup.fetchFromAI(term: term) }
        }
        activePopoverTerm = term
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

    private var notesCard: some View {
        sectionCard(title: "Notlar", icon: "note.text") {
            TextField("Kendi notunu yaz…", text: $word.notes, axis: .vertical)
                .lineLimit(2...8)
        }
    }

    @ViewBuilder
    private var relationsCard: some View {
        if !word.relations.isEmpty {
            sectionCard(title: "İlişkili Kelimeler", icon: "link") {
                let grouped = Dictionary(grouping: word.relations, by: { $0.kind })
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(RelationKind.allCases) { kind in
                        if let items = grouped[kind], !items.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
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
    }

    @ViewBuilder
    private var familyCard: some View {
        let hasRoot = (word.familyRoot?.isEmpty == false)
        let hasMembers = !word.familyMembers.isEmpty
        if hasRoot || hasMembers {
            sectionCard(title: "Kelime Ailesi", icon: "person.3") {
                VStack(alignment: .leading, spacing: 10) {
                    if let root = word.familyRoot, !root.isEmpty {
                        HStack(spacing: 6) {
                            Text("Kök:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button {
                                handleTermTap(root)
                            } label: {
                                Text(root)
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 10).padding(.vertical, 4)
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
                        handleTermTap(item.term)
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
                                    : (termExists(item.term)
                                       ? Color.accentColor.opacity(0.4)
                                       : Color.orange.opacity(0.35)),
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

    private func cefrColor(_ level: CEFRLevel) -> Color {
        switch level.tint {
        case "green": return .green
        case "mint": return .mint
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        default: return .accentColor
        }
    }

    private func scheduleCard(card: FSRSCard) -> some View {
        sectionCard(title: "FSRS Programı", icon: "clock.arrow.circlepath") {
            VStack(alignment: .leading, spacing: 6) {
                row("Durum", value: card.state.label)
                row("Vade", value: card.due.formatted(date: .abbreviated, time: .shortened))
                row("Kararlılık", value: String(format: "%.2f gün", card.stability))
                row("Zorluk", value: String(format: "%.2f / 10", card.difficulty))
                row("Tekrar", value: "\(card.reps)")
                row("Unutma", value: "\(card.lapses)")
            }
        }
    }

    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }

    private func sectionCard<Content: View>(title: String,
                                            icon: String,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
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
