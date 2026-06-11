//
//  LexmindSchema.swift
//  Lexmind
//
//  Versioned schema + migration-plan skeleton. We only ship one shipped
//  schema today (V1), but wiring this in now means any future V2 only has
//  to add a new `VersionedSchema` enum and append a `MigrationStage` —
//  no scrambling at release time when the persistent store on existing
//  installs would otherwise be left to SwiftData's default fallback.
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

/// Migration plan skeleton. `stages` is empty while V1 is the only
/// shipped schema — SwiftData treats a single-version plan as a no-op.
/// When V2 lands, append it to `schemas` and add a `.lightweight` (or
/// `.custom`) stage describing the V1 → V2 transition.
enum LexmindMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [LexmindSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
