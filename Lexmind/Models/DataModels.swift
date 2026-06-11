//
//  DataModels.swift
//  Lexmind
//

import Foundation
import SwiftData

enum CardState: Int, Codable, CaseIterable {
    case new = 0
    case learning = 1
    case review = 2
    case relearning = 3

    var label: String {
        switch self {
        case .new: return "Yeni"
        case .learning: return "Öğreniliyor"
        case .review: return "Tekrar"
        case .relearning: return "Yeniden"
        }
    }
}

enum CEFRLevel: String, Codable, CaseIterable, Identifiable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"
    case c2 = "C2"

    var id: String { rawValue }

    var label: String { rawValue }

    var tint: String {
        switch self {
        case .a1: return "green"
        case .a2: return "mint"
        case .b1: return "yellow"
        case .b2: return "orange"
        case .c1: return "red"
        case .c2: return "purple"
        }
    }
}

enum WordTopic: String, Codable, CaseIterable, Identifiable {
    case daily
    case work
    case travel
    case academic
    case technology
    case business
    case health
    case emotions
    case food
    case nature
    case general

    var id: String { rawValue }

    var label: String {
        switch self {
        case .daily: return "Günlük"
        case .work: return "İş"
        case .travel: return "Seyahat"
        case .academic: return "Akademik"
        case .technology: return "Teknoloji"
        case .business: return "İş Dünyası"
        case .health: return "Sağlık"
        case .emotions: return "Duygular"
        case .food: return "Yemek"
        case .nature: return "Doğa"
        case .general: return "Genel"
        }
    }

    var symbol: String {
        switch self {
        case .daily: return "house.fill"
        case .work: return "briefcase.fill"
        case .travel: return "airplane"
        case .academic: return "graduationcap.fill"
        case .technology: return "cpu"
        case .business: return "chart.line.uptrend.xyaxis"
        case .health: return "heart.fill"
        case .emotions: return "face.smiling"
        case .food: return "fork.knife"
        case .nature: return "leaf.fill"
        case .general: return "globe"
        }
    }
}

enum RelationKind: String, Codable, CaseIterable, Identifiable {
    case synonym
    case antonym
    case related

    var id: String { rawValue }

    var label: String {
        switch self {
        case .synonym: return "Eş Anlamlı"
        case .antonym: return "Zıt Anlamlı"
        case .related: return "İlgili"
        }
    }

    var symbol: String {
        switch self {
        case .synonym: return "equal.circle"
        case .antonym: return "arrow.left.arrow.right.circle"
        case .related: return "link.circle"
        }
    }
}

enum RelationSource: String, Codable {
    case verified
    case ai

    var symbol: String {
        switch self {
        case .verified: return "checkmark.seal.fill"
        case .ai:       return "sparkle"
        }
    }
}

enum ReviewRating: Int, Codable, CaseIterable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4

    var label: String {
        switch self {
        case .again: return "Tekrar"
        case .hard: return "Zor"
        case .good: return "İyi"
        case .easy: return "Kolay"
        }
    }

    var symbol: String {
        switch self {
        case .again: return "arrow.counterclockwise"
        case .hard: return "tortoise.fill"
        case .good: return "checkmark.circle.fill"
        case .easy: return "hare.fill"
        }
    }
}

@Model
final class Word {
    /// Lookup/storage key — always `trim + lowercased`. Enforced by `init` and
    /// `Word.normalize(_:)` so the unique constraint actually catches
    /// "Apple" vs "apple" duplicates.
    @Attribute(.unique) var term: String
    /// Original-cased, trimmed form of the user's input. `nil` for legacy
    /// records and library imports where casing is already canonical; views
    /// fall back to `term` via `displayName`.
    var displayTerm: String?
    var partOfSpeech: String
    var ipa: String
    var countability: String
    var definition: String
    var turkishMeaning: String
    var examples: [String]
    var notes: String
    var levelRaw: String?
    var topicsRaw: [String]
    var familyRoot: String?
    var familyMembersRaw: [String] = []
    var familyMembersVerifiedRaw: [String] = []
    var inflectionExamplesRaw: [String] = []
    var createdAt: Date
    var lastStudiedAt: Date?

    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var displayName: String {
        if let dt = displayTerm, !dt.isEmpty { return dt }
        return term
    }

    @Relationship(deleteRule: .cascade, inverse: \FSRSCard.word)
    var card: FSRSCard?

    @Relationship(deleteRule: .cascade, inverse: \ReviewLog.word)
    var reviewLogs: [ReviewLog] = []

    @Relationship(deleteRule: .cascade, inverse: \WordRelation.source)
    var relations: [WordRelation] = []

    /// Many-to-many membership; inverse declared on `WordDeck.words`.
    /// Default `.nullify` is intentional — deleting a deck must NOT delete
    /// its words, and deleting a word must drop it from every deck.
    var decks: [WordDeck] = []

    var level: CEFRLevel? {
        get { levelRaw.flatMap { CEFRLevel(rawValue: $0) } }
        set { levelRaw = newValue?.rawValue }
    }

    var topics: [WordTopic] {
        get { topicsRaw.compactMap { WordTopic(rawValue: $0) } }
        set { topicsRaw = newValue.map { $0.rawValue } }
    }

    var familyMembers: [String] {
        get { familyMembersRaw }
        set { familyMembersRaw = newValue.map { $0.lowercased() } }
    }

