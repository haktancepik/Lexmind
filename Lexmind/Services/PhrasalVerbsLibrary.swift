//
//  PhrasalVerbsLibrary.swift
//  Lexmind
//
//  Loads the curated phrasal-verbs JSON (~195 entries) from a bundled
//  resource and exposes each one as a `CommonWord` so the existing
//  import + lookup UI can reuse it without changes.
//
//  Source data is produced by `scripts/parse_phrasal_verbs.py`, which
//  merges two upstream PDFs (AKIN Dil + YDS lists). Schema mirrors the
//  Oxford loader so this file can stay a near-clone of
//  `OxfordWordsLibrary`.
//

import Foundation
import os

private struct PhrasalVerbEntry: Decodable {
    let term: String
    let partOfSpeech: String
    let ipa: String?
    let countability: String?
    let definition: String?
    let turkishMeaning: String?
    let examples: [String]?
    let level: String
    let topics: [String]?
}

enum PhrasalVerbsLibrary {

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
            _ = PhrasalVerbsLibrary.all
        }.value
    }

    nonisolated private static func loadAll() -> [CommonWord] {
        let signpostID = Signpost.library.makeSignpostID()
        let state = Signpost.library.beginInterval("loadPhrasalVerbs", id: signpostID)
        defer { Signpost.library.endInterval("loadPhrasalVerbs", state) }

        guard let url = Bundle.main.url(forResource: "phrasalverbs", withExtension: "json") else {
            Log.library.fault("phrasalverbs.json not found in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let raw = try JSONDecoder().decode([PhrasalVerbEntry].self, from: data)
            let result = raw.compactMap(convert)
            Log.library.info("phrasalverbs.json decoded — \(result.count) entries")
            return result
        } catch {
            Log.library.error("phrasalverbs.json decode failed: \(error.localizedDescription)")
            return []
        }
    }

    nonisolated private static func convert(_ e: PhrasalVerbEntry) -> CommonWord? {
        guard let level = CEFRLevel(rawValue: e.level) else { return nil }
        let topics: [WordTopic]
        if let names = e.topics, !names.isEmpty {
            topics = names.compactMap { WordTopic(rawValue: $0) }
        } else {
            topics = [.general]
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
            familyRoot: nil,
            familyMembers: [],
            familyMembersVerified: [],
            inflectionExamples: [],
            synonyms: [],
            antonyms: [],
            related: []
        )
    }
}
