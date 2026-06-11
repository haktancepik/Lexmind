//
//  LexmindSchema.swift
//  Lexmind
//
//  Versioned schemas + migration plan. Two schemas live here today:
//    • V1 — initial 6 models.
//    • V2 — adds `WordDeck` and the `Word.decks` inverse so users can
//      organise their library into preset (per-CEFR-level) and custom
//      decks. V1 → V2 stage seeds six preset decks and binds existing
//      Word rows to their level's preset.
//

import Foundation
import SwiftData

/// Initial shipped schema. Add new models here only if they were also
/// part of the very first App Store release. New work goes into a new
/// `LexmindSchemaV2` (etc.) so the migration plan can describe the diff.
enum LexmindSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            Word.self,
            FSRSCard.self,
            ReviewLog.self,
            DailyGoal.self,
            WordRelation.self,
            DailyReadingPassage.self
        ]
    }
}

/// V2 adds `WordDeck` and the many-to-many `Word.decks` inverse. The
/// model types themselves are shared with V1 — the only schema diff is
/// the new `WordDeck` table and the new join. Version bump triggers the
/// custom stage that seeds preset decks.
enum LexmindSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            Word.self,
            FSRSCard.self,
            ReviewLog.self,
            DailyGoal.self,
            WordRelation.self,
            DailyReadingPassage.self,
            WordDeck.self
        ]
    }
}

/// Migration plan. Each shipped schema is listed in `schemas` (oldest
/// first) and consecutive pairs get a `MigrationStage` in `stages`.
enum LexmindMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [LexmindSchemaV1.self, LexmindSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [v1ToV2]
    }

    /// Custom stage so we can run a `didMigrate` that:
    ///   1. Creates six preset decks (`A1`..`C2`, `isPreset = true`).
    ///   2. Binds every existing `Word` to the preset deck matching its
    ///      `levelRaw`. Words without a level stay unattached — the user
    ///      can assign them to a custom deck later.
    /// `willMigrate` is nil because the V1 store already contains
    /// everything we need; we only seed *after* the schema is in place.
    static let v1ToV2 = MigrationStage.custom(
        fromVersion: LexmindSchemaV1.self,
        toVersion: LexmindSchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            var presetByLevel: [String: WordDeck] = [:]
            for (idx, level) in CEFRLevel.allCases.enumerated() {
                let deck = WordDeck(
                    name: level.rawValue,
                    isPreset: true,
                    presetLevel: level,
                    sortOrder: idx
                )
                context.insert(deck)
                presetByLevel[level.rawValue] = deck
            }

            let allWords = try context.fetch(FetchDescriptor<Word>())
            for word in allWords {
                guard
                    let raw = word.levelRaw,
                    let deck = presetByLevel[raw]
                else { continue }
                deck.words.append(word)
            }

            try context.save()
        }
    )
}
