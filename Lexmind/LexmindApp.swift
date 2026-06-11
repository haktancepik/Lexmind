//
//  LexmindApp.swift
//  Lexmind
//

import SwiftUI
import SwiftData
import os

@main
struct LexmindApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    let modelContainer: ModelContainer
    private let metricObserver = MetricKitObserver()

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
            Log.app.fault("ModelContainer init failed: \(error.localizedDescription)")
            fatalError("Failed to create ModelContainer: \(error)")
        }
        metricObserver.start()
        Log.app.info("Lexmind launched — schema V2, MetricKit subscriber active")
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
