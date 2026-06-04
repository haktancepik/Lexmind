//
//  FSRSScheduler.swift
//  Lexmind
//
//  FSRS-5 implementation of the Free Spaced Repetition Scheduler.
//  Reference: https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler
//

import Foundation

struct FSRSParameters {
    var w: [Double] = [
        0.40255, 1.18385, 3.173, 15.69105,
        7.1949, 0.5345, 1.4604, 0.0046,
        1.54575, 0.1192, 1.01925, 1.9395,
        0.11, 0.29605, 2.2698, 0.2315,
        2.9898, 0.51655, 0.6621
    ]
    var requestRetention: Double = 0.9
    var maximumInterval: Double = 36500
    var enableShortTerm: Bool = true

    static let factor: Double = 19.0 / 81.0
    static let decay: Double = -0.5
}

struct FSRSScheduler {
    var parameters: FSRSParameters = FSRSParameters()

    private func clampDifficulty(_ d: Double) -> Double {
        max(1, min(10, d))
    }

    private func initialStability(_ rating: ReviewRating) -> Double {
        max(0.1, parameters.w[rating.rawValue - 1])
    }

    private func initialDifficulty(_ rating: ReviewRating) -> Double {
        let r = Double(rating.rawValue)
        return clampDifficulty(parameters.w[4] - exp(parameters.w[5] * (r - 1)) + 1)
    }

    private func meanReversion(_ initial: Double, current: Double) -> Double {
        parameters.w[7] * initial + (1 - parameters.w[7]) * current
    }

    private func nextDifficulty(currentD: Double, rating: ReviewRating) -> Double {
        let r = Double(rating.rawValue)
        let delta = -parameters.w[6] * (r - 3)
        let nextD = currentD + delta * ((10 - currentD) / 9)
        return clampDifficulty(meanReversion(initialDifficulty(.easy), current: nextD))
    }

    private func retrievability(elapsedDays: Double, stability: Double) -> Double {
        guard stability > 0 else { return 0 }
        return pow(1 + FSRSParameters.factor * elapsedDays / stability, FSRSParameters.decay)
    }

    private func nextRecallStability(d: Double, s: Double, r: Double, rating: ReviewRating) -> Double {
        let hardPenalty: Double = (rating == .hard) ? parameters.w[15] : 1
        let easyBonus: Double = (rating == .easy) ? parameters.w[16] : 1
        let value = s * (1 + exp(parameters.w[8])
                        * (11 - d)
                        * pow(s, -parameters.w[9])
                        * (exp((1 - r) * parameters.w[10]) - 1)
                        * hardPenalty
                        * easyBonus)
        return max(0.01, value)
    }

    private func nextForgetStability(d: Double, s: Double, r: Double) -> Double {
        let value = parameters.w[11]
            * pow(d, -parameters.w[12])
            * (pow(s + 1, parameters.w[13]) - 1)
            * exp((1 - r) * parameters.w[14])
        return max(0.01, value)
    }

    private func shortTermStability(s: Double, rating: ReviewRating) -> Double {
        let r = Double(rating.rawValue)
        let value = s * exp(parameters.w[17] * (r - 3 + parameters.w[18]))
        return max(0.01, value)
    }

    private func nextInterval(stability: Double) -> Double {
        let logRetention = log(parameters.requestRetention)
        let interval = (stability / FSRSParameters.factor) * (pow(parameters.requestRetention, 1 / FSRSParameters.decay) - 1)
        _ = logRetention
        let rounded = max(1, round(interval))
        return min(rounded, parameters.maximumInterval)
    }

    struct ScheduleResult {
        var stability: Double
        var difficulty: Double
        var elapsedDays: Double
        var scheduledDays: Double
        var reps: Int
        var lapses: Int
        var state: CardState
        var lastReview: Date
        var due: Date
    }

    func schedule(card: FSRSCard, rating: ReviewRating, now: Date = .now) -> ScheduleResult {
        let elapsed: Double
        if let last = card.lastReview {
            elapsed = max(0, now.timeIntervalSince(last) / 86_400)
        } else {
            elapsed = 0
        }

        var stability = card.stability
        var difficulty = card.difficulty
        let reps = card.reps + 1
        var lapses = card.lapses
        var state = card.state
        var scheduledDays: Double = 0

        switch card.state {
        case .new:
            stability = initialStability(rating)
            difficulty = initialDifficulty(rating)
            switch rating {
            case .again:
                state = .learning
                scheduledDays = 0
            case .hard:
                state = .learning
                scheduledDays = 0
            case .good:
                state = .learning
                scheduledDays = 0
            case .easy:
                state = .review
                scheduledDays = nextInterval(stability: stability)
            }

        case .learning, .relearning:
            if parameters.enableShortTerm {
                stability = shortTermStability(s: max(stability, 0.1), rating: rating)
            }
            difficulty = nextDifficulty(currentD: max(difficulty, 1), rating: rating)
            switch rating {
            case .again:
                state = card.state
                scheduledDays = 0
                if card.state == .relearning { lapses += 1 }
            case .hard:
                scheduledDays = 0
                state = card.state
            case .good:
                state = .review
                scheduledDays = nextInterval(stability: stability)
            case .easy:
                state = .review
                scheduledDays = nextInterval(stability: stability)
            }

        case .review:
            let r = retrievability(elapsedDays: elapsed, stability: stability)
            difficulty = nextDifficulty(currentD: difficulty, rating: rating)
            if rating == .again {
                stability = nextForgetStability(d: difficulty, s: stability, r: r)
                lapses += 1
                state = .relearning
                scheduledDays = 0
            } else {
                stability = nextRecallStability(d: difficulty, s: stability, r: r, rating: rating)
                state = .review
                scheduledDays = nextInterval(stability: stability)
            }
        }

        let dueInterval: TimeInterval
        if scheduledDays <= 0 {
            // Re-show same session — schedule a short learning step in minutes.
            switch rating {
            case .again: dueInterval = 60         // 1 min
            case .hard:  dueInterval = 6 * 60     // 6 min
            case .good:  dueInterval = 10 * 60    // 10 min
            case .easy:  dueInterval = 86_400     // 1 day
            }
        } else {
            dueInterval = scheduledDays * 86_400
        }
        let due = now.addingTimeInterval(dueInterval)

        return ScheduleResult(
            stability: stability,
            difficulty: difficulty,
            elapsedDays: elapsed,
            scheduledDays: scheduledDays,
            reps: reps,
            lapses: lapses,
            state: state,
            lastReview: now,
            due: due
        )
    }

    func apply(result: ScheduleResult, to card: FSRSCard) {
        card.stability = result.stability
        card.difficulty = result.difficulty
        card.elapsedDays = result.elapsedDays
        card.scheduledDays = result.scheduledDays
        card.reps = result.reps
        card.lapses = result.lapses
        card.state = result.state
        card.lastReview = result.lastReview
        card.due = result.due
    }
}
