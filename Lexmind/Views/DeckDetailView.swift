//
//  DeckDetailView.swift
//  Lexmind
//
//  Deck-scoped word list. Reads `deck.words` directly so the list reacts
//  to membership changes. Row layout intentionally mirrors WordsListView
//  for visual consistency; deck-management toolbar actions (rename,
//  delete, merge, "Bu desteyi çalış") land in later 1.6 slices.
//

import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Bindable var deck: WordDeck
    @State private var searchText = ""

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
                        ? "Bu seviyede henüz kelime yok. Hazır Kütüphane'den ekleyebilirsin."
                        : "Bu desteye henüz kelime eklemedin.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredWords) { word in
                    NavigationLink {
                        WordDetailView(word: word)
                    } label: {
                        row(for: word)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Kelime ara")
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
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

#Preview {
    NavigationStack {
        DeckDetailView(deck: WordDeck(name: "Önizleme"))
    }
    .modelContainer(PreviewData.container)
}
