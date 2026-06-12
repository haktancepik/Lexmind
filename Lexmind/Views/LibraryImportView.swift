//
//  LibraryImportView.swift
//  Lexmind
//
//  Top-level "Hazır Kütüphane" sheet. Owns @Query state, the import
//  Task, and the result alert; defers preset-deck tiles, filter chips,
//  word rows, and the in-flight progress overlay to small focused
//  subviews.
//

import SwiftUI
import SwiftData

struct LibraryImportView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var existingWords: [Word]
    @Query(filter: #Predicate<WordDeck> { $0.isPreset == true },
           sort: \WordDeck.sortOrder)
    private var presetDecks: [WordDeck]

    /// Optional CEFR level to seed `levelFilter` with on first appearance —
    /// lets the onboarding flow open the sheet pre-filtered to the
    /// learner's chosen level.
    private let initialLevel: CEFRLevel?

    init(initialLevel: CEFRLevel? = nil) {
        self.initialLevel = initialLevel
    }

    @State private var searchText = ""
    @State private var importedCount: Int = 0
    @State private var showResult = false
    @State private var levelFilter: CEFRLevel? = nil
    @State private var topicFilter: WordTopic? = nil
    @State private var recentlyAdded: Set<String> = []
    @State private var importErrorMessage: String?
    @State private var importProgress: LibraryImportProgress?
    @State private var importTask: Task<Void, Never>?
    @State private var importCancelled: Bool = false
    @State private var existingTerms: Set<String> = []
    @State private var librariesReady: Bool = false

    // MARK: - Derived state

    private func refreshExistingTerms() {
        existingTerms = Set(existingWords.map { $0.term.lowercased() })
    }

    private var filtered: [CommonWord] {
        var base = MergedLibrary.filtered(level: levelFilter, topic: topicFilter)
        if !searchText.isEmpty {
            base = base.filter {
                $0.term.localizedCaseInsensitiveContains(searchText) ||
                $0.turkishMeaning.localizedCaseInsensitiveContains(searchText) ||
                $0.definition.localizedCaseInsensitiveContains(searchText)
            }
        }
        return base
    }

    private var visibleNewCount: Int {
        filtered.filter { !existingTerms.contains($0.term.lowercased()) }.count
    }

    private func groupedByLevel(_ list: [CommonWord]) -> [(CEFRLevel, [CommonWord])] {
        let groups = Dictionary(grouping: list, by: { $0.level })
        return CEFRLevel.allCases.compactMap { level in
            guard let words = groups[level], !words.isEmpty else { return nil }
            return (level, words)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if librariesReady {
                    libraryList
                } else {
                    loadingState
                }
            }
            .navigationTitle("Hazır Kütüphane")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert(importErrorMessage == nil ? "İçe aktarıldı" : "Hata",
                   isPresented: $showResult) {
                Button("Tamam", role: .cancel) { }
            } message: {
                resultAlertMessage
            }
            .interactiveDismissDisabled(importTask != nil)
            .overlay {
                if let progress = importProgress {
                    LibraryImportProgressOverlay(
                        progress: progress,
                        canCancel: importTask != nil,
                        onCancel: { importTask?.cancel() }
                    )
                }
            }
            .onAppear {
                refreshExistingTerms()
                WordDeck.bootstrapPresetsIfNeeded(in: context)
                if let initialLevel, levelFilter == nil {
                    levelFilter = initialLevel
                }
            }
            .onChange(of: existingWords.count) { _, _ in
                refreshExistingTerms()
            }
            .task {
                guard !librariesReady else { return }
                async let common: Void = CommonWordsLibrary.preload()
                async let oxford: Void = OxfordWordsLibrary.preload()
                _ = await common
                _ = await oxford
                librariesReady = true
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Kapat") { dismiss() }
                .disabled(importTask != nil)
        }
        if librariesReady {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    importVisible()
                } label: {
                    Label("Hepsini Ekle (\(visibleNewCount))",
                          systemImage: "tray.and.arrow.down.fill")
                }
                .disabled(visibleNewCount == 0 || importTask != nil)
            }
        }
    }

    @ViewBuilder
    private var resultAlertMessage: some View {
        if let err = importErrorMessage {
            Text("Kaydedilemedi: \(err)")
        } else if importedCount == 0 {
            Text(importCancelled
                 ? "İşlem iptal edildi, kelime eklenmedi."
                 : "Yeni kelime eklenmedi (hepsi zaten listende).")
        } else {
            Text(importCancelled
                 ? "\(importedCount) kelime eklendi, işlem yarıda durduruldu."
                 : "\(importedCount) kelime kütüphaneye eklendi.")
        }
    }

    // MARK: - List

    private var libraryList: some View {
        List {
            Section {
                LibraryImportSummaryRow(existingTerms: existingTerms)
            }
            Section("Hazır Desteler") {
                LibraryImportPresetDecks(
                    existingTerms: existingTerms,
                    isImporting: importTask != nil,
                    onTapLevel: { words in importLevel(words) }
                )
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            }
            Section {
                LibraryImportFilterChips(
                    levelFilter: $levelFilter,
                    topicFilter: $topicFilter
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .listRowBackground(Color.clear)
            }
            if filtered.isEmpty {
                Section("Kelimeler (0)") {
                    Text("Eşleşen kelime bulunamadı.")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(groupedByLevel(filtered), id: \.0) { level, words in
                    Section {
                        ForEach(words) { word in
                            let key = word.term.lowercased()
                            LibraryImportWordRow(
                                word: word,
                                alreadyAdded: existingTerms.contains(key),
                                justAdded: recentlyAdded.contains(key),
                                onAdd: { addSingle($0) }
                            )
                        }
                    } header: {
                        LibraryImportLevelSectionHeader(
                            level: level,
                            words: words,
                            existingTerms: existingTerms,
                            isImporting: importTask != nil,
                            onImport: { importLevel($0) }
                        )
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Kütüphanede ara")
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Kelime kütüphanesi hazırlanıyor…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Import flow

    private func addSingle(_ word: CommonWord) {
        importInto([word])
    }

    private func importVisible() {
        let missing = filtered.filter { !existingTerms.contains($0.term.lowercased()) }
        importInto(missing)
    }

    private func importLevel(_ words: [CommonWord]) {
        let missing = words.filter { !existingTerms.contains($0.term.lowercased()) }
        importInto(missing)
    }

    private func importInto(_ list: [CommonWord]) {
        guard importTask == nil else { return }

        let existingSnapshot = existingTerms
        let candidates = list.filter { !existingSnapshot.contains($0.term.lowercased()) }
        guard !candidates.isEmpty else {
            importedCount = 0
            importErrorMessage = nil
            importCancelled = false
            if list.count > 1 { showResult = true }
            return
        }

        let payload = candidates.map { cw in
            let mapRel: ([LibraryRelation]) -> [LibraryImporter.ImportableWord.Relation] = { items in
                items.map { .init(term: $0.term, verified: $0.verified) }
            }
            return LibraryImporter.ImportableWord(
                term: cw.term.lowercased(),
                partOfSpeech: cw.partOfSpeech,
                ipa: cw.ipa,
                countability: cw.countability,
                definition: cw.definition,
                turkishMeaning: cw.turkishMeaning,
                examples: cw.examples,
                levelRaw: cw.level.rawValue,
                topicsRaw: cw.topics.map { $0.rawValue },
                familyRoot: cw.familyRoot,
                familyMembers: cw.familyMembers,
                familyMembersVerified: cw.familyMembersVerified,
                inflectionExamples: cw.inflectionExamples,
                synonyms: mapRel(cw.synonyms),
                antonyms: mapRel(cw.antonyms),
                related: mapRel(cw.related)
            )
        }

        let useOverlay = candidates.count > 1
        if useOverlay {
            importProgress = LibraryImportProgress(total: candidates.count, done: 0, currentTerm: "")
        }
        importCancelled = false

        let container = context.container
        let importer = LibraryImporter(modelContainer: container)
        let addedTerms = candidates.map { $0.term.lowercased() }
        let multiItem = list.count > 1

        importTask = Task {
            var added = 0
            var cancelled = false
            var errorMessage: String?

            do {
                let result = try await importer.importWords(payload) { done, term in
                    importProgress?.done = done
                    if !term.isEmpty {
                        importProgress?.currentTerm = term
                    }
                }
                added = result.added
                cancelled = result.cancelled
            } catch is CancellationError {
                cancelled = true
            } catch {
                errorMessage = error.localizedDescription
            }

            if added > 0 {
                recentlyAdded.formUnion(addedTerms.prefix(added))
            }
            importedCount = added
            importErrorMessage = errorMessage
            importCancelled = cancelled
            importProgress = nil
            importTask = nil
            if multiItem || added == 0 || errorMessage != nil {
                showResult = true
            }
        }
    }
}

#Preview {
    LibraryImportView()
        .modelContainer(PreviewData.container)
}
