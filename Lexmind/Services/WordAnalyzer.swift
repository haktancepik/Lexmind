//
//  WordAnalyzer.swift
//  Lexmind
//

import Foundation
import FoundationModels

@Generable(description: "Detailed linguistic analysis of an English word")
struct WordAnalysis: Equatable {
    @Guide(description: "The English part of speech, e.g. noun, verb, adjective, adverb")
    var partOfSpeech: String

    @Guide(description: "IPA pronunciation enclosed in slashes, e.g. /ˈhɛloʊ/")
    var ipa: String

    @Guide(description: "Countability: countable, uncountable, both, or N/A if not a noun")
    var countability: String

    @Guide(description: "A concise English definition of the word")
    var definition: String

    @Guide(description: "Turkish translation of the word")
    var turkishMeaning: String

    @Guide(description: "Five distinct natural example sentences that use the word", .count(5))
    var examples: [String]

    @Guide(description: "Optimal CEFR level (A1, A2, B1, B2, C1, or C2) for this word")
    var cefrLevel: String

    @Guide(description: "Topics this word belongs to from: daily, work, travel, academic, technology, business, health, emotions, food, nature, general", .count(1...3))
    var topics: [String]

    @Guide(description: "Up to 5 common English synonyms (lowercase, single words preferred)", .count(0...5))
    var synonyms: [String]

    @Guide(description: "Up to 3 common English antonyms (lowercase). Empty if word has no clear antonym.", .count(0...3))
    var antonyms: [String]

    @Guide(description: "Up to 4 related/associated English words (lowercase)", .count(0...4))
    var related: [String]

    @Guide(description: "The canonical root form of this word (e.g. 'create' for 'creation'). Empty if word is already the root or has no family.")
    var familyRoot: String

    @Guide(description: "Up to 6 derived forms in the same family (e.g. for 'create': created, creating, creation, creative). Lowercase.", .count(0...6))
    var familyMembers: [String]

    @Guide(description: "Three example sentences. EACH sentence must use a DIFFERENT inflected/derived form of the word (e.g. for 'create': one with 'created' past tense, one with 'creating' gerund, one with 'creation' noun). Do not repeat the same form.", .count(3))
    var inflectionExamples: [String]
}

@Generable(description: "Compact analysis used for the quick-lookup popover")
struct QuickWordAnalysis: Equatable {
    @Guide(description: "English part of speech, single word (noun/verb/adjective/...)")
    var partOfSpeech: String

    @Guide(description: "IPA pronunciation in slashes, e.g. /ˈhɛloʊ/")
    var ipa: String

    @Guide(description: "Concise English definition")
    var definition: String

    @Guide(description: "Short idiomatic Turkish translation")
    var turkishMeaning: String

    @Guide(description: "Canonical root form, empty if the word IS the root or has no family")
    var familyRoot: String

    @Guide(description: "Up to 4 derived forms in the same family. Empty array if none.", .count(0...4))
    var familyMembers: [String]

    @Guide(description: "Two short example sentences. Each MUST use a different inflected/derived form (e.g. past tense, gerund, noun derivation).", .count(2))
    var inflectionExamples: [String]
}

enum WordAnalyzerError: LocalizedError {
    case modelUnavailable(String)
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelUnavailable(let reason): return "Yapay zeka modeli kullanılamıyor: \(reason)"
        case .generationFailed(let reason): return "Analiz başarısız: \(reason)"
        }
    }
}

@Observable
final class WordAnalyzer {
    private let model = SystemLanguageModel.default

    var availabilityMessage: String? {
        switch model.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "Bu cihaz Apple Intelligence'i desteklemiyor."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Lütfen Ayarlar'dan Apple Intelligence'i etkinleştirin."
        case .unavailable(.modelNotReady):
            return "Yapay zeka modeli henüz hazır değil, indiriliyor olabilir."
        case .unavailable:
            return "Yapay zeka şu anda kullanılamıyor."
        }
    }

    var isAvailable: Bool {
        if case .available = model.availability { return true }
        return false
    }

    func analyze(term: String) async throws -> WordAnalysis {
        guard isAvailable else {
            throw WordAnalyzerError.modelUnavailable(availabilityMessage ?? "bilinmeyen sebep")
        }

        let session = LanguageModelSession {
            "You are an English vocabulary tutor for Turkish learners."
            "Given an English word, produce a precise linguistic analysis."
            "Always return the IPA in /slashes/."
            "Part of speech must be a single English word (noun/verb/adjective/adverb/preposition/etc.)."
            "Countability applies only to nouns; for non-nouns return N/A."
            "The five 'examples' should use the base form naturally; do not force varied inflections there."
            "For 'inflectionExamples', each of the three sentences must use a distinct family member (past tense / gerund / noun derivation / comparative / etc.) — never repeat the same form."
            "Turkish meaning must be a short, idiomatic Turkish translation."
            "Provide synonyms/antonyms/related and word family only when meaningful; return empty arrays otherwise."
        }

        do {
            let response = try await session.respond(
                to: "Analyze the English word: \"\(term)\"",
                generating: WordAnalysis.self
            )
            return response.content
        } catch {
            throw WordAnalyzerError.generationFailed(error.localizedDescription)
        }
    }

    func streamQuick(term: String) -> AsyncThrowingStream<QuickWordAnalysis.PartiallyGenerated, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                guard isAvailable else {
                    continuation.finish(throwing: WordAnalyzerError.modelUnavailable(availabilityMessage ?? "bilinmeyen sebep"))
                    return
                }
                let session = LanguageModelSession {
                    "You are an English vocabulary tutor for Turkish learners."
                    "Given an English word, produce a compact analysis suitable for a quick-look popover."
                    "Always return IPA in /slashes/."
                    "Part of speech must be a single English word (noun/verb/adjective/adverb/preposition/etc.)."
                    "Turkish meaning must be a short, idiomatic Turkish translation — single phrase, no parentheses."
                    "Family: if the word is the root, return empty familyRoot. Members must be real derived forms."
                    "Each inflectionExample must use a DIFFERENT family member; never repeat the same form."
                }
                do {
                    let stream = session.streamResponse(
                        to: "Analyze the English word: \"\(term)\"",
                        generating: QuickWordAnalysis.self
                    )
                    for try await snapshot in stream {
                        continuation.yield(snapshot.content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: WordAnalyzerError.generationFailed(error.localizedDescription))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
