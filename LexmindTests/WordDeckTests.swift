//
//  WordDeckTests.swift
//  LexmindTests
//
//  Coverage for the `WordDeck` model and its many-to-many membership
//  with `Word`. Focus is on relationship plumbing (both sides in sync,
//  delete-rule behaviour) rather than UI — the Decks tab will get its
//  own UI tests later.
//

import Testing
import Foundation
import SwiftData
@testable import Lexmind

@MainActor
struct WordDeckTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Word.self, FSRSCard.self, ReviewLog.self,
                 DailyGoal.self, WordRelation.self, DailyReadingPassage.self,
                 WordDeck.self,
            configurations: config
        )
    }

    // MARK: - CRUD

    @Test func createDeck_persists() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        ctx.insert(WordDeck(name: "Seyahat"))
        try ctx.save()
        let fetched = try ctx.fetch(FetchDescriptor<WordDeck>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Seyahat")
        #expect(fetched.first?.isPreset == false)
        #expect(fetched.first?.presetLevel == nil)
    }

    @Test func presetDeck_storesLevel() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        ctx.insert(WordDeck(name: "A1", isPreset: true, presetLevel: .a1, sortOrder: 0))
        try ctx.save()
        let fetched = try ctx.fetch(FetchDescriptor<WordDeck>()).first
        #expect(fetched?.isPreset == true)
        #expect(fetched?.presetLevel == .a1)
        #expect(fetched?.presetLevelRaw == "A1")
    }

    // MARK: - Many-to-many

    @Test func addingWord_to_deck_setsBothSides() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let word = Word(term: "apple")
        let deck = WordDeck(name: "A1", isPreset: true, presetLevel: .a1)
        ctx.insert(word)
        ctx.insert(deck)
        deck.words.append(word)
        try ctx.save()

        let fetchedWord = try ctx.fetch(FetchDescriptor<Word>()).first
        let fetchedDeck = try ctx.fetch(FetchDescriptor<WordDeck>()).first
        #expect(fetchedDeck?.words.count == 1)
        #expect(fetchedWord?.decks.count == 1)
        #expect(fetchedWord?.decks.first?.id == fetchedDeck?.id)
    }

    @Test func removingWord_from_deck_clearsBackref() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let word = Word(term: "apple")
        let deck = WordDeck(name: "A1")
        ctx.insert(word)
        ctx.insert(deck)
        deck.words.append(word)
        try ctx.save()

        deck.words.removeAll()
        try ctx.save()

        let fetchedWord = try ctx.fetch(FetchDescriptor<Word>()).first
        #expect(fetchedWord?.decks.isEmpty == true)
    }

    @Test func wordInMultipleDecks() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let word = Word(term: "apple", level: .a1)
        let a1Deck = WordDeck(name: "A1", isPreset: true, presetLevel: .a1)
        let customDeck = WordDeck(name: "Yiyecekler")
        ctx.insert(word)
        ctx.insert(a1Deck)
        ctx.insert(customDeck)
        a1Deck.words.append(word)
        customDeck.words.append(word)
        try ctx.save()

        let fetchedWord = try ctx.fetch(FetchDescriptor<Word>()).first
        #expect(fetchedWord?.decks.count == 2)
    }

    // MARK: - Delete-rule semantics

    @Test func deletingDeck_doesNotDeleteWord() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let word = Word(term: "apple")
        let deck = WordDeck(name: "Custom")
        ctx.insert(word)
        ctx.insert(deck)
        deck.words.append(word)
        try ctx.save()

        ctx.delete(deck)
        try ctx.save()

        let words = try ctx.fetch(FetchDescriptor<Word>())
        let decks = try ctx.fetch(FetchDescriptor<WordDeck>())
        #expect(words.count == 1)
        #expect(decks.isEmpty)
        #expect(words.first?.decks.isEmpty == true)
    }

    @Test func deletingWord_removesFromDeck() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let word = Word(term: "apple")
        let deck = WordDeck(name: "Custom")
        ctx.insert(word)
        ctx.insert(deck)
        deck.words.append(word)
        try ctx.save()

        ctx.delete(word)
        try ctx.save()

        let fetchedDeck = try ctx.fetch(FetchDescriptor<WordDeck>()).first
        #expect(fetchedDeck?.words.isEmpty == true)
    }
}
