//
//  WordsListView.swift
//  Lexmind
//

import SwiftUI
import SwiftData

struct WordsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Word.createdAt, order: .reverse) private var words: [Word]
    @State private var searchText = ""
    @State private var showAddWord = false
    @State private var showLibrary = false
    @State private var filter: Filter = .all
    @State private var levelFilter: CEFRLevel? = nil
    @State private var topicFilter: WordTopic? = nil

    enum Filter: String, CaseIterable, Identifiable {
        case all = "Tümü"
        case due = "Bekleyen"
        case new = "Yeni"
        case learned = "Öğrenildi"
        var id: String { rawValue }
    }

    var filtered: [Word] {
        var base: [Word]
        switch filter {
        case .all: base = words
        case .due: base = words.filter { $0.card?.isDue ?? true }
        case .new: base = words.filter { ($0.card?.state ?? .new) == .new }
        case .learned: base = words.filter { ($0.card?.state ?? .new) == .review }
        }
        if let lv = levelFilter {
            base = base.filter { $0.level == lv }
        }
        if let tp = topicFilter {
            base = base.filter { $0.topics.contains(tp) }
        }
        if searchText.isEmpty { return base }
        return base.filter {
            $0.term.localizedCaseInsensitiveContains(searchText) ||
            $0.turkishMeaning.localizedCaseInsensitiveContains(searchText) ||
            $0.definition.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Filtre", selection: $filter) {
                        ForEach(Filter.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

                    HStack(spacing: 12) {
                        Menu {
                            Button("Tümü") { levelFilter = nil }
                            ForEach(CEFRLevel.allCases) { lv in
                                Button(lv.label) { levelFilter = lv }
                            }
                        } label: {
                            Label(levelFilter?.label ?? "Tüm Seviyeler",
                                  systemImage: "graduationcap")
                                .font(.caption)
                        }

                        Menu {
                            Button("Tümü") { topicFilter = nil }
                            ForEach(WordTopic.allCases) { tp in
                                Button(tp.label, systemImage: tp.symbol) {
                                    topicFilter = tp
                                }
                            }
                        } label: {
                            Label(topicFilter?.label ?? "Tüm Konular",
                                  systemImage: topicFilter?.symbol ?? "tag")
                                .font(.caption)
                        }

                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                }

                if filtered.isEmpty {
                    ContentUnavailableView(
                        "Kelime bulunamadı",
                        systemImage: "text.book.closed",
                        description: Text("Sağ üstteki + ile yeni bir kelime ekle.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filtered) { word in
                        NavigationLink {
                            WordDetailView(word: word)
                        } label: {
                            row(for: word)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Kelime ara")
            .navigationTitle("Kelimeler")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showAddWord = true
                        } label: {
                            Label("Yeni Kelime", systemImage: "plus")
                        }
                        Button {
                            showLibrary = true
                        } label: {
                            Label("Hazır Kütüphane", systemImage: "books.vertical")
                        }
                    } label: {
                        Label("Ekle", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddWord) {
                AddWordView()
            }
            .sheet(isPresented: $showLibrary) {
                LibraryImportView()
            }
        }
    }

    private func row(for word: Word) -> some View {
        HStack(alignment: .center, spacing: 12) {
            stateBadge(for: word)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(word.term).font(.headline)
                    if !word.partOfSpeech.isEmpty {
                        Text(word.partOfSpeech)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.tertiary, in: Capsule())
                    }
                    if let lv = word.level {
                        Text(lv.label)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(cefrColor(lv).opacity(0.18), in: Capsule())
                            .foregroundStyle(cefrColor(lv))
                    }
                }
                if !word.turkishMeaning.isEmpty {
                    Text(word.turkishMeaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let due = word.card?.due {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(due, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(stateLabel(for: word))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func stateBadge(for word: Word) -> some View {
        let state = word.card?.state ?? .new
        let color: Color = {
            switch state {
            case .new: return .purple
            case .learning: return .blue
            case .review: return .green
            case .relearning: return .orange
            }
        }()
        Circle().fill(color).frame(width: 10, height: 10)
    }

    private func stateLabel(for word: Word) -> String {
        word.card?.state.label ?? CardState.new.label
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

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filtered[index])
        }
    }
}

#Preview {
    WordsListView()
        .modelContainer(PreviewData.container)
}
