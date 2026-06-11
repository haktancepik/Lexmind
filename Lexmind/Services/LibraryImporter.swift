//
//  LibraryImporter.swift
//  Lexmind
//
//  Background ModelActor that bulk-imports library words off the main
//  thread. Reports progress to a @MainActor callback and honors
//  cooperative cancellation between batches.
//

import Foundation
import SwiftData
import os

@ModelActor
actor LibraryImporter {

    struct ImportableWord: Sendable {
        let term: String
        let partOfSpeech: String
        let ipa: String
        let countability: String
        let definition: String
        let turkishMeaning: String
        let examples: [String]
        let levelRaw: String?
        let topicsRaw: [String]
        let familyRoot: String?
        let familyMembers: [String]
        let familyMembersVerified: [String]
        let inflectionExamples: [String]
        let synonyms: [Relation]
        let antonyms: [Relation]
        let related: [Relation]

        struct Relation: Sendable {
            let term: String
            let verified: Bool
        }
    }

    struct ImportResult: Sendable {
        let added: Int
        let cancelled: Bool
    }

    func importWords(
        _ words: [ImportableWord],
        batchSize: Int = 100,
        progress: @Sendable @MainActor (Int, String) -> Void
    ) async throws -> ImportResult {
        let signpostID = Signpost.importer.makeSignpostID()
        let state = Signpost.importer.beginInterval("importWords", id: signpostID, "total=\(words.count)")
        defer { Signpost.importer.endInterval("importWords", state) }

        let existing = (try? modelContext.fetch(FetchDescriptor<Word>())) ?? []
        let existingSet = Set(existing.map { $0.term.lowercased() })

        let candidates = words.filter { !existingSet.contains($0.term.lowercased()) }
        guard !candidates.isEmpty else {
            Log.importer.info("importWords skipped — 0 candidates after dedupe (input=\(words.count))")
            return ImportResult(added: 0, cancelled: false)
        }

        // Index preset decks by their CEFR raw so each new word can be
        // bound to the matching deck without a fetch per row. Decks are
        // re-fetched each call (cheap — 6 rows max) so a deck created
        // mid-session is picked up.
        let presetDecks = (try? modelContext.fetch(FetchDescriptor<WordDeck>(
            predicate: #Predicate { $0.isPreset == true }
        ))) ?? []
        var presetByLevel: [String: WordDeck] = [:]
        for deck in presetDecks {
            if let raw = deck.presetLevelRaw {
                presetByLevel[raw] = deck
            }
        }

        var added = 0
        var index = 0

        while index < candidates.count {
            if Task.isCancelled {
                return ImportResult(added: added, cancelled: true)
            }

            let end = min(index + batchSize, candidates.count)
            let slice = candidates[index..<end]
            var insertedInBatch = 0
            var lastTerm = ""
            var cancelledMidBatch = false

            for cw in slice {
                if insertedInBatch > 0 && insertedInBatch % 25 == 0 && Task.isCancelled {
                    cancelledMidBatch = true
                    break
                }
                let word = Word(
                    term: cw.term,
                    partOfSpeech: cw.partOfSpeech,
                    ipa: cw.ipa,
                    countability: cw.countability,
                    definition: cw.definition,
                    turkishMeaning: cw.turkishMeaning,
                    examples: cw.examples,
                    level: cw.levelRaw.flatMap(CEFRLevel.init(rawValue:)),
                    topics: cw.topicsRaw.compactMap(WordTopic.init(rawValue:)),
                    familyRoot: cw.familyRoot,
                    familyMembers: cw.familyMembers,
                    inflectionExamples: cw.inflectionExamples
                )
                word.familyMembersVerifiedRaw = cw.familyMembersVerified.map { $0.lowercased() }
                let card = FSRSCard()
                word.card = card
                card.word = word
                modelContext.insert(word)
                modelContext.insert(card)

                // Bind to the preset deck matching this word's CEFR level.
                // Idempotent: the candidate filter above already rules out
                // duplicates, so a freshly-inserted word can't already be
                // a member of any deck.
                if let raw = cw.levelRaw, let deck = presetByLevel[raw] {
                    deck.words.append(word)
                }

                for rel in cw.synonyms {
                    let r = WordRelation(
                        kind: .synonym,
                        targetTerm: rel.term,
                        origin: rel.verified ? .verified : .ai,
                        source: word
                    )
                    modelContext.insert(r)
                }
                for rel in cw.antonyms {
                    let r = WordRelation(
                        kind: .antonym,
                        targetTerm: rel.term,
                        origin: rel.verified ? .verified : .ai,
                        source: word
                    )
                    modelContext.insert(r)
                }
                for rel in cw.related {
                    let r = WordRelation(
                        kind: .related,
                        targetTerm: rel.term,
                        origin: rel.verified ? .verified : .ai,
                        source: word
                    )
                    modelContext.insert(r)
                }

                insertedInBatch += 1
                lastTerm = cw.term
            }

            if insertedInBatch > 0 {
                do {
                    try modelContext.save()
                } catch {
                    Log.importer.error("batch save failed at index=\(index), inserted=\(insertedInBatch): \(error.localizedDescription)")
                    modelContext.rollback()
                    throw error
                }
                added += insertedInBatch
                await progress(added, lastTerm)
            }

            if cancelledMidBatch {
                return ImportResult(added: added, cancelled: true)
            }

            index = end
        }

        Log.importer.info("importWords done — added=\(added), totalInput=\(words.count)")
        return ImportResult(added: added, cancelled: false)
    }
}
