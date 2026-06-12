//
//  BackupService.swift
//  Lexmind
//
//  JSON export/import for every user-generated row in the store. This
//  doubles as the GDPR "download my data" feature — the same payload
//  format covers both the manual backup workflow and the right-to-
//  export obligation.
//
//  Schema is intentionally explicit rather than encoding/decoding the
//  SwiftData @Model classes directly (SwiftData PersistentModel doesn't
//  conform to Codable, and even if it did, we want a stable on-disk
//  shape that survives schema migrations). Version is bumped any time
//  a field is removed or renamed; new optional fields can be added
//  without a bump.
//
//  Import policy: idempotent merge.
//    • Words: term is the natural key; existing rows are kept as-is,
//      payload rows with the same term are skipped (not overwritten).
//    • User decks: name is the natural key; preset decks come from the
//      schema bootstrap, never from the payload.
//    • DailyGoal: payload's first goal overwrites the existing one (a
//      device only has one goal at a time).
//    • DailyReadingPassage: excluded — cached AI output, regenerable.
//

import Foundation
import SwiftData
import os

@MainActor
struct BackupService {

    // MARK: - Schema

    static let currentVersion = 1

    struct Payload: Codable {
        let version: Int
        let exportedAt: Date
        let appVersion: String
        let words: [WordDTO]
        let goals: [GoalDTO]
        let decks: [DeckDTO]
    }

    struct WordDTO: Codable {
        let term: String
        let displayTerm: String?
        let partOfSpeech: String
        let ipa: String
        let countability: String
        let definition: String
        let turkishMeaning: String
        let examples: [String]
        let notes: String
        let levelRaw: String?
        let topicsRaw: [String]
        let familyRoot: String?
        let familyMembers: [String]
        let familyMembersVerified: [String]
        let inflectionExamples: [String]
        let createdAt: Date
        let lastStudiedAt: Date?
        let card: CardDTO?
        let relations: [RelationDTO]
        let logs: [LogDTO]
    }

    struct CardDTO: Codable {
        let stability: Double
        let difficulty: Double
        let elapsedDays: Double
        let scheduledDays: Double
        let reps: Int
        let lapses: Int
        let stateRaw: Int
        let lastReview: Date?
        let due: Date
    }

    struct RelationDTO: Codable {
        let kindRaw: String
        let targetTerm: String
        let sourceRaw: String?
        let createdAt: Date
    }

    struct LogDTO: Codable {
        let ratingRaw: Int
        let scheduledDays: Double
        let elapsedDays: Double
        let stateRaw: Int
        let reviewedAt: Date
    }

    struct GoalDTO: Codable {
        let newCardsPerDay: Int
        let reviewsPerDay: Int
    }

    struct DeckDTO: Codable {
        let name: String
        let isPreset: Bool
        let presetLevelRaw: String?
        let sortOrder: Int
        let createdAt: Date
        /// Lowercased Word.term values that belong to this deck.
        let wordTerms: [String]
    }