    func familySource(for member: String) -> RelationSource {
        familyMembersVerifiedRaw.contains(member.lowercased()) ? .verified : .ai
    }

    var inflectionExamples: [String] {
        get { inflectionExamplesRaw }
        set { inflectionExamplesRaw = newValue }
    }

    init(
        term: String,
        partOfSpeech: String = "",
        ipa: String = "",
        countability: String = "",
        definition: String = "",
        turkishMeaning: String = "",
        examples: [String] = [],
        notes: String = "",
        level: CEFRLevel? = nil,
        topics: [WordTopic] = [],
        familyRoot: String? = nil,
        familyMembers: [String] = [],
        inflectionExamples: [String] = [],
        createdAt: Date = .now
    ) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        self.term = trimmed.lowercased()
        // Only store a separate display form when the original casing differs
        // from the canonical (lowercased) key — keeps DB rows tidy for library
        // imports that already pass lowercase terms.
        self.displayTerm = (trimmed.isEmpty || trimmed == trimmed.lowercased()) ? nil : trimmed
        self.partOfSpeech = partOfSpeech
        self.ipa = ipa
        self.countability = countability
        self.definition = definition
        self.turkishMeaning = turkishMeaning
        self.examples = examples
        self.notes = notes
        self.levelRaw = level?.rawValue
        self.topicsRaw = topics.map { $0.rawValue }
        self.familyRoot = familyRoot
        self.familyMembersRaw = familyMembers.map { $0.lowercased() }
        self.inflectionExamplesRaw = inflectionExamples
        self.createdAt = createdAt
    }
}

@Model
final class WordRelation {
    var kindRaw: String
    var targetTerm: String
    var sourceRaw: String?
    var source: Word?
    var target: Word?
    var createdAt: Date

    var kind: RelationKind {
        get { RelationKind(rawValue: kindRaw) ?? .related }
        set { kindRaw = newValue.rawValue }
    }

    var origin: RelationSource {
        get { sourceRaw.flatMap(RelationSource.init) ?? .ai }
        set { sourceRaw = newValue.rawValue }
    }

    init(kind: RelationKind,
         targetTerm: String,
         origin: RelationSource = .ai,
         source: Word? = nil,
         target: Word? = nil) {
        self.kindRaw = kind.rawValue
        self.targetTerm = targetTerm.lowercased()
        self.sourceRaw = origin.rawValue
        self.source = source
        self.target = target
        self.createdAt = .now
    }
}

@Model
final class FSRSCard {
    var stability: Double
    var difficulty: Double
    var elapsedDays: Double
    var scheduledDays: Double
    var reps: Int
    var lapses: Int
    var stateRaw: Int
    var lastReview: Date?
    var due: Date

    var word: Word?

    var state: CardState {
        get { CardState(rawValue: stateRaw) ?? .new }
        set { stateRaw = newValue.rawValue }
    }

    var isDue: Bool {
        due <= .now
    }

    init(
        stability: Double = 0,
        difficulty: Double = 0,
        elapsedDays: Double = 0,
        scheduledDays: Double = 0,
        reps: Int = 0,
        lapses: Int = 0,
        state: CardState = .new,
        lastReview: Date? = nil,
        due: Date = .now
    ) {
        self.stability = stability
        self.difficulty = difficulty
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.reps = reps
        self.lapses = lapses
        self.stateRaw = state.rawValue
        self.lastReview = lastReview
        self.due = due
    }
}

@Model
final class ReviewLog {
    var ratingRaw: Int
    var scheduledDays: Double
    var elapsedDays: Double
    var stateRaw: Int
    var reviewedAt: Date

    var word: Word?

    var rating: ReviewRating {
        ReviewRating(rawValue: ratingRaw) ?? .good
    }

    var state: CardState {
        CardState(rawValue: stateRaw) ?? .new
    }

    init(
        rating: ReviewRating,
        scheduledDays: Double,
        elapsedDays: Double,
        state: CardState,
        reviewedAt: Date = .now
    ) {
        self.ratingRaw = rating.rawValue
        self.scheduledDays = scheduledDays
        self.elapsedDays = elapsedDays
        self.stateRaw = state.rawValue
        self.reviewedAt = reviewedAt
    }
}

@Model
final class DailyGoal {
    @Attribute(.unique) var id: String
    var newCardsPerDay: Int
    var reviewsPerDay: Int

    init(newCardsPerDay: Int = 10, reviewsPerDay: Int = 50) {
        self.id = "default"
        self.newCardsPerDay = newCardsPerDay
        self.reviewsPerDay = reviewsPerDay
    }
}

@Model
final class DailyReadingPassage {
    @Attribute(.unique) var id: UUID
    var date: Date
    var title: String
    var passageText: String
    var cefrLevel: String
    var wordTermsRaw: [String]
    var createdAt: Date

    var wordTerms: [String] {
        get { wordTermsRaw }
        set { wordTermsRaw = newValue.map { $0.lowercased() } }
    }

    init(date: Date,
         title: String,
         passageText: String,
         cefrLevel: String,
         wordTerms: [String],
         createdAt: Date = .now) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.title = title
        self.passageText = passageText
        self.cefrLevel = cefrLevel
        self.wordTermsRaw = wordTerms.map { $0.lowercased() }
        self.createdAt = createdAt
    }
}
