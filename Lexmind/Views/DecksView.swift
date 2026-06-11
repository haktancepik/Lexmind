//
//  DecksView.swift
//  Lexmind
//
//  Top-level Decks tab.
//
//  Sections:
//    • Hazır Desteler — six preset CEFR decks (A1..C2). Always present,
//      idempotently seeded on first appearance. Read-only management:
//      no rename/delete, but can be merge sources.
//    • Kendi Destelerim — user-created decks. Swipe actions for rename
//      and delete; toolbar offers "Birleştir" multi-select flow that
//      produces a brand-new deck from any combination of sources.
//

import SwiftUI
import SwiftData

struct DecksView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WordDeck.sortOrder) private var decks: [WordDeck]

    @State private var showNewDeckSheet = false
    @State private var renameTarget: WordDeck?
    @State private var deleteTarget: WordDeck?
    @State private var showMergeSheet = false

    private var presetDecks: [WordDeck] { decks.filter(\.isPreset) }
    private var userDecks: [WordDeck] { decks.filter { !$0.isPreset } }

    var body: some View {
        NavigationStack {
            List {
                Section("Hazır Desteler") {
                    if presetDecks.isEmpty {
                        Text("Yükleniyor…")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(presetDecks) { deck in
                            NavigationLink {
                                DeckDetailView(deck: deck)
                            } label: {
                                presetRow(for: deck)
                            }
                        }
                    }
                }

                Section("Kendi Destelerim") {
                    if userDecks.isEmpty {
                        ContentUnavailableView(
                            "Henüz desten yok",
                            systemImage: "rectangle.stack.badge.plus",
                            description: Text("Sağ üstteki + ile kendi desteni oluştur.")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(userDecks) { deck in
                            NavigationLink {
                                DeckDetailView(deck: deck)
                            } label: {
                                userRow(for: deck)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteTarget = deck
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                                Button {
                                    renameTarget = deck
                                } label: {
                                    Label("Adlandır", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button {
                                    renameTarget = deck
                                } label: {
                                    Label("Yeniden Adlandır", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    deleteTarget = deck
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Desteler")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showNewDeckSheet = true
                        } label: {
                            Label("Yeni Deste", systemImage: "rectangle.stack.badge.plus")
                        }
                        Button {
                            showMergeSheet = true
                        } label: {
                            Label("Desteleri Birleştir", systemImage: "square.stack.3d.up")
                        }
                        .disabled(decks.count < 2)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewDeckSheet) {
                NewDeckSheet()
            }
            .sheet(item: $renameTarget) { deck in
                RenameDeckSheet(deck: deck)
            }
            .sheet(isPresented: $showMergeSheet) {
                MergeDecksSheet()
            }
            .alert(
                "Desteyi sil",
                isPresented: Binding(
                    get: { deleteTarget != nil },
                    set: { if !$0 { deleteTarget = nil } }
                ),
                presenting: deleteTarget
            ) { deck in
                Button("Sil", role: .destructive) {
                    delete(deck)
                }
                Button("Vazgeç", role: .cancel) {
                    deleteTarget = nil
                }
            } message: { deck in
                Text("\"\(deck.name)\" silinecek. İçindeki \(deck.words.count) kelime silinmeyecek, sadece deste bağı kalkacak.")
            }
            .task {
                WordDeck.bootstrapPresetsIfNeeded(in: context)
            }
        }
    }

    private func delete(_ deck: WordDeck) {
        guard !deck.isPreset else { return }
        context.delete(deck)
        try? context.save()
        deleteTarget = nil
    }

    @ViewBuilder
    private func presetRow(for deck: WordDeck) -> some View {
        HStack(spacing: 12) {
            levelBadge(for: deck.presetLevel)
            VStack(alignment: .leading, spacing: 2) {
                Text(deck.name).font(.headline)
                Text("\(deck.words.count) kelime")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func userRow(for deck: WordDeck) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.stack.fill")
                .foregroundStyle(.tint)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(deck.name).font(.headline)
                Text("\(deck.words.count) kelime")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func levelBadge(for level: CEFRLevel?) -> some View {
        let color = cefrColor(level)
        Text(level?.rawValue ?? "?")
            .font(.caption.bold())
            .frame(width: 32, height: 32)
            .background(color.opacity(0.18), in: Circle())
            .foregroundStyle(color)
    }

    private func cefrColor(_ level: CEFRLevel?) -> Color {
        switch level?.tint {
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

private struct NewDeckSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<WordDeck> { !$0.isPreset }) private var userDecks: [WordDeck]
    @State private var name: String = ""

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var nameTaken: Bool {
        userDecks.contains { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }
    }
    private var canSave: Bool { !trimmed.isEmpty && !nameTaken }

    var body: some View {
        NavigationStack {
            Form {
                Section("Deste İsmi") {
                    TextField("Örn. Seyahat", text: $name)
                        .textInputAutocapitalization(.words)
                }
                if nameTaken {
                    Text("Bu isimde bir destem zaten var.")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("Yeni Deste")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Oluştur") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let maxSort = userDecks.map(\.sortOrder).max() ?? -1
        context.insert(WordDeck(
            name: trimmed,
            isPreset: false,
            sortOrder: maxSort + 1
        ))
        try? context.save()
        dismiss()
    }
}

private struct RenameDeckSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var deck: WordDeck
    @Query(filter: #Predicate<WordDeck> { !$0.isPreset }) private var userDecks: [WordDeck]
    @State private var name: String = ""
    @State private var didInitialize = false

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var nameTaken: Bool {
        userDecks.contains {
            $0.id != deck.id &&
            $0.name.caseInsensitiveCompare(trimmed) == .orderedSame
        }
    }
    private var canSave: Bool {
        !trimmed.isEmpty && !nameTaken && trimmed != deck.name
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Yeni İsim") {
                    TextField("Deste ismi", text: $name)
                        .textInputAutocapitalization(.words)
                }
                if nameTaken {
                    Text("Bu isimde bir destem zaten var.")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("Yeniden Adlandır")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if !didInitialize {
                    name = deck.name
                    didInitialize = true
                }
            }
        }
    }

    private func save() {
        deck.name = trimmed
        try? context.save()
        dismiss()
    }
}

private struct MergeDecksSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WordDeck.sortOrder) private var decks: [WordDeck]

    @State private var selectedIDs: Set<UUID> = []
    @State private var newName: String = ""
    @State private var deleteSourcesAfter: Bool = false

    private var trimmed: String { newName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var selectedDecks: [WordDeck] {
        decks.filter { selectedIDs.contains($0.id) }
    }
    private var userDecks: [WordDeck] { decks.filter { !$0.isPreset } }
    private var nameTaken: Bool {
        userDecks.contains { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }
    }
    private var totalUniqueWords: Int {
        Set(selectedDecks.flatMap { $0.words.map(\.id) }).count
    }
    private var hasUserDeckSelected: Bool {
        selectedDecks.contains { !$0.isPreset }
    }
    private var canMerge: Bool {
        selectedIDs.count >= 2 &&
        !trimmed.isEmpty &&
        !nameTaken
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Yeni deste ismi", text: $newName)
                        .textInputAutocapitalization(.words)
                    if nameTaken {
                        Text("Bu isimde bir destem zaten var.")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                } header: {
                    Text("Hedef Deste")
                } footer: {
                    Text("Birleşim sonucu yeni bir kullanıcı destesi oluşur.")
                }

                Section {
                    if decks.isEmpty {
                        Text("Hiç deste yok.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(decks) { deck in
                            Button {
                                toggle(deck.id)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedIDs.contains(deck.id)
                                          ? "checkmark.circle.fill"
                                          : "circle")
                                        .foregroundStyle(selectedIDs.contains(deck.id)
                                                         ? Color.accentColor
                                                         : Color.secondary)
                                        .imageScale(.large)
                                    Image(systemName: deck.isPreset
                                          ? "graduationcap.fill"
                                          : "rectangle.stack.fill")
                                        .foregroundStyle(.tint)
                                        .frame(width: 22)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(deck.name).font(.body)
                                        Text("\(deck.words.count) kelime")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Kaynak Desteler")
                } footer: {
                    if selectedIDs.count >= 2 {
                        Text("\(selectedIDs.count) deste seçili • \(totalUniqueWords) benzersiz kelime")
                    } else {
                        Text("En az 2 deste seç.")
                    }
                }

                if hasUserDeckSelected {
                    Section {
                        Toggle("Birleşim sonrası kaynak desteleri sil", isOn: $deleteSourcesAfter)
                    } footer: {
                        Text("Sadece senin oluşturduğun desteler silinir; hazır CEFR desteleri silinmez.")
                    }
                }
            }
            .navigationTitle("Desteleri Birleştir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Birleştir") { merge() }
                        .disabled(!canMerge)
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func merge() {
        let sources = selectedDecks
        guard sources.count >= 2 else { return }

        let maxSort = userDecks.map(\.sortOrder).max() ?? -1
        let target = WordDeck(
            name: trimmed,
            isPreset: false,
            sortOrder: maxSort + 1
        )
        context.insert(target)

        var seen: Set<PersistentIdentifier> = []
        for src in sources {
            for word in src.words {
                let pid = word.persistentModelID
                if !seen.contains(pid) {
                    target.words.append(word)
                    seen.insert(pid)
                }
            }
        }

        if deleteSourcesAfter {
            for src in sources where !src.isPreset {
                context.delete(src)
            }
        }

        try? context.save()
        dismiss()
    }
}

#Preview {
    DecksView()
        .modelContainer(PreviewData.container)
}
