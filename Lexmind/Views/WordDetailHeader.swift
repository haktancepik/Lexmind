//
//  WordDetailHeader.swift
//  Lexmind
//
//  Title + horizontally-scrolling tag row (POS, countability, FSRS
//  state, CEFR level, topics) for the Word detail screen. Surfaces the
//  in-flight regeneration spinner and an inline error message when AI
//  analysis fails.
//

import SwiftUI

struct WordDetailHeader: View {
    let word: Word
    let isRegenerating: Bool
    let error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(word.displayName)
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if isRegenerating {
                    ProgressView()
                        .accessibilityLabel(Text("Yeniden analiz ediliyor"))
                }
            }
            tagRow
            if let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
    }

    private var tagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !word.partOfSpeech.isEmpty {
                    tag(word.partOfSpeech, color: .blue)
                }
                if !word.countability.isEmpty,
                   word.countability.lowercased() != "n/a" {
                    tag(word.countability, color: .purple)
                }
                if let state = word.card?.state {
                    tag(state.label, color: .green)
                }
                if let lv = word.level {
                    tag(lv.label, color: Self.cefrColor(lv))
                }
                ForEach(word.topics) { tp in
                    Label(tp.label, systemImage: tp.symbol)
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(.tertiary, in: Capsule())
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(combinedTagLabel))
    }

    /// Joins every visible tag into a single VoiceOver utterance —
    /// otherwise users would swipe through 5+ decorative capsules.
    private var combinedTagLabel: String {
        var parts: [String] = []
        if !word.partOfSpeech.isEmpty { parts.append(word.partOfSpeech) }
        if !word.countability.isEmpty,
           word.countability.lowercased() != "n/a" {
            parts.append(word.countability)
        }
        if let state = word.card?.state {
            parts.append("FSRS durumu: \(state.label)")
        }
        if let lv = word.level {
            parts.append("CEFR \(lv.label)")
        }
        for tp in word.topics { parts.append(tp.label) }
        return parts.joined(separator: ", ")
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    static func cefrColor(_ level: CEFRLevel) -> Color {
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
}
