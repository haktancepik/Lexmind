//
//  ReadingFallbackBuilder.swift
//  Lexmind
//
//  Builds a structured "recap" view-model from the user's recently studied
//  words when Apple Intelligence is unavailable. Uses already-stored example
//  sentences, Turkish meanings, and CEFR levels so the Reading tab keeps
//  delivering value on devices without FoundationModels.
//

import Foundation

struct ReadingRecap: Equatable {
    struct Item: Equatable, Identifiable {
        let id: String
        let term: String
        let partOfSpeech: String
        let ipa: String
        let turkishMeaning: String
        let cefrLevel: CEFRLevel?
        let example: String?
    }

    let title: String
    let items: [Item]
    let dominantCEFR: CEFRLevel?
}

enum ReadingFallbackBuilder {

    static let maxItems = 12

    /// Builds a recap structure from recently studied words. Returns `nil` if
    /// there is nothing meaningful to show (no words with any usable content).
    static func build(from words: [Word],
                      limit: Int = maxItems,
                      now: Date = .now) -> ReadingRecap? {
        let sample = recentlyStudied(words: words, limit: limit, now: now)
        guard !sample.isEmpty else { return nil }

        let items: [ReadingRecap.Item] = sample.map { word in
            ReadingRecap.Item(
                id: word.term,
                term: word.term,
                partOfSpeech: word.partOfSpeech,
                ipa: word.ipa,
                turkishMeaning: word.turkishMeaning,
                cefrLevel: word.level,
                example: preferredExample(for: word)
            )
        }

        return ReadingRecap(
            title: "Bugünün Kelimeleri",
            items: items,
            dominantCEFR: dominantCEFR(in: sample)
        )
    }

    // MARK: - Helpers

    private static func recentlyStudied(words: [Word], limit: Int, now: Date) -> [Word] {
        words
            .sorted { lhs, rhs in
                let l = lhs.reviewLogs.map(\.reviewedAt).max() ?? lhs.lastStudiedAt ?? .distantPast
                let r = rhs.reviewLogs.map(\.reviewedAt).max() ?? rhs.lastStudiedAt ?? .distantPast
                return l > r
            }
            .prefix(limit)
            .map { $0 }
    }

    /// Prefers the first non-empty example; falls back to the first non-empty
    /// inflection example so the recap stays useful even on minimally-enriched
    /// words.
    private static func preferredExample(for word: Word) -> String? {
        if let first = word.examples.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            return first
        }
        if let inflected = word.inflectionExamples.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            return inflected
        }
        return nil
    }

    private static func dominantCEFR(in words: [Word]) -> CEFRLevel? {
        let levels = words.compactMap { $0.level }
        guard !levels.isEmpty else { return nil }
        let counts = Dictionary(grouping: levels, by: { $0 }).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
