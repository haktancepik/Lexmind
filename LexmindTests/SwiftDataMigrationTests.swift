//
//  SwiftDataMigrationTests.swift
//  LexmindTests
//
//  Smoke tests for the versioned-schema setup in `LexmindSchema.swift`.
//  These guard against accidental schema/migration regressions before V2
//  exists; once a V2 lands, real V1 → V2 migration tests should be added
//  alongside these.
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

    // MARK: - SchemaMigrationPlan setup

    @Test func migrationPlan_currentlyContainsOnlyV1() {
        let names = LexmindMigrationPlan.schemas.map { String(describing: $0) }
        #expect(names == ["LexmindSchemaV1"])
    }

    @Test func migrationPlan_hasNoStagesYet() {
        // Single-version plan needs no stages; once V2 ships this expectation
        // should be updated to assert exactly one .lightweight (or .custom)
        // stage describing the V1 → V2 transition.
        #expect(LexmindMigrationPlan.stages.isEmpty)
    }

    // MARK: - Container wiring

    @Test func v1Container_buildsWithMigrationPlan_andAcceptsInsert() throws {
        let schema = Schema(versionedSchema: LexmindSchemaV1.self)
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

        let word = Word(term: "schemaCheck")
        context.insert(word)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Word>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.term == "schemacheck")
    }
}
