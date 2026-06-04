//
//  LexmindApp.swift
//  Lexmind
//

import SwiftUI
import SwiftData

@main
struct LexmindApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [
            Word.self,
            FSRSCard.self,
            ReviewLog.self,
            DailyGoal.self,
            WordRelation.self
        ])
    }
}
