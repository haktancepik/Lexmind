//
//  HomeModel.swift
//  Lexmind
//
//  Pure business logic for HomeView — derives due/new/reviewed metrics,
//  streak count, next-due slice, and greeting from injected SwiftData
//  query results. Lives outside the View so the formulas can be unit
//  tested without spinning up a SwiftUI host.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class HomeModel {
    var words: [Word] = []
    var goals: [DailyGoal] = []
    var reviewLogs: [ReviewLog] = []

    /// Snapshot the latest SwiftData query results into the model so the
    /// derived metrics below recompute against fresh data.
    func sync(words: [Word], goals: [DailyGoal], reviewLogs: [ReviewLog]) {
        self.words = words
        self.goals = goals
        self.reviewLogs = reviewLogs
    }

    /// Stateless helper so callers can guarantee a `DailyGoal` exists
    /// without having to construct + sync a model first.
    static func ensureGoalExists(currentGoals: [DailyGoal], in context: ModelContext) {
        guard currentGoals.isEmpty else { return }
        context.insert(DailyGoal())
        try? context.save()
    }

    /// Hour-injectable greeting variant so unit tests don't depend on
    /// the system clock.
    static func greeting(forHour hour: Int) -> String {
        switch hour {
        case 5..<12: return "Günaydın 👋"
        case 12..<17: return "İyi günler 👋"
        case 17..<22: return "İyi akşamlar 👋"
        default: return "Merhaba 👋"
        }
    }

    // MARK: - Derived metrics

    var goal: DailyGoal { goals.first ?? DailyGoal() }

    var dueCount: Int {
        words.filter { ($0.card?.isDue ?? true) }.count
    }

    var newCount: Int {
        words.filter { ($0.card?.state ?? .new) == .new }.count
    }

    var reviewedTodayCount: Int {
        let cal = Calendar.current
        return reviewLogs.filter { cal.isDateInToday($0.reviewedAt) }.count
    }

    /// Consecutive days (including today) with at least one review log.
    var streak: Int {
        guard !reviewLogs.isEmpty else { return 0 }
        let cal = Calendar.current
        var streakDays = 0
        var cursor = Date()
        let logsByDay = Dictionary(grouping: reviewLogs) { cal.startOfDay(for: $0.reviewedAt) }
        while logsByDay[cal.startOfDay(for: cursor)] != nil {
            streakDays += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streakDays
    }

    var nextDueWords: [Word] {
        words
            .filter { $0.card != nil }
            .sorted { ($0.card?.due ?? .now) < ($1.card?.due ?? .now) }
            .prefix(5)
            .map { $0 }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        return Self.greeting(forHour: hour)
    }
}
