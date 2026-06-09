//
//  CommonWordsLibrary.swift
//  Lexmind
//
//  Curated set of frequently used English words with full analysis,
//  classified by CEFR level (A1–C2) and topic. Loaded from
//  Resources/common.json which is produced by
//  scripts/export_common_to_json.py and later enriched by
//  scripts/enrich_full.py (family/relations).
//

import Foundation

struct LibraryRelation: Hashable {
    let term: String
    let verified: Bool
}

struct CommonWord: Identifiable, Hashable {
    let id = UUID()
    let term: String
    let partOfSpeech: String
    let ipa: String
    let countability: String
    let definition: String
    let turkishMeaning: String
    let examples: [String]
    let level: CEFRLevel
    let topics: [WordTopic]
    let familyRoot: String?
    let familyMembers: [String]
    let familyMembersVerified: [String]
    let inflectionExamples: [String]
    let synonyms: [LibraryRelation]
    let antonyms: [LibraryRelation]
    let related: [LibraryRelation]

    init(
        term: String,
        partOfSpeech: String,
        ipa: String,
        countability: String,
        definition: String,
        turkishMeaning: String,
        examples: [String],
        level: CEFRLevel,
        topics: [WordTopic],
        familyRoot: String? = nil,
        familyMembers: [String] = [],
        familyMembersVerified: [String] = [],
        inflectionExamples: [String] = [],
        synonyms: [LibraryRelation] = [],
        antonyms: [LibraryRelation] = [],
        related: [LibraryRelation] = []
    ) {
        self.term = term
        self.partOfSpeech = partOfSpeech
        self.ipa = ipa
        self.countability = countability
        self.definition = definition
        self.turkishMeaning = turkishMeaning
        self.examples = examples
        self.level = level
        self.topics = topics
        self.familyRoot = familyRoot
        self.familyMembers = familyMembers
        self.familyMembersVerified = familyMembersVerified
        self.inflectionExamples = inflectionExamples
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.related = related
    }
}

enum CommonWordsLibrary {

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

    nonisolated private static func loadAll() -> [CommonWord] {
        guard let url = Bundle.main.url(forResource: "common", withExtension: "json") else {
            #if DEBUG
            print("[CommonWordsLibrary] common.json not found in bundle")
            #endif
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let raw = try JSONDecoder().decode([CommonWordEntry].self, from: data)
            return raw.compactMap(convert)
        } catch {
            #if DEBUG
            print("[CommonWordsLibrary] Failed to load: \(error)")
            #endif
            return []
        }
    }

    nonisolated private static func convert(_ e: CommonWordEntry) -> CommonWord? {
        guard let level = CEFRLevel(rawValue: e.level) else { return nil }
        let topics: [WordTopic]
        if let names = e.topics, !names.isEmpty {
            topics = names.compactMap { WordTopic(rawValue: $0) }
        } else {
            topics = [.general]
        }
        let mapRelations: ([CommonWordEntry.RelationEntry]?) -> [LibraryRelation] = { items in
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

private struct CommonWordEntry: Decodable {
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
