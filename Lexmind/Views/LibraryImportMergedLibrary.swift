//
//  LibraryImportMergedLibrary.swift
//  Lexmind
//
//  Pulls Common + Oxford word libraries into a single de-duplicated
//  list (Common wins on collision because it ships with the richest
//  metadata). Lives outside `LibraryImportView` so subviews can read
//  it without having to be nested inside the main view.
//

import Foundation
import SwiftUI

enum MergedLibrary {
    static let all: [CommonWord] = {
        var seen = Set<String>()
        var merged: [CommonWord] = []
        merged.reserveCapacity(CommonWordsLibrary.all.count + OxfordWordsLibrary.all.count)
        for word in CommonWordsLibrary.all + OxfordWordsLibrary.all {
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
