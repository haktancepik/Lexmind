//
//  DecksView.swift
//  Lexmind
//
//  Top-level Decks tab. Two sections:
//    • Hazır Desteler — six preset CEFR decks (A1..C2). Always present,
//      idempotently seeded on first appearance.
//    • Kendi Destelerim — user-created decks. Plus button opens a sheet
//      that takes a name and inserts an empty deck.
//
//  Rename/delete/merge and "Bu desteyi çalış" wiring land in later 1.6
//  slices; this view is the navigation shell + new-deck creation only.
//

import SwiftUI
import SwiftData

struct DecksView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WordDeck.sortOrder) private var decks: [WordDeck]

    @State private var showNewDeckSheet = false

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
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Desteler")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewDeckSheet = true
                    } label: {
                        Label("Yeni Deste", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewDeckSheet) {
                NewDeckSheet()
            }
            .task {
                WordDeck.bootstrapPresetsIfNeeded(in: context)
            }
        }
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

#Preview {
    DecksView()
        .modelContainer(PreviewData.container)
}
