//
//  ReadingPassageGenerator.swift
//  Lexmind
//

import Foundation
import FoundationModels
import os

@Generable(description: "A short coherent English reading passage practising a set of vocabulary words")
struct ReadingPassageGeneration: Equatable {
    @Guide(description: "Kısa, akılda kalıcı İngilizce başlık (maks. 8 kelime)")
    var title: String

    @Guide(description: "200-350 kelimelik tek parça, akıcı İngilizce metin. Verilen tüm kelimeler doğal şekilde geçmeli (çekimli formlar serbest). Liste/madde/başlık kullanma; düz nesir yaz. Türkçe kullanma.")
    var passage: String

    @Guide(description: "Metnin genel CEFR seviyesi: A1, A2, B1, B2, C1, veya C2")
    var cefrLevel: String
}

enum ReadingPassageError: LocalizedError {
    case modelUnavailable(String)
    case generationFailed(String)
    case noWords

    var errorDescription: String? {
        switch self {
        case .modelUnavailable(let reason): return "Yapay zeka modeli kullanılamıyor: \(reason)"
        case .generationFailed(let reason): return "Metin oluşturulamadı: \(reason)"
        case .noWords: return "Bugün için çalışılmış kelime yok."
        }
    }
}

@Observable
final class ReadingPassageGenerator {
    private let model = SystemLanguageModel.default

    static let maxWords = 15

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

    func generate(words: [Word]) async throws -> ReadingPassageGeneration {
        guard isAvailable else {
            throw ReadingPassageError.modelUnavailable(availabilityMessage ?? "bilinmeyen sebep")
        }
        let sample = Self.sampleRecent(words: words, limit: Self.maxWords)
        guard !sample.isEmpty else { throw ReadingPassageError.noWords }

        let signpostID = Signpost.ai.makeSignpostID()
        let state = Signpost.ai.beginInterval("generatePassage", id: signpostID, "words=\(sample.count)")
        defer { Signpost.ai.endInterval("generatePassage", state) }

        let session = LanguageModelSession {
            "You are an English tutor writing graded readers for Turkish learners."
            "Write ONE coherent English passage (200-350 words) that naturally uses every word in the provided list. Inflected forms are allowed."
            "Use simple sentence structures matching the target CEFR level."
            "Do not use bullets, lists, headings, or quotation blocks; flowing prose only."
            "English only — do not switch to Turkish."
        }

        do {
            let response = try await session.respond(
                to: Self.prompt(for: sample),
                generating: ReadingPassageGeneration.self
            )
            return response.content
        } catch {
            Log.ai.error("generatePassage failed: \(error.localizedDescription)")
            throw ReadingPassageError.generationFailed(error.localizedDescription)
        }
    }

    func stream(words: [Word]) -> AsyncThrowingStream<ReadingPassageGeneration.PartiallyGenerated, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                guard isAvailable else {
                    continuation.finish(throwing: ReadingPassageError.modelUnavailable(availabilityMessage ?? "bilinmeyen sebep"))
                    return
                }
                let sample = Self.sampleRecent(words: words, limit: Self.maxWords)
                guard !sample.isEmpty else {
                    continuation.finish(throwing: ReadingPassageError.noWords)
                    return
                }
                let session = LanguageModelSession {
                    "You are an English tutor writing graded readers for Turkish learners."
                    "Write ONE coherent English passage (200-350 words) using every provided word naturally. Inflected forms are allowed."
                    "Use sentence structures matching the requested CEFR level."
                    "English only — no bullets, lists, headings, or quotation blocks; flowing prose only."
                }
                do {
                    let stream = session.streamResponse(
                        to: Self.prompt(for: sample),
                        generating: ReadingPassageGeneration.self
                    )
                    for try await snapshot in stream {
                        continuation.yield(snapshot.content)
                    }
                    continuation.finish()
                } catch {
                    Log.ai.error("streamPassage failed: \(error.localizedDescription)")
                    continuation.finish(throwing: ReadingPassageError.generationFailed(error.localizedDescription))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    static func sampleRecent(words: [Word], limit: Int) -> [Word] {
        words
            .sorted { lhs, rhs in
                let l = lhs.reviewLogs.map(\.reviewedAt).max() ?? lhs.lastStudiedAt ?? .distantPast
                let r = rhs.reviewLogs.map(\.reviewedAt).max() ?? rhs.lastStudiedAt ?? .distantPast
                return l > r
            }
            .prefix(limit)
            .map { $0 }
    }

    private static func prompt(for words: [Word]) -> String {
        let dominant = dominantCEFR(in: words) ?? "B1"
        let lines = words.map { w -> String in
            let tr = w.turkishMeaning.isEmpty ? "" : " (TR: \(w.turkishMeaning))"
            let lv = w.level?.rawValue ?? "-"
            return "- \(w.term)\(tr) [CEFR \(lv)]"
        }.joined(separator: "\n")
        return """
        Target CEFR: \(dominant)
        Words to use (each at least once, inflections allowed):
        \(lines)
        """
    }

    private static func dominantCEFR(in words: [Word]) -> String? {
        let levels = words.compactMap { $0.level?.rawValue }
        guard !levels.isEmpty else { return nil }
        let counts = Dictionary(grouping: levels, by: { $0 }).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
