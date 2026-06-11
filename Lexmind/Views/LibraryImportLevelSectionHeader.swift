//
//  LibraryImportLevelSectionHeader.swift
//  Lexmind
//
//  Header row above each CEFR-level section in the library list — CEFR
//  pill, word/new counters, and a tint-aware "Hepsini ekle" capsule
//  button that defers to the parent's import flow.
//

import SwiftUI

struct LibraryImportLevelSectionHeader: View {
    let level: CEFRLevel
    let words: [CommonWord]
    let existingTerms: Set<String>
    let isImporting: Bool
    let onImport: ([CommonWord]) -> Void

    var body: some View {
        let newCountInLevel = words.filter { !existingTerms.contains($0.term.lowercased()) }.count
        let tint = libraryImportCEFRColor(level)
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
                onImport(words)
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
            .disabled(newCountInLevel == 0 || isImporting)
        }
    }
}