    enum BackupError: LocalizedError {
        case unsupportedVersion(Int)
        case decodeFailed(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedVersion(let v):
                return "Yedek dosyası bu sürümde desteklenmiyor (v\(v))."
            case .decodeFailed(let msg):
                return "Yedek dosyası okunamadı: \(msg)"
            }
        }
    }

    struct ImportSummary {
        let payloadVersion: Int
        let totalWordsInPayload: Int
        let newWords: Int
        let skippedExistingWords: Int
        let logsInPayload: Int
        let userDecksInPayload: Int
        let newUserDecks: Int
        let goalReplaced: Bool
    }

    // MARK: - Dependencies

    let context: ModelContext

    // MARK: - Export

    func export() throws -> Data {
        let words = try context.fetch(FetchDescriptor<Word>())
        let goals = try context.fetch(FetchDescriptor<DailyGoal>())
        let decks = try context.fetch(FetchDescriptor<WordDeck>(sortBy: [SortDescriptor(\.sortOrder)]))

        let wordDTOs = words.map { word -> WordDTO in
            WordDTO(
                term: word.term,
                displayTerm: word.displayTerm,
                partOfSpeech: word.partOfSpeech,
                ipa: word.ipa,
                countability: word.countability,
                definition: word.definition,
                turkishMeaning: word.turkishMeaning,
                examples: word.examples,
                notes: word.notes,
                levelRaw: word.levelRaw,
                topicsRaw: word.topicsRaw,
                familyRoot: word.familyRoot,
                familyMembers: word.familyMembersRaw,
                familyMembersVerified: word.familyMembersVerifiedRaw,
                inflectionExamples: word.inflectionExamplesRaw,
                createdAt: word.createdAt,
                lastStudiedAt: word.lastStudiedAt,
                card: word.card.map { card in
                    CardDTO(
                        stability: card.stability,
                        difficulty: card.difficulty,
                        elapsedDays: card.elapsedDays,
                        scheduledDays: card.scheduledDays,
                        reps: card.reps,
                        lapses: card.lapses,
                        stateRaw: card.stateRaw,
                        lastReview: card.lastReview,
                        due: card.due
                    )
                },
                relations: word.relations.map { rel in
                    RelationDTO(
                        kindRaw: rel.kindRaw,
                        targetTerm: rel.targetTerm,
                        sourceRaw: rel.sourceRaw,
                        createdAt: rel.createdAt
                    )
                },
                logs: word.reviewLogs.map { log in
                    LogDTO(
                        ratingRaw: log.ratingRaw,
                        scheduledDays: log.scheduledDays,
                        elapsedDays: log.elapsedDays,
                        stateRaw: log.stateRaw,
                        reviewedAt: log.reviewedAt
                    )
                }
            )
        }

        let goalDTOs = goals.map {
            GoalDTO(newCardsPerDay: $0.newCardsPerDay, reviewsPerDay: $0.reviewsPerDay)
        }

        let deckDTOs = decks.map { deck in
            DeckDTO(
                name: deck.name,
                isPreset: deck.isPreset,
                presetLevelRaw: deck.presetLevelRaw,
                sortOrder: deck.sortOrder,
                createdAt: deck.createdAt,
                wordTerms: deck.words.map { $0.term }
            )
        }

        let info = Bundle.main.infoDictionary
        let appVersion = (info?["CFBundleShortVersionString"] as? String) ?? "—"

        let payload = Payload(
            version: Self.currentVersion,
            exportedAt: .now,
            appVersion: appVersion,
            words: wordDTOs,
            goals: goalDTOs,
            decks: deckDTOs
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    // MARK: - Import

    /// Decodes and validates the payload. With `dryRun: true` no rows
    /// are written — the returned summary tells the UI exactly what
    /// will change so the user can confirm.
    @discardableResult
    func importPayload(data: Data, dryRun: Bool) throws -> ImportSummary {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let payload: Payload
        do {
            payload = try decoder.decode(Payload.self, from: data)
        } catch {
            throw BackupError.decodeFailed(error.localizedDescription)
        }

        guard payload.version <= Self.currentVersion else {
            throw BackupError.unsupportedVersion(payload.version)
        }

        let existingWords = try context.fetch(FetchDescriptor<Word>())
        let existingTermSet = Set(existingWords.map { $0.term.lowercased() })

        let existingDecks = try context.fetch(FetchDescriptor<WordDeck>())
        let existingUserDeckNames = Set(existingDecks.filter { !$0.isPreset }.map { $0.name })

        let newWordDTOs = payload.words.filter { !existingTermSet.contains($0.term.lowercased()) }
        let userDecksInPayload = payload.decks.filter { !$0.isPreset }
        let newUserDeckDTOs = userDecksInPayload.filter { !existingUserDeckNames.contains($0.name) }

        let summary = ImportSummary(
            payloadVersion: payload.version,
            totalWordsInPayload: payload.words.count,
            newWords: newWordDTOs.count,
            skippedExistingWords: payload.words.count - newWordDTOs.count,
            logsInPayload: payload.words.reduce(0) { $0 + $1.logs.count },
            userDecksInPayload: userDecksInPayload.count,
            newUserDecks: newUserDeckDTOs.count,
            goalReplaced: !payload.goals.isEmpty
        )

        guard !dryRun else { return summary }

        // Apply phase ----------------------------------------------------

        // Index Word inserts by lowercased term so deck membership can
        // be wired up after every Word is in place.
        var insertedWordByTerm: [String: Word] = [:]

        for dto in newWordDTOs {
            let word = Word(
                term: dto.term,
                partOfSpeech: dto.partOfSpeech,
                ipa: dto.ipa,
                countability: dto.countability,
                definition: dto.definition,
                turkishMeaning: dto.turkishMeaning,
                examples: dto.examples,
                notes: dto.notes,
                level: CEFRLevel(rawValueOrNil: dto.levelRaw),
                topics: dto.topicsRaw.compactMap(WordTopic.init(rawValue:)),
                familyRoot: dto.familyRoot,
                familyMembers: dto.familyMembers,
                inflectionExamples: dto.inflectionExamples,
                createdAt: dto.createdAt
            )
            word.displayTerm = dto.displayTerm
            word.familyMembersVerifiedRaw = dto.familyMembersVerified.map { $0.lowercased() }
            word.lastStudiedAt = dto.lastStudiedAt
            context.insert(word)

            if let cardDTO = dto.card {
                let card = FSRSCard(
                    stability: cardDTO.stability,
                    difficulty: cardDTO.difficulty,
                    elapsedDays: cardDTO.elapsedDays,
                    scheduledDays: cardDTO.scheduledDays,
                    reps: cardDTO.reps,
                    lapses: cardDTO.lapses,
                    state: CardState(rawValue: cardDTO.stateRaw) ?? .new,
                    lastReview: cardDTO.lastReview,
                    due: cardDTO.due
                )
                context.insert(card)
                word.card = card
                card.word = word
            }

            for relDTO in dto.relations {
                let rel = WordRelation(
                    kind: RelationKind(rawValue: relDTO.kindRaw) ?? .related,
                    targetTerm: relDTO.targetTerm,
                    origin: RelationSource(rawValue: relDTO.sourceRaw ?? "") ?? .ai,
                    source: word
                )
                rel.createdAt = relDTO.createdAt
                context.insert(rel)
            }

            for logDTO in dto.logs {
                let log = ReviewLog(
                    rating: ReviewRating(rawValue: logDTO.ratingRaw) ?? .good,
                    scheduledDays: logDTO.scheduledDays,
                    elapsedDays: logDTO.elapsedDays,
                    state: CardState(rawValue: logDTO.stateRaw) ?? .new,
                    reviewedAt: logDTO.reviewedAt
                )
                log.word = word
                context.insert(log)
            }

            insertedWordByTerm[dto.term.lowercased()] = word
        }

        // Existing words that also need to be findable for deck wiring.
        for word in existingWords {
            insertedWordByTerm[word.term.lowercased()] = word
        }

        // Apply payload's first goal to the existing DailyGoal singleton.
        if let goalDTO = payload.goals.first {
            let goals = try context.fetch(FetchDescriptor<DailyGoal>())
            if let target = goals.first {
                target.newCardsPerDay = goalDTO.newCardsPerDay
                target.reviewsPerDay = goalDTO.reviewsPerDay
            } else {
                context.insert(DailyGoal(
                    newCardsPerDay: goalDTO.newCardsPerDay,
                    reviewsPerDay: goalDTO.reviewsPerDay
                ))
            }
        }

        // New user decks: insert + bind member words by term.
        for dto in newUserDeckDTOs {
            let deck = WordDeck(
                name: dto.name,
                isPreset: false,
                presetLevel: nil,
                sortOrder: dto.sortOrder,
                createdAt: dto.createdAt
            )
            context.insert(deck)
            for term in dto.wordTerms {
                if let word = insertedWordByTerm[term.lowercased()] {
                    deck.words.append(word)
                }
            }
        }

        try context.save()
        Log.data.info("Backup applied — words +\(summary.newWords), decks +\(summary.newUserDecks)")
        return summary
    }
}

private extension CEFRLevel {
    init?(rawValueOrNil raw: String?) {
        guard let raw else { return nil }
        self.init(rawValue: raw)
    }
}
