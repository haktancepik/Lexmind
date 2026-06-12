//
//  FSRSSchedulerTests.swift
//  LexmindTests
//
//  Tests for `FSRSScheduler` — the FSRS-5 spaced repetition algorithm that
//  drives every card's next due date, stability, and difficulty.
//
//  Property-style tests dominate here (state transitions, invariants,
//  ordering) so weights can be tuned later without rewriting golden
//  values. A few exact-value tests anchor the initial-stability formula.
//

import Testing
import Foundation
import SwiftData
@testable import Lexmind

@MainActor
struct FSRSSchedulerTests {

    // MARK: - Fixtures
    //
    // The container is owned by the test struct so it outlives every
    // helper-returned `FSRSCard`. Returning a card from a helper that
    // owned its container locally would crash with
    // "model instance was destroyed" the moment the helper returned,
    // because ARC tore down the in-memory container.

    let container: ModelContainer

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Word.self, FSRSCard.self, ReviewLog.self,
                 DailyGoal.self, WordRelation.self, DailyReadingPassage.self,
            configurations: config
        )
    }

    private func makeCard(
        state: CardState = .new,
        stability: Double = 0,
        difficulty: Double = 0,
        reps: Int = 0,
        lapses: Int = 0,
        lastReview: Date? = nil
    ) -> FSRSCard {
        let card = FSRSCard(
            stability: stability,
            difficulty: difficulty,
            reps: reps,
            lapses: lapses,
            state: state,
            lastReview: lastReview,
            due: lastReview ?? .now
        )
        container.mainContext.insert(card)
        return card
    }

    // MARK: - Initial stability (new state)

    @Test func newCard_initialStability_matchesWeights() throws {
        let scheduler = FSRSScheduler()
        let cases: [(ReviewRating, Double)] = [
            (.again, 0.40255),
            (.hard,  1.18385),
            (.good,  3.173),
            (.easy,  15.69105)
        ]
        for (rating, expected) in cases {
            let card = makeCard()
            let result = scheduler.schedule(card: card, rating: rating)
            #expect(
                abs(result.stability - expected) < 1e-4,
                "rating \(rating): got \(result.stability), expected \(expected)"
            )
        }
    }

    @Test func newCard_initialDifficulty_inBounds() throws {
        let scheduler = FSRSScheduler()
        for rating in ReviewRating.allCases {
            let card = makeCard()
            let result = scheduler.schedule(card: card, rating: rating)
            #expect(result.difficulty >= 1, "rating \(rating) under-bound: \(result.difficulty)")
            #expect(result.difficulty <= 10, "rating \(rating) over-bound: \(result.difficulty)")
        }
    }

    // MARK: - State transitions from .new

    @Test func newState_transitionsTo_learning_or_review() throws {
        let scheduler = FSRSScheduler()
        let expectations: [(ReviewRating, CardState)] = [
            (.again, .learning),
            (.hard,  .learning),
            (.good,  .learning),
            (.easy,  .review)
        ]
        for (rating, expected) in expectations {
            let card = makeCard()
            let result = scheduler.schedule(card: card, rating: rating)
            #expect(result.state == expected, "rating \(rating): got \(result.state)")
        }
    }

    // MARK: - State transitions from .learning

    @Test func learningState_again_or_hard_staysLearning() throws {
        let scheduler = FSRSScheduler()
        for rating in [ReviewRating.again, .hard] {
            let card = makeCard(state: .learning, stability: 1.0, difficulty: 5.0, reps: 1)
            let result = scheduler.schedule(card: card, rating: rating)
            #expect(result.state == .learning, "rating \(rating) should stay .learning")
        }
    }

    @Test func learningState_good_or_easy_movesToReview() throws {
        let scheduler = FSRSScheduler()
        for rating in [ReviewRating.good, .easy] {
            let card = makeCard(state: .learning, stability: 1.0, difficulty: 5.0, reps: 1)
            let result = scheduler.schedule(card: card, rating: rating)
            #expect(result.state == .review, "rating \(rating) should move to .review")
        }
    }

    // MARK: - State transitions from .review

    @Test func reviewState_again_movesToRelearning_andLapsesIncrement() throws {
        let scheduler = FSRSScheduler()
        let last = Date.now.addingTimeInterval(-5 * 86_400)
        let card = makeCard(
            state: .review, stability: 5, difficulty: 6, reps: 3, lapses: 1, lastReview: last
        )
        let result = scheduler.schedule(card: card, rating: .again)
        #expect(result.state == .relearning)
        #expect(result.lapses == 2)
    }

    @Test func reviewState_nonAgain_staysInReview_noLapseDelta() throws {
        let scheduler = FSRSScheduler()
        for rating in [ReviewRating.hard, .good, .easy] {
            let last = Date.now.addingTimeInterval(-3 * 86_400)
            let card = makeCard(
                state: .review, stability: 4, difficulty: 5, reps: 5, lapses: 2, lastReview: last
            )
            let result = scheduler.schedule(card: card, rating: rating)
            #expect(result.state == .review, "rating \(rating) should stay .review")
            #expect(result.lapses == 2, "rating \(rating) should not bump lapses")
        }
    }

    // MARK: - State transitions from .relearning

    @Test func relearningState_again_staysRelearning_andLapsesIncrement() throws {
        let scheduler = FSRSScheduler()
        let card = makeCard(state: .relearning, stability: 1, difficulty: 7, reps: 4, lapses: 1)
        let result = scheduler.schedule(card: card, rating: .again)
        #expect(result.state == .relearning)
        #expect(result.lapses == 2)
    }

    @Test func relearningState_good_or_easy_movesToReview() throws {
        let scheduler = FSRSScheduler()
        for rating in [ReviewRating.good, .easy] {
            let card = makeCard(state: .relearning, stability: 1, difficulty: 7, reps: 4)
            let result = scheduler.schedule(card: card, rating: rating)
            #expect(result.state == .review, "rating \(rating) should move to .review")
        }
    }

    // MARK: - Reps counter

    @Test func reps_alwaysIncrement_byOne() throws {
        let scheduler = FSRSScheduler()
        for state in CardState.allCases {
            for rating in ReviewRating.allCases {
                let card = makeCard(state: state, stability: 1, difficulty: 5, reps: 7)
                let result = scheduler.schedule(card: card, rating: rating)
                #expect(
                    result.reps == 8,
                    "state \(state), rating \(rating): reps went \(card.reps)→\(result.reps)"
                )
            }
        }
    }

    // MARK: - Difficulty invariant

    @Test func difficulty_alwaysInBounds() throws {
        let scheduler = FSRSScheduler()
        for state in CardState.allCases {
            for rating in ReviewRating.allCases {
                let card = makeCard(state: state, stability: 2, difficulty: 5)
                let result = scheduler.schedule(card: card, rating: rating)
                #expect(result.difficulty >= 1, "underbound at \(state)/\(rating)")
                #expect(result.difficulty <= 10, "overbound at \(state)/\(rating)")
            }
        }
    }

    // MARK: - Stability ordering on review

    @Test func review_stabilityGain_easy_outranks_good_outranks_hard() throws {
        let scheduler = FSRSScheduler()
        let last = Date.now.addingTimeInterval(-2 * 86_400)
        func stability(after rating: ReviewRating) throws -> Double {
            let card = makeCard(
                state: .review, stability: 5, difficulty: 5, reps: 4, lastReview: last
            )
            return scheduler.schedule(card: card, rating: rating).stability
        }
        let easy = try stability(after: .easy)
        let good = try stability(after: .good)
        let hard = try stability(after: .hard)
        #expect(easy > good, "easy stability (\(easy)) should exceed good (\(good))")
        #expect(good > hard, "good stability (\(good)) should exceed hard (\(hard))")
    }

    // MARK: - Time edge cases

    @Test func elapsedDays_clampsToZero_whenNowIsBeforeLastReview() throws {
        let scheduler = FSRSScheduler()
        let last = Date.now
        let card = makeCard(
            state: .review, stability: 5, difficulty: 5, reps: 3, lastReview: last
        )
        // Simulate clock going backward by 1 day.
        let earlier = last.addingTimeInterval(-86_400)
        let result = scheduler.schedule(card: card, rating: .good, now: earlier)
        #expect(result.elapsedDays == 0, "elapsedDays should clamp to 0 on backward clock")
    }

    @Test func longGap_doesNotCrash_andProducesFiniteStability() throws {
        let scheduler = FSRSScheduler()
        let last = Date.now.addingTimeInterval(-365 * 86_400)
        let card = makeCard(
            state: .review, stability: 2, difficulty: 6, reps: 5, lastReview: last
        )
        let result = scheduler.schedule(card: card, rating: .good)
        #expect(result.stability.isFinite)
        #expect(result.stability > 0)
        #expect(result.scheduledDays.isFinite)
    }

    // MARK: - Due interval scaling

    @Test func newCard_again_dueWithinShortLearningWindow() throws {
        let scheduler = FSRSScheduler()
        let now = Date.now
        let card = makeCard()
        let result = scheduler.schedule(card: card, rating: .again, now: now)
        // again on .new path → scheduledDays = 0 → due = now + 60s
        let delta = result.due.timeIntervalSince(now)
        #expect(delta > 0)
        #expect(delta < 5 * 60, "again on new should re-show within a few minutes, got \(delta)s")
    }

    @Test func newCard_easy_dueAtLeastOneDayAway() throws {
        let scheduler = FSRSScheduler()
        let now = Date.now
        let card = makeCard()
        let result = scheduler.schedule(card: card, rating: .easy, now: now)
        let delta = result.due.timeIntervalSince(now)
        #expect(delta >= 86_400 - 1, "easy on new should be at least 1 day away, got \(delta)s")
    }

    // MARK: - apply()

    @Test func apply_writesResultBackToCard() throws {
        let scheduler = FSRSScheduler()
        let card = makeCard(state: .review, stability: 4, difficulty: 5, reps: 3, lastReview: .now)
        let result = scheduler.schedule(card: card, rating: .good)
        scheduler.apply(result: result, to: card)
        #expect(card.stability == result.stability)
        #expect(card.difficulty == result.difficulty)
        #expect(card.reps == result.reps)
        #expect(card.lapses == result.lapses)
        #expect(card.state == result.state)
        #expect(card.due == result.due)
    }
}
