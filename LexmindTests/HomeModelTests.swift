//
//  HomeModelTests.swift
//  LexmindTests
//
//  Unit tests for `HomeModel` — the @Observable layer that feeds
//  HomeView's hero/stats/upcoming cards. We exercise each derived
//  metric formula in isolation plus the two stateless static helpers
//  (`ensureGoalExists`, `greeting(forHour:)`).
//

import Testing
import Foundation
import SwiftData
@testable import Lexmind

@MainActor
struct HomeModelTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Word.self, FSRSCard.self, ReviewLog.self,
                 DailyGoal.self, WordRelation.self, DailyReadingPassage.self,
                 WordDeck.self,
            configurations: config
        )
    }

    /// Creates and inserts a `Word`; optionally attaches a card with a
    /// given state + due offset (seconds from now). A `nil` cardState
    /// means no card is attached at all.
    @discardableResult
    private func makeWord(
        term: String,
        cardState: CardState? = .new,
        dueOffset: TimeInterval = 0,
        in context: ModelContext
    ) -> Word {
        let word = Word(term: term)
        context.insert(word)
        if let state = cardState {
            let card = FSRSCard(
                state: state,
                due: Date().addingTimeInterval(dueOffset)
            )
            context.insert(card)
            word.card = card
            card.word = word
        }
        return word
    }

    @discardableResult
    private func makeLog(daysAgo: Int, hour: Int = 12, in context: ModelContext) -> ReviewLog {
        let cal = Calendar.current
        let base = cal.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let dayStart = cal.startOfDay(for: base)
        let when = cal.date(byAdding: .hour, value: hour, to: dayStart) ?? base
        let log = ReviewLog(
            rating: .good,
            scheduledDays: 1,
            elapsedDays: 0,
            state: .review,
            reviewedAt: when
        )
        context.insert(log)
        return log
    }

    // MARK: - goal

    @Test func goal_emptyGoals_returnsDefault() throws {
        let model = HomeModel()
        #expect(model.goal.newCardsPerDay == 10)
        #expect(model.goal.reviewsPerDay == 50)
    }

    @Test func goal_returnsFirstWhenPresent() throws {
        let model = HomeModel()
        let custom = DailyGoal(newCardsPerDay: 7, reviewsPerDay: 33)
        model.sync(words: [], goals: [custom], reviewLogs: [])
        #expect(model.goal.newCardsPerDay == 7)
        #expect(model.goal.reviewsPerDay == 33)
    }

    // MARK: - dueCount

    @Test func dueCount_emptyWords_isZero() throws {
        let model = HomeModel()
        #expect(model.dueCount == 0)
    }

    @Test func dueCount_wordWithoutCard_countsAsDue() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let w = makeWord(term: "apple", cardState: nil, in: ctx)
        let model = HomeModel()
        model.sync(words: [w], goals: [], reviewLogs: [])
        #expect(model.dueCount == 1)
    }

    @Test func dueCount_onlyOverdueCardsCounted() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let overdue = makeWord(term: "apple", dueOffset: -3600, in: ctx)
        let future = makeWord(term: "banana", dueOffset: 86_400, in: ctx)
        let model = HomeModel()
        model.sync(words: [overdue, future], goals: [], reviewLogs: [])
        #expect(model.dueCount == 1)
    }

    // MARK: - newCount

    @Test func newCount_wordWithoutCard_countsAsNew() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let w = makeWord(term: "apple", cardState: nil, in: ctx)
        let model = HomeModel()
        model.sync(words: [w], goals: [], reviewLogs: [])
        #expect(model.newCount == 1)
    }

    @Test func newCount_onlyNewStateCounted() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let new = makeWord(term: "apple", cardState: .new, in: ctx)
        let learning = makeWord(term: "banana", cardState: .learning, in: ctx)
        let review = makeWord(term: "cherry", cardState: .review, in: ctx)
        let model = HomeModel()
        model.sync(words: [new, learning, review], goals: [], reviewLogs: [])
        #expect(model.newCount == 1)
    }

    // MARK: - reviewedTodayCount

    @Test func reviewedTodayCount_emptyLogs_isZero() throws {
        let model = HomeModel()
        #expect(model.reviewedTodayCount == 0)
    }

    @Test func reviewedTodayCount_countsOnlyToday() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let today1 = makeLog(daysAgo: 0, hour: 9, in: ctx)
        let today2 = makeLog(daysAgo: 0, hour: 14, in: ctx)
        let yesterday = makeLog(daysAgo: 1, in: ctx)
        let model = HomeModel()
        model.sync(words: [], goals: [], reviewLogs: [today1, today2, yesterday])
        #expect(model.reviewedTodayCount == 2)
    }

    // MARK: - streak

    @Test func streak_emptyLogs_isZero() throws {
        let model = HomeModel()
        #expect(model.streak == 0)
    }

    @Test func streak_singleTodayLog_isOne() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let log = makeLog(daysAgo: 0, in: ctx)
        let model = HomeModel()
        model.sync(words: [], goals: [], reviewLogs: [log])
        #expect(model.streak == 1)
    }

    @Test func streak_consecutiveDays_counts() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let logs = [
            makeLog(daysAgo: 0, in: ctx),
            makeLog(daysAgo: 1, in: ctx),
            makeLog(daysAgo: 2, in: ctx)
        ]
        let model = HomeModel()
        model.sync(words: [], goals: [], reviewLogs: logs)
        #expect(model.streak == 3)
    }

    @Test func streak_gapBreaksCount() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        // today + skip 1 + then day 2 ago is missing → only today counts
        let logs = [
            makeLog(daysAgo: 0, in: ctx),
            makeLog(daysAgo: 2, in: ctx)
        ]
        let model = HomeModel()
        model.sync(words: [], goals: [], reviewLogs: logs)
        #expect(model.streak == 1)
    }

    @Test func streak_onlyPastNotToday_isZero() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let log = makeLog(daysAgo: 1, in: ctx)
        let model = HomeModel()
        model.sync(words: [], goals: [], reviewLogs: [log])
        #expect(model.streak == 0)
    }

    // MARK: - nextDueWords

    @Test func nextDueWords_excludesNilCards() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let withCard = makeWord(term: "apple", dueOffset: 60, in: ctx)
        let withoutCard = makeWord(term: "banana", cardState: nil, in: ctx)
        let model = HomeModel()
        model.sync(words: [withCard, withoutCard], goals: [], reviewLogs: [])
        #expect(model.nextDueWords.count == 1)
        #expect(model.nextDueWords.first?.term == "apple")
    }

    @Test func nextDueWords_sortedByDueAscending() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let later = makeWord(term: "cherry", dueOffset: 7200, in: ctx)
        let soon = makeWord(term: "apple", dueOffset: 60, in: ctx)
        let mid = makeWord(term: "banana", dueOffset: 3600, in: ctx)
        let model = HomeModel()
        model.sync(words: [later, soon, mid], goals: [], reviewLogs: [])
        #expect(model.nextDueWords.map(\.term) == ["apple", "banana", "cherry"])
    }

    @Test func nextDueWords_cappedAtFive() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        var words: [Word] = []
        for i in 0..<8 {
            words.append(makeWord(term: "w\(i)", dueOffset: TimeInterval(i * 60), in: ctx))
        }
        let model = HomeModel()
        model.sync(words: words, goals: [], reviewLogs: [])
        #expect(model.nextDueWords.count == 5)
    }

    // MARK: - greeting (static, hour-injected)

    @Test func greeting_morning() {
        #expect(HomeModel.greeting(forHour: 8) == "Günaydın 👋")
    }

    @Test func greeting_noon() {
        #expect(HomeModel.greeting(forHour: 12) == "İyi günler 👋")
    }

    @Test func greeting_evening() {
        #expect(HomeModel.greeting(forHour: 19) == "İyi akşamlar 👋")
    }

    @Test func greeting_nightFallback() {
        #expect(HomeModel.greeting(forHour: 2) == "Merhaba 👋")
    }

    @Test func greeting_lateNightUpperBound() {
        #expect(HomeModel.greeting(forHour: 22) == "Merhaba 👋")
    }

    // MARK: - ensureGoalExists

    @Test func ensureGoalExists_emptyGoals_inserts() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        HomeModel.ensureGoalExists(currentGoals: [], in: ctx)
        let stored = try ctx.fetch(FetchDescriptor<DailyGoal>())
        #expect(stored.count == 1)
        #expect(stored.first?.reviewsPerDay == 50)
    }

    @Test func ensureGoalExists_existingGoal_noop() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let existing = DailyGoal(newCardsPerDay: 5, reviewsPerDay: 20)
        ctx.insert(existing)
        try ctx.save()
        HomeModel.ensureGoalExists(currentGoals: [existing], in: ctx)
        let stored = try ctx.fetch(FetchDescriptor<DailyGoal>())
        #expect(stored.count == 1)
        #expect(stored.first?.reviewsPerDay == 20)
    }

    // MARK: - sync

    @Test func sync_replacesAllFields() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let w1 = makeWord(term: "apple", in: ctx)
        let g1 = DailyGoal()
        ctx.insert(g1)
        let l1 = makeLog(daysAgo: 0, in: ctx)
        let model = HomeModel()
        model.sync(words: [w1], goals: [g1], reviewLogs: [l1])
        #expect(model.words.count == 1)
        #expect(model.goals.count == 1)
        #expect(model.reviewLogs.count == 1)

        // Second sync wipes the previous snapshot.
        model.sync(words: [], goals: [], reviewLogs: [])
        #expect(model.words.isEmpty)
        #expect(model.goals.isEmpty)
        #expect(model.reviewLogs.isEmpty)
    }
}
