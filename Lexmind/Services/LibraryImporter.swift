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
        let existing = (try? modelContext.fetch(FetchDescriptor<Word>())) ?? []
        let existingSet = Set(existing.map { $0.term.lowercased() })

        let candidates = words.filter { !existingSet.contains($0.term.lowercased()) }
        guard !candidates.isEmpty else {
            return ImportResult(added: 0, cancelled: false)
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

        return ImportResult(added: added, cancelled: false)
    }
}
