//
//  StudySession.swift
//  Lexmind
//
//  Drives a single Study run. Owns the queue, the current card, the
//  reveal flag, and the count of reviews completed during the session.
//  Pulled out of StudyView so the schedule/grade/advance loop is
//  testable without lifting the whole UI, and so the view body only
//  has to read `@Observable` properties instead of juggling six
//  `@State` vars.
//

import Foundation
import SwiftData
import SwiftUI

/// State + scheduling logic for one Study session. View constructs it,
/// hands it the visible word pool plus the daily review limit, and from
/// then on just reacts to its published properties.
@MainActor
@Observable
final class StudySession {

    // MARK: Observable state

    /// Cards still waiting in this session, in display order.
    var queue: [Word] = []

    /// The card currently on screen. `nil` once the queue empties.
    var current: Word?

    /// Whether the back of the current card has been flipped.
    var revealed = false

    /// Count of grades the user has submitted this session.
    var sessionReviewed = 0

    /// Wall-clock when the queue was last (re)built. Reserved for future
    /// session-length analytics; not consumed by the view yet.
    var sessionStartedAt: Date = .now

    // MARK: Dependencies

    private let scheduler = FSRSScheduler()

    // MARK: Queue construction

    /// Builds the queue from a word pool. No-op if the queue already
    /// holds cards — call `rebuildQueue(from:reviewLimit:)` to force a
    /// fresh queue (e.g. after the user switches active decks).
    func buildQueue(from pool: [Word], reviewLimit: Int) {
        guard queue.isEmpty else { return }
        let limit = max(reviewLimit, 1)

        let due = pool
            .filter { ($0.card?.state ?? .new) != .new && ($0.card?.isDue ?? false) }
            .sorted { ($0.card?.due ?? .now) < ($1.card?.due ?? .now) }
            .prefix(limit)

        let news = pool
            .filter { ($0.card?.state ?? .new) == .new }
            .sorted { $0.createdAt < $1.createdAt }

        queue = Array(due) + Array(news)
        sessionStartedAt = .now
        current = queue.first
    }

    /// Resets all in-flight state and rebuilds against the new pool.
    /// Session counters reset so progress reflects the new scope only.
    func rebuildQueue(from pool: [Word], reviewLimit: Int) {
        queue.removeAll()
        current = nil
        revealed = false
        sessionReviewed = 0
        buildQueue(from: pool, reviewLimit: reviewLimit)
    }

    // MARK: User actions

    /// Flips the current card to show its answer.
    func reveal() {
        revealed = true
    }

    /// Schedules + persists the current card under the given rating and
    /// advances to the next queued card. Re-queues cards still due
    /// within the next 15 minutes (learning steps).
    func grade(_ rating: ReviewRating, in context: ModelContext) {
        guard let word = current, let card = word.card else { return }
        let result = scheduler.schedule(card: card, rating: rating)
        let log = ReviewLog(
            rating: rating,
            scheduledDays: result.scheduledDays,
            elapsedDays: result.elapsedDays,
            state: result.state
        )
        log.word = word
        word.reviewLogs.append(log)
        scheduler.apply(result: result, to: card)
        word.lastStudiedAt = result.lastReview
        sessionReviewed += 1
        try? context.save()
        advance()
    }

    private func advance() {
        revealed = false
        let finished = current
        queue.removeAll { $0 === finished }
        if let finished, let card = finished.card,
           card.due <= Date().addingTimeInterval(15 * 60) {
            queue.append(finished)
        }
        current = queue.first
    }

    // MARK: Preview helpers

    /// Human-readable interval (e.g. "10dk", "<1g", "5g", "2ay", "1y")
    /// the card would land on if the user picked `rating` right now.
    func previewInterval(for word: Word, rating: ReviewRating) -> String {
        guard let card = word.card else { return "" }
        let result = scheduler.schedule(card: card, rating: rating)
        if result.scheduledDays <= 0 {
            return Self.previewMinutes(for: rating)
        } else if result.scheduledDays < 1 {
            return "<1g"
        } else if result.scheduledDays < 30 {
            return "\(Int(result.scheduledDays))g"
        } else if result.scheduledDays < 365 {
            return "\(Int(result.scheduledDays / 30))ay"
        } else {
            return "\(Int(result.scheduledDays / 365))y"
        }
    }

    static func previewMinutes(for rating: ReviewRating) -> String {
        switch rating {
        case .again: return "1dk"
        case .hard:  return "6dk"
        case .good:  return "10dk"
        case .easy:  return "1g"
        }
    }
}
