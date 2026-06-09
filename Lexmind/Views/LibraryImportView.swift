//
//  LibraryImportView.swift
//  Lexmind
//

import SwiftUI
import SwiftData

private enum MergedLibrary {
    static let all: [CommonWord] = {
        var seen = Set<String>()
        var merged: [CommonWord] = []
        merged.reserveCapacity(CommonWordsLibrary.all.count + OxfordWordsLibrary.all.count)
        for word in CommonWordsLibrary.all + OxfordWordsLibrary.all {
            let key = word.term.lowercased()
            if seen.insert(key).inserted {
                merged.append(word)
            }
        }
        return merged
    }()

    static let allTermSet: Set<String> = Set(all.map { $0.term.lowercased() })

    static func filtered(level: CEFRLevel?, topic: WordTopic?) -> [CommonWord] {
        all.filter { word in
            if let level, word.level != level { return false }
            if let topic, !word.topics.contains(topic) { return false }
            return true
        }
    }
}

struct LibraryImportView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var existingWords: [Word]

    @State private var searchText = ""
    @State private var importedCount: Int = 0
    @State private var showResult = false
    @State private var levelFilter: CEFRLevel? = nil
    @State private var topicFilter: WordTopic? = nil
    @State private var recentlyAdded: Set<String> = []
    @State private var importErrorMessage: String?
    @State private var importProgress: ImportProgress?
    @State private var importTask: Task<Void, Never>?
    @State private var importCancelled: Bool = false
    @State private var existingTerms: Set<String> = []

    private struct ImportProgress: Equatable {
        var total: Int
        var done: Int
        var currentTerm: String
    }

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

    private var newWordsCount: Int {
        MergedLibrary.all.filter { !existingTerms.contains($0.term.lowercased()) }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    summaryRow
                }

                Section {
                    filterChips
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
                                row(for: word)
                            }
                        } header: {
                            levelSectionHeader(level: level, words: words)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Kütüphanede ara")
            .navigationTitle("Hazır Kütüphane")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .disabled(importTask != nil)
                }
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
            .alert(importErrorMessage == nil ? "İçe aktarıldı" : "Hata",
                   isPresented: $showResult) {
                Button("Tamam", role: .cancel) { }
            } message: {
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
            .interactiveDismissDisabled(importTask != nil)
            .overlay {
                if let progress = importProgress {
                    importProgressOverlay(progress)
                }
            }
            .onAppear { refreshExistingTerms() }
            .onChange(of: existingWords.count) { _, _ in
                refreshExistingTerms()
            }
        }
    }

    @ViewBuilder
    private func importProgressOverlay(_ progress: ImportProgress) -> some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { }
            VStack(spacing: 14) {
                Text("Kelimeler ekleniyor…")
                    .font(.headline)
                ProgressView(value: Double(progress.done),
                             total: Double(max(progress.total, 1)))
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
                    .animation(.linear(duration: 0.15), value: progress.done)
                Text("\(progress.done) / \(progress.total) kelime")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                if !progress.currentTerm.isEmpty {
                    Text(progress.currentTerm)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                Button(role: .destructive) {
                    importTask?.cancel()
                } label: {
                    Label("İptal", systemImage: "xmark.circle")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 4)
                .disabled(importTask == nil)
            }
            .padding(20)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
            )
            .shadow(radius: 12)
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
    }

    private var filterChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CEFRLevel.allCases) { lv in
                        chip(
                            title: lv.label,
                            symbol: "graduationcap",
                            isSelected: levelFilter == lv,
                            tint: cefrColor(lv)
                        ) {
                            levelFilter = (levelFilter == lv) ? nil : lv
                        }
                    }
                }
                .padding(.horizontal)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WordTopic.allCases) { tp in
                        chip(
                            title: tp.label,
                            symbol: tp.symbol,
                            isSelected: topicFilter == tp,
                            tint: .accentColor
                        ) {
                            topicFilter = (topicFilter == tp) ? nil : tp
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func chip(title: String,
                      symbol: String,
                      isSelected: Bool,
                      tint: Color,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? tint.opacity(0.2) : Color(.tertiarySystemFill))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? tint : .clear, lineWidth: 1)
                )
                .foregroundStyle(isSelected ? tint : Color.primary)
        }
        .buttonStyle(.plain)
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

    private var summaryRow: some View {
        let total = MergedLibrary.all.count
        let alreadyIn = existingTerms.intersection(MergedLibrary.allTermSet).count
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(total) kelime")
                    .font(.headline)
                Text("\(alreadyIn) zaten ekli")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "books.vertical.fill")
                .font(.title)
                .foregroundStyle(.tint)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func row(for word: CommonWord) -> some View {
        let termKey = word.term.lowercased()
        let alreadyAdded = existingTerms.contains(termKey)
        let justAdded = recentlyAdded.contains(termKey)

        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(word.term)
                        .font(.body.bold())
                    Text(word.partOfSpeech)
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.tertiary, in: Capsule())
                    Spacer()
                }
                if word.turkishMeaning.isEmpty {
                    Text("Tanım ilk açışta cihazda dolar")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .italic()
                } else {
                    Text(word.turkishMeaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !word.ipa.isEmpty {
                    Text(word.ipa)
                        .font(.caption.monospaced())
                        .foregroundStyle(.tertiary)
                }
                HStack(spacing: 6) {
                    Text(word.level.label)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(cefrColor(word.level).opacity(0.18), in: Capsule())
                        .foregroundStyle(cefrColor(word.level))
                    ForEach(word.topics, id: \.self) { tp in
                        Image(systemName: tp.symbol)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 8)

            Button {
                addSingle(word)
            } label: {
                if alreadyAdded {
                    Label(justAdded ? "Eklendi" : "Ekli", systemImage: "checkmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .buttonStyle(.plain)
            .disabled(alreadyAdded)
            .accessibilityLabel(alreadyAdded ? "Ekli" : "Ekle")
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var visibleNewCount: Int {
        filtered.filter { !existingTerms.contains($0.term.lowercased()) }.count
    }

    private func newCount(in list: [CommonWord]) -> Int {
        list.filter { !existingTerms.contains($0.term.lowercased()) }.count
    }

    private func groupedByLevel(_ list: [CommonWord]) -> [(CEFRLevel, [CommonWord])] {
        let groups = Dictionary(grouping: list, by: { $0.level })
        return CEFRLevel.allCases.compactMap { level in
            guard let words = groups[level], !words.isEmpty else { return nil }
            return (level, words)
        }
    }

    @ViewBuilder
    private func levelSectionHeader(level: CEFRLevel, words: [CommonWord]) -> some View {
        let newCountInLevel = newCount(in: words)
        let tint = cefrColor(level)
        HStack(spacing: 8) {
            Text(level.label)
                .font(.caption2.bold())
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(tint.opacity(0.2), in: Capsule())
                .foregroundStyle(tint)
            Text("\(words.count) kelime · \(newCountInLevel) yeni")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(nil)
            Spacer()
            Button {
                importLevel(words)
            } label: {
                Label("Hepsini ekle", systemImage: "tray.and.arrow.down")
                    .labelStyle(.titleAndIcon)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(tint.opacity(newCountInLevel == 0 ? 0.08 : 0.18), in: Capsule())
                    .foregroundStyle(newCountInLevel == 0 ? Color.secondary : tint)
                    .textCase(nil)
            }
            .buttonStyle(.plain)
            .disabled(newCountInLevel == 0 || importTask != nil)
        }
    }

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
            importProgress = ImportProgress(total: candidates.count, done: 0, currentTerm: "")
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
