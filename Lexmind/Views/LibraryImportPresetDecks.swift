//
//  LibraryImportPresetDecks.swift
//  Lexmind
//
//  Top "Hazır Desteler" section on the Library Import screen — six
//  CEFR tiles (A1..C2) showing the total + new-word count for each
//  level. Tapping a tile bulk-imports that level into the matching
//  preset deck.
//

import SwiftUI

struct LibraryImportPresetDecks: View {
    let existingTerms: Set<String>
    let isImporting: Bool
    let onTapLevel: ([CommonWord]) -> Void

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8),
                      GridItem(.flexible(), spacing: 8),
                      GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ForEach(CEFRLevel.allCases) { lv in
                tile(for: lv)
            }
        }
        .padding(.vertical, 4)
    }

    private func tile(for level: CEFRLevel) -> some View {
        let words = MergedLibrary.filtered(level: level, topic: nil)
        let newCount = words.filter { !existingTerms.contains($0.term.lowercased()) }.count
        let tint = libraryImportCEFRColor(level)
        return Button {
            onTapLevel(words)
        } label: {
            VStack(spacing: 4) {
                Text(level.label)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(tint)
                Text("\(words.count) kelime")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(newCount == 0 ? "Tamamlandı" : "\(newCount) yeni")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(newCount == 0 ? Color.secondary : tint)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(newCount == 0 ? 0.06 : 0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(tint.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(newCount == 0 || isImporting)
    }
}
