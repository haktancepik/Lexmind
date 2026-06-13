//
//  LibraryImportMergedLibrary.swift
//  Lexmind
//
//  Pulls Common + Oxford + PhrasalVerbs word libraries into a single
//  de-duplicated list (earlier sources win on collision because they
//  ship with the richest metadata: Common > Oxford > PhrasalVerbs).
//  Lives outside `LibraryImportView` so subviews can read it without
//  having to be nested inside the main view.
//

import Foundation
import SwiftUI

enum MergedLibrary {
    static let all: [CommonWord] = {
        var seen = Set<String>()
        var merged: [CommonWord] = []
        merged.reserveCapacity(
            CommonWordsLibrary.all.count
            + OxfordWordsLibrary.all.count
            + PhrasalVerbsLibrary.all.count
        )
        for word in CommonWordsLibrary.all
            + OxfordWordsLibrary.all
            + PhrasalVerbsLibrary.all {
            let key = word.term.lowercased()
            if seen.insert(key).inserted {
                merged.append(word)
            }
        }
        return merged
    }()

    static let allTermSet: Set<String> = Set(all.map { $0.term.lowercased() })

    static func filtered(level: CEFRLevel?, topic: WordTopic?) -> [CommonWord] {
        all.filter { word in
            if let level, word.level != level { return false }
            if let topic, !word.topics.contains(topic) { return false }
            return true
        }
    }

    /// Warms every underlying library in parallel so subsequent
    /// `MergedLibrary.all` access on the main thread is free. Idempotent
    /// — each library is its own static let, so repeat calls return
    /// immediately. Single seam to add new sources to (next time we add
    /// e.g. TOEFL or idioms, only this method needs to grow).
    static func preloadAll() async {
        async let common: Void = CommonWordsLibrary.preload()
        async let oxford: Void = OxfordWordsLibrary.preload()
        async let phrasal: Void = PhrasalVerbsLibrary.preload()
        _ = await common
        _ = await oxford
        _ = await phrasal
    }
}

/// CEFR level → SwiftUI Color mapping used across the Library Import
/// screen (chips, preset tiles, word rows, level headers).
func libraryImportCEFRColor(_ level: CEFRLevel) -> Color {
    switch level.tint {
    case "green":  return .green
    case "mint":   return .mint
    case "yellow": return .yellow
    case "orange": return .orange
    case "red":    return .red
    case "purple": return .purple
    default:       return .accentColor
    }
}
