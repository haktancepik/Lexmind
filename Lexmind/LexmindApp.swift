//
//  LexmindApp.swift
//  Lexmind
//

import SwiftUI
import SwiftData

@main
struct LexmindApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema(versionedSchema: LexmindSchemaV2.self)
            let configuration = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: LexmindMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                RootTabView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(modelContainer)
    }
}
