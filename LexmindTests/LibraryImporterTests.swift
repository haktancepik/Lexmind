//
//  LibraryImporterTests.swift
//  LexmindTests
//
//  Coverage for `LibraryImporter` — the @ModelActor that bulk-inserts
//  library words off the main thread. Focus is on the two contracts the
//  rest of the app relies on:
//    • Each imported word with a CEFR level is bound to the matching
//      preset deck (so the Decks tab reflects the import immediately).
//    • A second pass over the same input is a no-op (idempotent), so a
//      user can re-tap "Bu desteyi ekle" without growing the deck or
//      duplicating Words / FSRSCards / WordRelations.
//

import Testing
import Foundation
import SwiftData
@testable import Lexmind

@MainActor
struct LibraryImporterTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: LexmindSchemaV2.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    /// Spin up an in-memory V2 container and pre-seed the six preset
    /// decks the way the live app does on Decks-tab appearance. Tests
    /// that exercise level binding rely on these existing.
    private func makeContainerWithPresets() throws -> ModelContainer {
        let container = try makeContainer()
        WordDeck.bootstrapPresetsIfNeeded(in: container.mainContext)
        return container
    }

    private func sampleWord(
        term: String,
        level: CEFRLevel? = nil
    ) -> LibraryImporter.ImportableWord {
        .init(
            term: term,
            partOfSpeech: "noun",
            ipa: "",
            countability: "",
            definition: "test definition",
            turkishMeaning: "test",
            examples: [],
            levelRaw: level?.rawValue,
            topicsRaw: [],
            familyRoot: nil,
            familyMembers: [],
            familyMembersVerified: [],
            inflectionExamples: [],
            synonyms: [],
            antonyms: [],
            related: []
        )
    }

    // MARK: - Level binding

    @Test func importBindsWordToMatchingPresetDeck() async throws {
        let container = try makeContainerWithPresets()
        let importer = LibraryImporter(modelContainer: container)

        let result = try await importer.importWords([
            sampleWord(term: "apple", level: .a1)
        ]) { _, _ in }

        #expect(result.added == 1)
        #expect(result.cancelled == false)

        let ctx = container.mainContext
        let apple = try ctx.fetch(FetchDescriptor<Word>(
            predicate: #Predicate { $0.term == "apple" }
        )).first
        #expect(apple?.decks.count == 1)
        #expect(apple?.decks.first?.presetLevelRaw == "A1")

        let a1Deck = try ctx.fetch(FetchDescriptor<WordDeck>(
            predicate: #Predicate { $0.presetLevelRaw == "A1" }
        )).first
        #expect(a1Deck?.words.count == 1)
        #expect(a1Deck?.words.first?.term == "apple")
    }

    @Test func importRoutesEachWordToOwnLevelDeck() async throws {
        let container = try makeContainerWithPresets()
        let importer = LibraryImporter(modelContainer: container)

        let result = try await importer.importWords([
            sampleWord(term: "apple", level: .a1),
            sampleWord(term: "book", level: .a2),
            sampleWord(term: "science", level: .b2)
        ]) { _, _ in }
        #expect(result.added == 3)

        let ctx = container.mainContext
        let decks = try ctx.fetch(FetchDescriptor<WordDeck>())
        var byLevel: [String: WordDeck] = [:]
        for deck in decks {
            if let raw = deck.presetLevelRaw { byLevel[raw] = deck }
        }
        #expect(byLevel["A1"]?.words.map(\.term).contains("apple") == true)
        #expect(byLevel["A2"]?.words.map(\.term).contains("book") == true)
        #expect(byLevel["B2"]?.words.map(\.term).contains("science") == true)
        // No cross-binding: a1 deck must not contain the a2 word.
        #expect(byLevel["A1"]?.words.map(\.term).contains("book") == false)
    }

    @Test func levellessWord_isNotBoundToAnyPresetDeck() async throws {
        let container = try makeContainerWithPresets()
        let importer = LibraryImporter(modelContainer: container)

        let result = try await importer.importWords([
            sampleWord(term: "ineffable", level: nil)
        ]) { _, _ in }
        #expect(result.added == 1)

        let ctx = container.mainContext
        let word = try ctx.fetch(FetchDescriptor<Word>()).first
        #expect(word?.decks.isEmpty == true)
    }

    @Test func importWithoutPresetDecks_stillInsertsWord() async throws {
        // No bootstrap — `presetByLevel` map is empty. The importer must
        // not crash and must still create the Word; it just can't bind.
        let container = try makeContainer()
        let importer = LibraryImporter(modelContainer: container)

        let result = try await importer.importWords([
            sampleWord(term: "apple", level: .a1)
        ]) { _, _ in }
        #expect(result.added == 1)

        let ctx = container.mainContext
        let apple = try ctx.fetch(FetchDescriptor<Word>()).first
        #expect(apple?.term == "apple")
        #expect(apple?.decks.isEmpty == true)
    }

    // MARK: - Idempotency

    @Test func secondImport_ofSameWord_addsNothing() async throws {
        let container = try makeContainerWithPresets()
        let importer = LibraryImporter(modelContainer: container)
        let payload = [sampleWord(term: "apple", level: .a1)]

        let first = try await importer.importWords(payload) { _, _ in }
        #expect(first.added == 1)

        let second = try await importer.importWords(payload) { _, _ in }
        #expect(second.added == 0)
        #expect(second.cancelled == false)

        let ctx = container.mainContext
        let words = try ctx.fetch(FetchDescriptor<Word>())
        #expect(words.count == 1)
        let a1Deck = try ctx.fetch(FetchDescriptor<WordDeck>(
            predicate: #Predicate { $0.presetLevelRaw == "A1" }
        )).first
        #expect(a1Deck?.words.count == 1)
    }

    @Test func secondImport_doesNotDuplicateCardsOrRelations() async throws {
        let container = try makeContainerWithPresets()
        let importer = LibraryImporter(modelContainer: container)
        let payload: [LibraryImporter.ImportableWord] = [
            .init(
                term: "apple",
                partOfSpeech: "noun",
                ipa: "",
                countability: "",
                definition: "fruit",
                turkishMeaning: "elma",
                examples: [],
                levelRaw: "A1",
                topicsRaw: [],
                familyRoot: nil,
                familyMembers: [],
                familyMembersVerified: [],
                inflectionExamples: [],
                synonyms: [.init(term: "fruit", verified: true)],
                antonyms: [],
                related: [.init(term: "tree", verified: false)]
            )
        ]

        _ = try await importer.importWords(payload) { _, _ in }
        _ = try await importer.importWords(payload) { _, _ in }

        let ctx = container.mainContext
        #expect(try ctx.fetch(FetchDescriptor<Word>()).count == 1)
        #expect(try ctx.fetch(FetchDescriptor<FSRSCard>()).count == 1)
        #expect(try ctx.fetch(FetchDescriptor<WordRelation>()).count == 2)
    }

    @Test func mixedPayload_onlyNewWordsAdded() async throws {
        let container = try makeContainerWithPresets()
        let importer = LibraryImporter(modelContainer: container)

        _ = try await importer.importWords([
            sampleWord(term: "apple", level: .a1)
        ]) { _, _ in }

        let second = try await importer.importWords([
            sampleWord(term: "apple", level: .a1),
            sampleWord(term: "book", level: .a2)
        ]) { _, _ in }
        #expect(second.added == 1)

        let ctx = container.mainContext
        let words = try ctx.fetch(FetchDescriptor<Word>()).map(\.term).sorted()
        #expect(words == ["apple", "book"])
    }

    // MARK: - Misc contracts

    @Test func emptyPayload_returnsZeroAdded() async throws {
        let container = try makeContainerWithPresets()
        let importer = LibraryImporter(modelContainer: container)

        let result = try await importer.importWords([]) { _, _ in
            Issue.record("progress callback should not fire on empty input")
        }
        #expect(result.added == 0)
        #expect(result.cancelled == false)
    }

    @Test func progressCallback_reportsRunningTotal() async throws {
        let container = try makeContainerWithPresets()
        let importer = LibraryImporter(modelContainer: container)

        let reports = Reports()
        _ = try await importer.importWords([
            sampleWord(term: "apple", level: .a1),
            sampleWord(term: "book", level: .a2),
            sampleWord(term: "science", level: .b2)
        ], batchSize: 1) { done, term in
            reports.append(done: done, term: term)
        }

        #expect(reports.dones == [1, 2, 3])
        #expect(reports.terms == ["apple", "book", "science"])
    }

    @MainActor
    private final class Reports {
        var dones: [Int] = []
        var terms: [String] = []
        func append(done: Int, term: String) {
            dones.append(done)
            terms.append(term)
        }
    }
}
