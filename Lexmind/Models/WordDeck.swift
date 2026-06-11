//
//  WordDeck.swift
//  Lexmind
//
//  User-facing grouping for `Word`s. Two flavors share one table:
//    • Preset decks — auto-created by V1→V2 migration (and at first run on
//      fresh installs) for each CEFR level, identified by `isPreset == true`
//      and `presetLevel != nil`. UI gates rename/delete on these.
//    • User decks — created freely from the Decks tab, can be renamed,
//      deleted, or merged. `presetLevel` is always nil.
//
//  Membership is many-to-many. The inverse lives here so `Word.decks` is a
//  bare `[WordDeck]` field on the Word side. Default delete rule (.nullify)
//  is exactly what we want: deleting a deck must NOT delete its words, and
//  deleting a word must drop it from every deck's membership list.
//

import Foundation
import SwiftData

@Model
final class WordDeck {
    @Attribute(.unique) var id: UUID
    var name: String
    var isPreset: Bool
    var presetLevelRaw: String?
    var createdAt: Date
    var sortOrder: Int

    @Relationship(inverse: \Word.decks)
    var words: [Word] = []

    var presetLevel: CEFRLevel? {
        get { presetLevelRaw.flatMap { CEFRLevel(rawValue: $0) } }
        set { presetLevelRaw = newValue?.rawValue }
    }

    init(
        name: String,
        isPreset: Bool = false,
        presetLevel: CEFRLevel? = nil,
        sortOrder: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.isPreset = isPreset
        self.presetLevelRaw = presetLevel?.rawValue
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    /// Idempotently seeds the six CEFR preset decks. The V1→V2 migration
    /// handles existing installs; this helper covers fresh installs and
    /// any future case where a preset was somehow deleted. Safe to call
    /// on every Decks-tab appearance.
    @MainActor
    static func bootstrapPresetsIfNeeded(in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<WordDeck>(
            predicate: #Predicate { $0.isPreset == true }
        ))) ?? []
        let existingLevels = Set(existing.compactMap { $0.presetLevelRaw })
        var didInsert = false
        for (idx, level) in CEFRLevel.allCases.enumerated() {
            guard !existingLevels.contains(level.rawValue) else { continue }
            context.insert(WordDeck(
                name: level.rawValue,
                isPreset: true,
                presetLevel: level,
                sortOrder: idx
            ))
            didInsert = true
        }
        if didInsert {
            try? context.save()
        }
    }
}
