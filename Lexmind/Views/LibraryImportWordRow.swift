//
//  LibraryImportWordRow.swift
//  Lexmind
//
//  Single library-word row in the Library Import list. Shows term +
//  POS, Turkish gloss, IPA, CEFR badge, topic icons, and a + / ✓ add
//  button on the trailing edge. Already-imported terms render the
//  filled check; freshly added terms briefly render the "Eklendi"
//  variant via `recentlyAdded`.
//

import SwiftUI

struct LibraryImportWordRow: View {
    let word: CommonWord
    let alreadyAdded: Bool
    let justAdded: Bool
    let onAdd: (CommonWord) -> Void

    var body: some View {
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
                    let tint = libraryImportCEFRColor(word.level)
                    Text(word.level.label)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(tint.opacity(0.18), in: Capsule())
                        .foregroundStyle(tint)
                    ForEach(word.topics, id: \.self) { tp in
                        Image(systemName: tp.symbol)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 8)

            Button {
                onAdd(word)
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
            .accessibilityLabel(Text(alreadyAdded ? "Ekli" : "Ekle"))
            .accessibilityHint(Text(alreadyAdded
                ? "Bu kelime zaten kütüphanende"
                : "\(word.term) kelimesini kütüphaneye ekler"))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
