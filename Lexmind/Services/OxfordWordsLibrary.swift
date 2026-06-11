//
//  OxfordWordsLibrary.swift
//  Lexmind
//
//  Loads the American Oxford 5000 (B2/C1 expansion) word set from a
//  bundled JSON resource and adapts each entry to `CommonWord` so the
//  existing import UI can reuse it without changes.
//
//  The bundled JSON is produced by `scripts/parse_oxford.py` followed by
//  `scripts/enrich_oxford.py` (one-time batch enrichment via Claude).
//

import Foundation
import os

private struct OxfordWordEntry: Decodable {
    let term: String
    let partOfSpeech: String
    let ipa: String?
    let countability: String?
    let definition: String?
    let turkishMeaning: String?
    let examples: [String]?
    let level: String
    let topics: [String]?
    let familyRoot: String?
    let familyMembers: [String]?
    let familyMembersVerified: [String]?
    let inflectionExamples: [String]?
    let synonyms: [RelationEntry]?
    let antonyms: [RelationEntry]?
    let related: [RelationEntry]?

    struct RelationEntry: Decodable {
        let term: String
        let verified: Bool
    }
}

enum OxfordWordsLibrary {

    static let all: [CommonWord] = loadAll()

    static let byTerm: [String: CommonWord] = {
        Dictionary(all.map { ($0.term.lowercased(), $0) },
                   uniquingKeysWith: { first, _ in first })
    }()

    static func find(_ term: String) -> CommonWord? {
        byTerm[term.lowercased()]
    }

    static func filtered(level: CEFRLevel? = nil, topic: WordTopic? = nil) -> [CommonWord] {
        all.filter { word in
            if let level, word.level != level { return false }
            if let topic, !word.topics.contains(topic) { return false }
            return true
        }
    }

    // MARK: - Loading

    /// Warms the lazy `static let all` initializer on a background task so the
    /// JSON decode does not block the calling (usually main) thread on first
    /// access. Idempotent — repeated calls return immediately.
    nonisolated static func preload() async {
        await Task.detached(priority: .utility) {
            _ = OxfordWordsLibrary.all
        }.value
    }

    nonisolated private static func loadAll() -> [CommonWord] {
        guard let url = Bundle.main.url(forResource: "oxford5000", withExtension: "json") else {
            Log.library.fault("oxford5000.json not found in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let raw = try JSONDecoder().decode([OxfordWordEntry].self, from: data)
            return raw.compactMap(convert)
        } catch {
            Log.library.error("oxford5000.json decode failed: \(error.localizedDescription)")
            return []
        }
    }

    nonisolated private static func convert(_ e: OxfordWordEntry) -> CommonWord? {
        guard let level = CEFRLevel(rawValue: e.level) else { return nil }
        let topics: [WordTopic]
        if let names = e.topics, !names.isEmpty {
            topics = names.compactMap { WordTopic(rawValue: $0) }
        } else {
            topics = [.general]
        }
        let mapRelations: ([OxfordWordEntry.RelationEntry]?) -> [LibraryRelation] = { items in
            (items ?? []).map { LibraryRelation(term: $0.term, verified: $0.verified) }
        }
        return CommonWord(
            term: e.term.lowercased(),
            partOfSpeech: e.partOfSpeech,
            ipa: e.ipa ?? "",
            countability: e.countability ?? "N/A",
            definition: e.definition ?? "",
            turkishMeaning: e.turkishMeaning ?? "",
            examples: e.examples ?? [],
            level: level,
            topics: topics.isEmpty ? [.general] : topics,
            familyRoot: e.familyRoot,
            familyMembers: e.familyMembers ?? [],
            familyMembersVerified: e.familyMembersVerified ?? [],
            inflectionExamples: e.inflectionExamples ?? [],
            synonyms: mapRelations(e.synonyms),
            antonyms: mapRelations(e.antonyms),
            related: mapRelations(e.related)
        )
    }
}
