//
//  QuickLookupService.swift
//  Lexmind
//

import Foundation

@Observable
final class QuickLookupService {

    enum LookupResult {
        case existing(Word)
        case common(CommonWord)
        case ai(WordAnalysis)
        case partialAI(QuickWordAnalysis.PartiallyGenerated)

        var turkishMeaning: String {
            switch self {
            case .existing(let w): return w.turkishMeaning
            case .common(let c): return c.turkishMeaning
            case .ai(let a): return a.turkishMeaning
            case .partialAI(let p): return p.turkishMeaning ?? ""
            }
        }

        var definition: String {
            switch self {
            case .existing(let w): return w.definition
            case .common(let c): return c.definition
            case .ai(let a): return a.definition
            case .partialAI(let p): return p.definition ?? ""
            }
        }

        var partOfSpeech: String {
            switch self {
            case .existing(let w): return w.partOfSpeech
            case .common(let c): return c.partOfSpeech
            case .ai(let a): return a.partOfSpeech
            case .partialAI(let p): return p.partOfSpeech ?? ""
            }
        }

        var ipa: String {
            switch self {
            case .existing(let w): return w.ipa
            case .common(let c): return c.ipa
            case .ai(let a): return WordAnalyzer.sanitizeIPA(a.ipa)
            case .partialAI(let p): return WordAnalyzer.sanitizeIPA(p.ipa ?? "")
            }
        }

        var familyRoot: String {
            switch self {
            case .existing(let w): return w.familyRoot ?? ""
            case .common: return ""
            case .ai(let a): return a.familyRoot
            case .partialAI(let p): return p.familyRoot ?? ""
            }
        }

        var familyMembers: [String] {
            switch self {
            case .existing(let w): return w.familyMembers
            case .common: return []
            case .ai(let a): return a.familyMembers
            case .partialAI(let p): return (p.familyMembers ?? []).compactMap { $0 }
            }
        }

        var inflectionExamples: [String] {
            switch self {
            case .existing(let w): return w.inflectionExamples
            case .common: return []
            case .ai(let a): return a.inflectionExamples
            case .partialAI(let p): return (p.inflectionExamples ?? []).compactMap { $0 }
            }
        }

        /// `true` while AI is still streaming partial results. Card sections
        /// (family, inflection, …) treat empty fields as "still loading"
        /// instead of "no data" only while this is true.
        var isStreaming: Bool {
            if case .partialAI = self { return true }
            return false
        }
    }

    enum Phase {
        case idle
        case loading(term: String)
        case ready(term: String, result: LookupResult)
        case failed(term: String, message: String)
    }

    private(set) var phase: Phase = .idle
    private var cache: [String: LookupResult] = [:]
    private var currentRequestID = UUID()

    private let analyzer: WordAnalyzer

    init(analyzer: WordAnalyzer) {
        self.analyzer = analyzer
    }

    func normalize(_ term: String) -> String {
        var key = term.lowercased()
        if key.hasSuffix("'s") || key.hasSuffix("’s") {
            key = String(key.dropLast(2))
        }
        return key
    }

    /// Synchronously sets `phase` based on whatever can be resolved without an AI call.
    /// Returns `true` if a `.ready` result is set (no further work needed),
    /// `false` if `phase` is `.loading` and the caller should `await fetchFromAI(term:)`.
    @discardableResult
    func prime(term rawTerm: String, in allWords: [Word]) -> Bool {
        let key = normalize(rawTerm)
        guard !key.isEmpty else {
            phase = .idle
            return true
        }

        let requestID = UUID()
        currentRequestID = requestID

        // Live library always wins (covers freshly added words too).
        if let live = allWords.first(where: { $0.term == key }) {
            let result: LookupResult = .existing(live)
            cache[key] = result
            phase = .ready(term: key, result: result)
            return true
        }

        if let cached = cache[key] {
            phase = .ready(term: key, result: cached)
            return true
        }

        if let common = CommonWordsLibrary.find(key) {
            let result: LookupResult = .common(common)
            cache[key] = result
            phase = .ready(term: key, result: result)
            return true
        }

        if let oxford = OxfordWordsLibrary.find(key) {
            let result: LookupResult = .common(oxford)
            cache[key] = result
            phase = .ready(term: key, result: result)
            return true
        }

        phase = .loading(term: key)
        return false
    }

    func fetchFromAI(term rawTerm: String) async {
        let key = normalize(rawTerm)
        guard !key.isEmpty else { return }
        let requestID = currentRequestID

        if !analyzer.isAvailable {
            phase = .failed(
                term: key,
                message: analyzer.availabilityMessage
                    ?? "Bu kelime sözlüğümüzde yok ve cihaz Apple Intelligence'i desteklemiyor."
            )
            return
        }

        do {
            for try await partial in analyzer.streamQuick(term: key) {
                guard requestID == currentRequestID else { return }
                phase = .ready(term: key, result: .partialAI(partial))
            }
            guard requestID == currentRequestID else { return }
            if case .ready(_, let final) = phase {
                cache[key] = final
            }
        } catch {
            guard requestID == currentRequestID else { return }
            phase = .failed(term: key, message: error.localizedDescription)
        }
    }

    /// Convenience that primes synchronously and falls back to AI if needed.
    func lookup(term rawTerm: String, in allWords: [Word]) async {
        if prime(term: rawTerm, in: allWords) { return }
        await fetchFromAI(term: rawTerm)
    }

    func reset() {
        currentRequestID = UUID()
        phase = .idle
    }

    func invalidate(term: String) {
        cache[normalize(term)] = nil
    }
}
