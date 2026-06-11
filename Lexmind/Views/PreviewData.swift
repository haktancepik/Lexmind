//
//  PreviewData.swift
//  Lexmind
//

import Foundation
import SwiftData

enum PreviewData {
    @MainActor
    static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Word.self, FSRSCard.self, ReviewLog.self, DailyGoal.self, WordRelation.self, DailyReadingPassage.self, WordDeck.self,
            configurations: config
        )
        let ctx = container.mainContext

        let samples: [(String, String, String, String, String, String, [String])] = [
            ("ephemeral", "adjective", "/ɪˈfɛm(ə)rəl/", "N/A",
             "Lasting for a very short time.", "kısa ömürlü",
             [
                "Cherry blossoms are ephemeral, blooming for only a few days each spring.",
                "Fame can be ephemeral; today's star may be forgotten next year.",
                "The artist captured the ephemeral light of dawn.",
                "Their happiness was ephemeral and faded by morning.",
                "Snowflakes have an ephemeral beauty."
             ]),
            ("resilient", "adjective", "/rɪˈzɪliənt/", "N/A",
             "Able to recover quickly from difficulties.", "dirençli, esnek",
             [
                "Children are remarkably resilient after setbacks.",
                "The resilient economy bounced back within months.",
                "She remained resilient despite repeated rejections.",
                "Bamboo is resilient and bends without breaking.",
                "A resilient leader inspires confidence in a crisis."
             ]),
            ("endeavor", "noun", "/ɪnˈdɛvər/", "countable",
             "An attempt to achieve a goal.", "girişim, çaba",
             [
                "Climbing Everest is a dangerous endeavor.",
                "Their endeavor to launch a startup paid off.",
                "She supported his every endeavor.",
                "The scientific endeavor requires patience.",
                "It was a noble endeavor that ended in success."
             ])
        ]

        let scheduler = FSRSScheduler()
        for (i, s) in samples.enumerated() {
            let w = Word(
                term: s.0,
                partOfSpeech: s.1,
                ipa: s.2,
                countability: s.3,
                definition: s.4,
                turkishMeaning: s.5,
                examples: s.6
            )
            let card = FSRSCard(due: .now.addingTimeInterval(Double(i - 1) * 86_400))
            card.word = w
            w.card = card
            ctx.insert(w)
            _ = scheduler
        }

        let goal = DailyGoal()
        ctx.insert(goal)

        return container
    }()
}
