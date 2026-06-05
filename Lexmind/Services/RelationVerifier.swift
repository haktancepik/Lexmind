//
//  RelationVerifier.swift
//  Lexmind
//

import Foundation
import NaturalLanguage

final class RelationVerifier {
    private let client: DatamuseClient

    init(client: DatamuseClient = .shared) {
        self.client = client
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
        async let synSet = client.terms(for: term, endpoint: .synonyms)
        async let antSet = client.terms(for: term, endpoint: .antonyms)
        async let relSet = client.terms(for: term, endpoint: .related)
        let (s, a, r) = await (synSet, antSet, relSet)

        word.relations.removeAll()
        appendRelations(.synonym, ai: synonyms, verified: s, into: word)
        appendRelations(.antonym, ai: antonyms, verified: a, into: word)
        appendRelations(.related, ai: related,  verified: r, into: word)

        let root = (familyRoot ?? "").lowercased()
        let normalizedMembers = familyMembers.map { $0.lowercased() }
        word.familyMembersVerifiedRaw = await verifyFamilyMembers(normalizedMembers, root: root)
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

    private func verifyFamilyMembers(_ members: [String], root: String) async -> [String] {
        guard !root.isEmpty, !members.isEmpty else { return [] }
        var verified: [String] = []
        await withTaskGroup(of: (String, Bool).self) { group in
            for m in members {
                group.addTask { [client] in
                    let exists = await client.wordExists(m)
                    return (m, exists)
                }
            }
            for await (m, exists) in group where exists {
                if sharesFamily(m, root: root) {
                    verified.append(m)
                }
            }
        }
        return verified
    }

    private func sharesFamily(_ member: String, root: String) -> Bool {
        let lemmaMember = lemma(of: member)
        let lemmaRoot = lemma(of: root)
        if !lemmaMember.isEmpty, lemmaMember == lemmaRoot { return true }
        let prefixLength = min(3, root.count)
        guard prefixLength > 0 else { return false }
        return member.hasPrefix(String(root.prefix(prefixLength)))
    }

    private func lemma(of term: String) -> String {
        let tagger = NLTagger(tagSchemes: [.lemma])
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
