//
//  SwiftDataMigrationTests.swift
//  LexmindTests
//
//  Smoke tests for the versioned-schema setup in `LexmindSchema.swift`.
//  Covers V1 + V2 metadata, plan wiring, and a V1→V2 round-trip that
//  exercises the `didMigrate` block — preset decks should be seeded and
//  existing words should be bound to the deck matching their CEFR level.
//

import Testing
import Foundation
import SwiftData
@testable import Lexmind

@MainActor
struct SwiftDataMigrationTests {

    // MARK: - VersionedSchema metadata

    @Test func v1Schema_versionIs_1_0_0() {
        #expect(LexmindSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
    }

    @Test func v1Schema_listsAllSixCoreModels() {
        let names = Set(LexmindSchemaV1.models.map { String(describing: $0) })
        #expect(names == [
            "Word",
            "FSRSCard",
            "ReviewLog",
            "DailyGoal",
            "WordRelation",
            "DailyReadingPassage"
        ])
    }

    @Test func v2Schema_versionIs_2_0_0() {
        #expect(LexmindSchemaV2.versionIdentifier == Schema.Version(2, 0, 0))
    }

    @Test func v2Schema_addsWordDeck_toV1Models() {
        let names = Set(LexmindSchemaV2.models.map { String(describing: $0) })
        #expect(names == [
            "Word",
            "FSRSCard",
            "ReviewLog",
            "DailyGoal",
            "WordRelation",
            "DailyReadingPassage",
            "WordDeck"
        ])
    }

    // MARK: - SchemaMigrationPlan setup

    @Test func migrationPlan_hasExactlyOneStage() {
        #expect(LexmindMigrationPlan.stages.count == 1)
    }

    @Test func migrationPlan_listsBothShippedSchemas() {
        let names = LexmindMigrationPlan.schemas.map { String(describing: $0) }
        #expect(names == ["LexmindSchemaV1", "LexmindSchemaV2"])
    }

    // MARK: - Container wiring

    @Test func v2Container_buildsWithMigrationPlan_andAcceptsInsert() throws {
        let schema = Schema(versionedSchema: LexmindSchemaV2.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            migrationPlan: LexmindMigrationPlan.self,
            configurations: [configuration]
        )
        let context = container.mainContext

        context.insert(Word(term: "schemaCheck"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Word>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.term == "schemacheck")
    }

    // MARK: - V1 → V2 round-trip
    //
    // SwiftData runs the migration plan when a persistent store written
    // with one VersionedSchema is opened under a newer one. We can't
    // observe that path in-memory, but we *can* exercise `didMigrate`
    // directly by handing it a V2 context pre-populated with V1-shaped
    // data — that's where the preset-deck seeding logic lives.

    @Test func v1ToV2_seedsSixPresetDecks_andBindsWordsByLevel() throws {
        let schema = Schema(versionedSchema: LexmindSchemaV2.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        let context = container.mainContext

        let apple = Word(term: "apple", level: .a1)
        let book = Word(term: "book", level: .a2)
        let science = Word(term: "science", level: .b2)
        let untagged = Word(term: "ineffable", level: nil)
        for w in [apple, book, science, untagged] { context.insert(w) }
        try context.save()

        guard case .custom(_, _, _, let didMigrate) = LexmindMigrationPlan.v1ToV2 else {
            Issue.record("v1ToV2 stage is not .custom")
            return
        }
        try didMigrate?(context)

        let decks = try context.fetch(FetchDescriptor<WordDeck>())
        #expect(decks.count == 6)
        #expect(decks.allSatisfy { $0.isPreset })

        var byLevel: [String: WordDeck] = [:]
        for deck in decks {
            if let raw = deck.presetLevelRaw {
                byLevel[raw] = deck
            }
        }
        #expect(byLevel["A1"]?.words.contains(where: { $0.term == "apple" }) == true)
        #expect(byLevel["A2"]?.words.contains(where: { $0.term == "book" }) == true)
        #expect(byLevel["B2"]?.words.contains(where: { $0.term == "science" }) == true)

        let untaggedFetched = try context.fetch(FetchDescriptor<Word>(
            predicate: #Predicate { $0.term == "ineffable" }
        )).first
        #expect(untaggedFetched?.decks.isEmpty == true)
    }
}
