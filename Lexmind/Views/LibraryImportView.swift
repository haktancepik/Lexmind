//
//  LibraryImportView.swift
//  Lexmind
//

import SwiftUI
import SwiftData

enum LibrarySource: String, CaseIterable, Identifiable {
    case common
    case oxford

    var id: String { rawValue }

    var label: String {
        switch self {
        case .common: return "Hazır"
        case .oxford: return "Oxford 5000"
        }
    }

    var all: [CommonWord] {
        switch self {
        case .common: return CommonWordsLibrary.all
        case .oxford: return OxfordWordsLibrary.all
        }
    }

    func filtered(level: CEFRLevel?, topic: WordTopic?) -> [CommonWord] {
        switch self {
        case .common: return CommonWordsLibrary.filtered(level: level, topic: topic)
        case .oxford: return OxfordWordsLibrary.filtered(level: level, topic: topic)
        }
    }
}

struct LibraryImportView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var existingWords: [Word]

    @State private var source: LibrarySource = .common
    @State private var searchText = ""
    @State private var importedCount: Int = 0
    @State private var showResult = false
    @State private var levelFilter: CEFRLevel? = nil
    @State private var topicFilter: WordTopic? = nil
    @State private var recentlyAdded: Set<String> = []
    @State private var importErrorMessage: String?

    private var existingTerms: Set<String> {
        Set(existingWords.map { $0.term.lowercased() })
    }

    private var filtered: [CommonWord] {
        var base = source.filtered(level: levelFilter, topic: topicFilter)
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
        source.all.filter { !existingTerms.contains($0.term.lowercased()) }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Kaynak", selection: $source) {
                        ForEach(LibrarySource.allCases) { src in
                            Text(src.label).tag(src)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    summaryRow
                } footer: {
                    Text(sourceFooter)
                }

                Section {
                    filterChips
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                }

                Section("Kelimeler (\(filtered.count))") {
                    if filtered.isEmpty {
                        Text("Eşleşen kelime bulunamadı.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filtered) { word in
                            row(for: word)
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
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        importVisible()
                    } label: {
                        Label("Hepsini Ekle (\(visibleNewCount))",
                              systemImage: "tray.and.arrow.down.fill")
                    }
                    .disabled(visibleNewCount == 0)
                }
            }
            .alert(importErrorMessage == nil ? "İçe aktarıldı" : "Hata",
                   isPresented: $showResult) {
                Button("Tamam", role: .cancel) { }
            } message: {
                if let err = importErrorMessage {
                    Text("Kaydedilemedi: \(err)")
                } else {
                    Text(importedCount == 0
                         ? "Yeni kelime eklenmedi (hepsi zaten listende)."
                         : "\(importedCount) kelime kütüphaneye eklendi.")
                }
            }
        }
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

    private var sourceFooter: String {
        switch source {
        case .common:
            return "Kütüphanedeki kelimeler örnek cümleleriyle birlikte hazır gelir. İstediklerini seç veya tümünü ekle."
        case .oxford:
            return "Oxford 5000 ileri seviye listesi (B2–C1). Tanım ve örnekler önceden hazırlanmıştır."
        }
    }

    private var summaryRow: some View {
        let total = source.all.count
        let alreadyIn = existingTerms.intersection(Set(source.all.map { $0.term.lowercased() })).count
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(total) \(source == .oxford ? "Oxford" : "hazır") kelime")
                    .font(.headline)
                Text("\(alreadyIn) zaten ekli")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: source == .oxford ? "graduationcap.fill" : "books.vertical.fill")
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

    private func addSingle(_ word: CommonWord) {
        importInto([word])
    }

    private func importVisible() {
        let missing = filtered.filter { !existingTerms.contains($0.term.lowercased()) }
        importInto(missing)
    }

    private func importInto(_ list: [CommonWord]) {
        var added = 0
        var addedTerms: [String] = []
        var firstError: Error?

        for cw in list {
            let term = cw.term.lowercased()
            guard !existingTerms.contains(term) else { continue }
            let word = Word(
                term: term,
                partOfSpeech: cw.partOfSpeech,
                ipa: cw.ipa,
                countability: cw.countability,
                definition: cw.definition,
                turkishMeaning: cw.turkishMeaning,
                examples: cw.examples,
                level: cw.level,
                topics: cw.topics
            )
            let card = FSRSCard()
            word.card = card
            card.word = word
            context.insert(word)
            context.insert(card)
            do {
                try context.save()
                added += 1
                addedTerms.append(term)
            } catch {
                context.rollback()
                if firstError == nil { firstError = error }
            }
        }

        recentlyAdded.formUnion(addedTerms)
        importedCount = added
        importErrorMessage = firstError?.localizedDescription
        if list.count > 1 || added == 0 || firstError != nil {
            showResult = true
        }
    }
}

#Preview {
    LibraryImportView()
        .modelContainer(PreviewData.container)
}
