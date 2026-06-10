//
//  LexmindApp.swift
//  Lexmind
//

import SwiftUI
import SwiftData

@main
struct LexmindApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                RootTabView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: [
            Word.self,
            FSRSCard.self,
            ReviewLog.self,
            DailyGoal.self,
            WordRelation.self,
            DailyReadingPassage.self
        ])
    }
}
