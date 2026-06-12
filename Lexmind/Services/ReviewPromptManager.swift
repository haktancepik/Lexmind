//
//  ReviewPromptManager.swift
//  Lexmind
//
//  Owns the heuristic for when to ask the user to rate the app via
//  SwiftUI's `RequestReviewAction`. App Store guideline 1.1.7 caps
//  prompts at 3/year per device, but Apple won't surface a prompt at
//  all if we ask too often — so we keep our own conservative gate:
//
//   • at least N successful study sessions completed
//   • at least 30 days since the last prompt we showed
//
//  All state lives in `@AppStorage` so it survives app re-launches but
//  resets on uninstall — appropriate for a UX nudge.
//

import Foundation
import SwiftUI

@MainActor
enum ReviewPromptManager {

    /// Minimum number of completed study sessions (≥1 graded card each)
    /// before we even consider asking. Tuning bias: under-ask. A new user
    /// hitting 3 productive sessions has signalled some real engagement.
    static let minSuccessfulSessions: Int = 3

    /// Throttle window between consecutive prompts.
    static let minDaysBetweenPrompts: Int = 30

    // MARK: - Storage keys
    //
    // Defined here as constants so `@AppStorage` callers and tests use
    // the same string literal.

    static let sessionCountKey = "reviewPrompt.successfulSessionCount"
    static let lastPromptKey = "reviewPrompt.lastShownAt"

    // MARK: - Public API

    /// Call from the Study session-completion handler with the number of
    /// cards the user just graded. Returns `true` when the caller should
    /// invoke the `@Environment(\.requestReview)` action — the manager
    /// will have already advanced its bookkeeping.
    @discardableResult
    static func registerCompletedSession(reviewedCount: Int) -> Bool {
        guard reviewedCount > 0 else { return false }

        let defaults = UserDefaults.standard
        let newCount = defaults.integer(forKey: sessionCountKey) + 1
        defaults.set(newCount, forKey: sessionCountKey)

        guard newCount >= minSuccessfulSessions else { return false }
        guard isOutsideThrottleWindow(now: .now, defaults: defaults) else { return false }

        defaults.set(Date(), forKey: lastPromptKey)
        return true
    }

    // MARK: - Internals (exposed `internal` so unit tests can drive them)

    static func isOutsideThrottleWindow(now: Date, defaults: UserDefaults) -> Bool {
        guard let last = defaults.object(forKey: lastPromptKey) as? Date else {
            return true
        }
        let interval = now.timeIntervalSince(last)
        return interval >= Double(minDaysBetweenPrompts) * 86_400
    }

    /// Test-only — wipes both counters back to default. Production code
    /// has no reason to call this.
    static func resetForTesting() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: sessionCountKey)
        defaults.removeObject(forKey: lastPromptKey)
    }
}
