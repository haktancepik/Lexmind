//
//  Logging.swift
//  Lexmind
//
//  Central os.Logger factory. Every subsystem in the app derives its
//  logger from `Log.subsystem` so Console.app and MetricKit payloads
//  group consistently. Use the category constants below — adding new
//  ones is cheap, freelance strings cause silent silo creation.
//

import Foundation
import os

enum Log {
    static let subsystem = "com.lexmind.app"

    /// App lifecycle, ModelContainer setup, root-level coordination.
    static let app = Logger(subsystem: subsystem, category: "app")

    /// JSON-backed word libraries (Common, Oxford, MergedLibrary).
    static let library = Logger(subsystem: subsystem, category: "services.library")

    /// LibraryImporter ModelActor — bulk inserts, deck binding.
    static let importer = Logger(subsystem: subsystem, category: "services.importer")

    /// FoundationModels (WordAnalyzer, ReadingPassageGenerator, lookups).
    static let ai = Logger(subsystem: subsystem, category: "services.ai")

    /// DatamuseClient and any other outbound HTTP.
    static let network = Logger(subsystem: subsystem, category: "services.network")

    /// FSRS scheduler.
    static let fsrs = Logger(subsystem: subsystem, category: "fsrs")

    /// SwiftData saves, fetches, migrations.
    static let data = Logger(subsystem: subsystem, category: "data")

    /// MetricKit payload summaries.
    static let metrics = Logger(subsystem: subsystem, category: "metrics")
}

/// Shared `OSSignposter` instances used to bracket critical work so
/// Instruments can chart latency / throughput. All four use the
/// reserved `PointsOfInterest` category so the default Instruments
/// "Points of Interest" track in Time Profiler / POI templates picks
/// them up automatically — interval names (`loadCommon`, `importWords`,
/// `schedule`, `generatePassage`, …) keep them distinguishable.
enum Signpost {
    static let importer = OSSignposter(subsystem: Log.subsystem, category: "PointsOfInterest")
    static let fsrs = OSSignposter(subsystem: Log.subsystem, category: "PointsOfInterest")
    static let ai = OSSignposter(subsystem: Log.subsystem, category: "PointsOfInterest")
    static let library = OSSignposter(subsystem: Log.subsystem, category: "PointsOfInterest")
}
