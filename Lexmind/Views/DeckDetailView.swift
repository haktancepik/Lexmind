//
//  DeckDetailView.swift
//  Lexmind
//
//  Deck-scoped word list. Reads `deck.words` directly so the list reacts
//  to membership changes. Toolbar "+" opens a multi-select picker over
//  words not yet in the deck; swipe-to-delete removes membership without
//  deleting the underlying Word.
//

import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("activeDeckID") private var activeDeckIDRaw: String = ""
    @AppStorage("rootTabSelection") private var rootTabSelection: Int = RootTab.home.rawValue
    @Bindable var deck: WordDeck
    @State private var searchText = ""
    @State private var showAddSheet = false

    private var sortedWords: [Word] {
        deck.words.sorted { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
    }

    private var filteredWords: [Word] {
        guard !searchText.isEmpty else { return sortedWords }
        return sortedWords.filter {
            $0.term.localizedCaseInsensitiveContains(searchText) ||
            $0.turkishMeaning.localizedCaseInsensitiveContains(searchText) ||
            $0.definition.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            if filteredWords.isEmpty {
                ContentUnavailableView(
                    "Boş deste",
                    systemImage: "tray",
                    description: Text(deck.isPreset
                        ? "Bu seviyede henüz kelime yok. Hazır Kütüphane'den ekleyebilirsin ya da sağ üstteki + ile manuel ekleyebilirsin."
                        : "Bu desteye henüz kelime eklemedin. Sağ üstteki + ile ekleyebilirsin.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredWords) { word in
                    NavigationLink {
                        WordDetailView(word: word)
                    } label: {
                        row(for: word)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            remove(word)
                        } label: {
                            Label("Çıkar", systemImage: "minus.circle")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Kelime ara")
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !deck.words.isEmpty {
                studyDeckButton
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Kelime Ekle", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddWordsToDeckSheet(deck: deck)
        }
    }

    private var studyDeckButton: some View {
        Button {
            studyThisDeck()
        } label: {
            Label("Bu Desteyi Çalış", systemImage: "brain.head.profile")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private func studyThisDeck() {
        activeDeckIDRaw = deck.id.uuidString
        rootTabSelection = RootTab.study.rawValue
    }

    private func remove(_ word: Word) {
        deck.words.removeAll { $0.id == word.id }
        try? context.save()
    }

    @ViewBuilder
    private func row(for word: Word) -> some View {
        HStack(alignment: .center, spacing: 12) {
            stateBadge(for: word)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(word.displayName).font(.headline)
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
}

private struct AddWordsToDeckSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var deck: WordDeck
    @Query(sort: \Word.term) private var allWords: [Word]

    @State private var searchText = ""
    @State private var selectedIDs: Set<PersistentIdentifier> = []

    private var existingIDs: Set<PersistentIdentifier> {
        Set(deck.words.map(\.persistentModelID))
    }

    private var candidates: [Word] {
        let pool = allWords.filter { !existingIDs.contains($0.persistentModelID) }
        guard !searchText.isEmpty else { return pool }
        return pool.filter {
            $0.term.localizedCaseInsensitiveContains(searchText) ||
            $0.turkishMeaning.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allWords.isEmpty {
                    ContentUnavailableView(
                        "Önce kelime ekle",
                        systemImage: "books.vertical",
                        description: Text("Kütüphane'den içe aktar veya manuel kelime ekle.")
                    )
                } else if candidates.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "Eklenecek kelime kalmadı" : "Sonuç yok",
                        systemImage: "checkmark.circle",
                        description: Text(searchText.isEmpty
                            ? "Tüm kelimelerin bu destede zaten var."
                            : "Aramayla eşleşen, destede olmayan kelime bulunamadı.")
                    )
                } else {
                    List {
                        ForEach(candidates) { word in
                            Button {
                                toggle(word)
                            } label: {
                                row(for: word)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Kelime ara")
            .navigationTitle("Kelime Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(selectedIDs.isEmpty ? "Ekle" : "Ekle (\(selectedIDs.count))") {
                        addSelected()
                    }
                    .disabled(selectedIDs.isEmpty)
                }
            }
        }
    }

    private func toggle(_ word: Word) {
        let id = word.persistentModelID
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func addSelected() {
        let toAdd = allWords.filter { selectedIDs.contains($0.persistentModelID) }
        for w in toAdd where !deck.words.contains(where: { $0.id == w.id }) {
            deck.words.append(w)
        }
        try? context.save()
        dismiss()
    }

    @ViewBuilder
    private func row(for word: Word) -> some View {
        HStack(spacing: 12) {
            Image(systemName: selectedIDs.contains(word.persistentModelID)
                  ? "checkmark.circle.fill"
                  : "circle")
                .foregroundStyle(selectedIDs.contains(word.persistentModelID)
                                 ? Color.accentColor
                                 : Color.secondary)
                .imageScale(.large)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(word.displayName).font(.headline)
                    if let lv = word.level {
                        Text(lv.rawValue)
                            .font(.caption2.bold())
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.tertiary, in: Capsule())
                    }
                }
                if !word.turkishMeaning.isEmpty {
                    Text(word.turkishMeaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        DeckDetailView(deck: WordDeck(name: "Önizleme"))
    }
    .modelContainer(PreviewData.container)
}
