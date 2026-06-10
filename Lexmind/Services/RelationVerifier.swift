//
//  RelationVerifier.swift
//  Lexmind
//

import Foundation
import NaturalLanguage

@Observable
final class RelationVerifier {
    private let client: DatamuseClient

    /// Most recent network failure surfaced by Datamuse, or `nil` if the last
    /// verification completed without any retryable error. Views observe this
    /// to show an "offline" badge with a Retry button.
    var lastError: DatamuseError? = nil

    /// `true` while an `applyVerifiedRelations` call is in flight. Views show
    /// a "Doğrulanıyor…" spinner badge next to relations / family while this
    /// is on so the user knows verification is still happening.
    var isVerifying: Bool = false

    init(client: DatamuseClient = .shared) {
        self.client = client
    }

    func clearError() {
        lastError = nil
    }

    func applyVerifiedRelations(to word: Word, from analysis: WordAnalysis) async {
        await applyVerifiedRelations(
            to: word,
            term: word.term,
            synonyms: analysis.synonyms,
            antonyms: analysis.antonyms,
            related: analysis.related,
            familyMembers: analysis.familyMembers,
            familyRoot: analysis.familyRoot
        )
    }

    func applyVerifiedRelations(to word: Word,
                                term: String,
                                synonyms: [String],
                                antonyms: [String],
                                related: [String],
                                familyMembers: [String],
                                familyRoot: String?) async {
        isVerifying = true
        defer { isVerifying = false }

        async let synResult = client.terms(for: term, endpoint: .synonyms)
        async let antResult = client.terms(for: term, endpoint: .antonyms)
        async let relResult = client.terms(for: term, endpoint: .related)
        let (synRaw, antRaw, relRaw) = await (synResult, antResult, relResult)

        let (s, sErr) = unpack(synRaw)
        let (a, aErr) = unpack(antRaw)
        let (r, rErr) = unpack(relRaw)

        word.relations.removeAll()
        appendRelations(.synonym, ai: synonyms, verified: s, into: word)
        appendRelations(.antonym, ai: antonyms, verified: a, into: word)
        appendRelations(.related, ai: related,  verified: r, into: word)

        let root = (familyRoot ?? "").lowercased()
        let normalizedMembers = familyMembers.map { $0.lowercased() }
        let (verified, famErr) = await verifyFamilyMembers(normalizedMembers, root: root)
        word.familyMembersVerifiedRaw = verified

        lastError = sErr ?? aErr ?? rErr ?? famErr
    }

    /// Re-runs verification using the current relation/family state stored on
    /// `word`. Used by the offline-badge Retry button.
    func retryVerification(for word: Word) async {
        let syns = word.relations.filter { $0.kind == .synonym }.map(\.targetTerm)
        let ants = word.relations.filter { $0.kind == .antonym }.map(\.targetTerm)
        let rels = word.relations.filter { $0.kind == .related  }.map(\.targetTerm)
        await applyVerifiedRelations(
            to: word,
            term: word.term,
            synonyms: syns,
            antonyms: ants,
            related: rels,
            familyMembers: word.familyMembers,
            familyRoot: word.familyRoot
        )
    }

    private func unpack(_ result: Result<Set<String>, DatamuseError>) -> (Set<String>, DatamuseError?) {
        switch result {
        case .success(let set): return (set, nil)
        case .failure(let err): return ([], err)
        }
    }

    private func appendRelations(_ kind: RelationKind,
                                 ai: [String],
                                 verified: Set<String>,
                                 into word: Word) {
        for raw in ai {
            let term = raw.lowercased().trimmingCharacters(in: .whitespaces)
            guard !term.isEmpty else { continue }
            let origin: RelationSource = verified.contains(term) ? .verified : .ai
            let relation = WordRelation(kind: kind,
                                        targetTerm: term,
                                        origin: origin,
                                        source: word)
            word.relations.append(relation)
        }
    }

    private func verifyFamilyMembers(_ members: [String], root: String) async -> ([String], DatamuseError?) {
        guard !root.isEmpty, !members.isEmpty else { return ([], nil) }

        let tagger = NLTagger(tagSchemes: [.lemma])
        let lemmaRoot = lemma(of: root, tagger: tagger)
        let prefixLen = min(3, root.count)
        let rootPrefix = String(root.prefix(prefixLen))

        var verified: [String] = []
        var firstError: DatamuseError?

        await withTaskGroup(of: (String, Result<Bool, DatamuseError>).self) { group in
            for m in members {
                group.addTask { [client] in
                    let result = await client.wordExists(m)
                    return (m, result)
                }
            }
            for await (m, result) in group {
                switch result {
                case .success(true):
                    if sharesFamily(m, rootPrefix: rootPrefix, lemmaRoot: lemmaRoot, tagger: tagger) {
                        verified.append(m)
                    }
                case .success(false):
                    continue
                case .failure(let err):
                    if firstError == nil { firstError = err }
                }
            }
        }
        return (verified, firstError)
    }

    private func sharesFamily(_ member: String,
                              rootPrefix: String,
                              lemmaRoot: String,
                              tagger: NLTagger) -> Bool {
        let lemmaMember = lemma(of: member, tagger: tagger)
        if !lemmaMember.isEmpty, lemmaMember == lemmaRoot { return true }
        guard !rootPrefix.isEmpty else { return false }
        return member.hasPrefix(rootPrefix)
    }

    private func lemma(of term: String, tagger: NLTagger) -> String {
        tagger.string = term
        var result = ""
        tagger.enumerateTags(in: term.startIndex..<term.endIndex,
                             unit: .word,
                             scheme: .lemma) { tag, _ in
            if let value = tag?.rawValue { result = value.lowercased() }
            return false
        }
        return result
    }
}
