//
//  StudyDeckPicker.swift
//  Lexmind
//
//  Capsule menu that lets the user scope the study session to a single
//  deck (or "Tümü" — the whole library). Pulled out of StudyView so
//  the same control can be reused by other study-launching surfaces
//  later without re-implementing the icon/label rules.
//

import SwiftUI

struct StudyDeckPicker: View {
    let decks: [WordDeck]
    let activeDeck: WordDeck?
    let onSelect: (WordDeck?) -> Void

    var body: some View {
        Menu {
            Button {
                onSelect(nil)
            } label: {
                Label("Tümü", systemImage: activeDeck == nil
                      ? "checkmark"
                      : "books.vertical")
            }
            if !decks.isEmpty {
                Divider()
                ForEach(decks) { deck in
                    Button {
                        onSelect(deck)
                    } label: {
                        Label(deck.name,
                              systemImage: activeDeck?.id == deck.id
                                ? "checkmark"
                                : (deck.isPreset ? "graduationcap" : "rectangle.stack"))
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label).font(.caption.bold())
                Image(systemName: "chevron.down").font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.12), in: Capsule())
            .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal)
    }

    private var label: String { activeDeck?.name ?? "Tümü" }

    private var icon: String {
        guard let activeDeck else { return "books.vertical.fill" }
        return activeDeck.isPreset ? "graduationcap.fill" : "rectangle.stack.fill"
    }
}
