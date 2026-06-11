//
//  WordDetailMeaningCard.swift
//  Lexmind
//
//  The middle four cards on the Word detail screen — phonetics, meaning
//  + Turkish gloss, example sentences, and inflection examples. Every
//  body of text is rendered through `TappableText` so the parent can
//  open the lookup popover when the user taps a token.
//

import SwiftUI
import UIKit

struct WordDetailPhoneticsCard: View {
    let word: Word

    var body: some View {
        WordDetailSectionCard(title: "Telaffuz", icon: "waveform") {
            if word.ipa.isEmpty {
                Text("Henüz IPA eklenmedi.").foregroundStyle(.secondary)
            } else {
                Text(word.ipa)
                    .font(.system(.title3, design: .monospaced))
            }
        }
    }
}

struct WordDetailMeaningCard: View {
    let word: Word
    let onTokenTap: (String) -> Void

    var body: some View {
        WordDetailSectionCard(title: "Anlam", icon: "text.bubble") {
            if !word.turkishMeaning.isEmpty {
                Text(word.turkishMeaning)
                    .font(.title3.bold())
            }
            if !word.definition.isEmpty {
                TappableText(
                    text: word.definition,
                    highlightedTerm: nil,
                    baseColor: .secondaryLabel,
                    onTokenTap: onTokenTap
                )
                .padding(.top, 4)
            }
            if word.turkishMeaning.isEmpty, word.definition.isEmpty {
                Text("Anlam henüz eklenmedi.").foregroundStyle(.secondary)
            }
        }
    }
}

struct WordDetailExamplesCard: View {
    let word: Word
    let onTokenTap: (String) -> Void

    var body: some View {
        WordDetailSectionCard(title: "Örnek Cümleler", icon: "quote.bubble") {
            if word.examples.isEmpty {
                Text("Örnek cümle yok.").foregroundStyle(.secondary)
            } else {
                ForEach(Array(word.examples.enumerated()), id: \.offset) { idx, line in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(idx + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 18, alignment: .leading)
                        TappableText(
                            text: line,
                            highlightedTerm: word.term.lowercased(),
                            baseColor: .label,
                            onTokenTap: onTokenTap
                        )
                    }
                    if idx < word.examples.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

struct WordDetailInflectionExamplesCard: View {
    let word: Word
    let onTokenTap: (String) -> Void

    var body: some View {
        if !word.inflectionExamples.isEmpty {
            WordDetailSectionCard(title: "Çekim Örnekleri", icon: "arrow.triangle.branch") {
                ForEach(Array(word.inflectionExamples.enumerated()), id: \.offset) { idx, line in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(idx + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 18, alignment: .leading)
                        TappableText(
                            text: line,
                            highlightedTerm: word.familyRoot?.lowercased() ?? word.term.lowercased(),
                            baseColor: .label,
                            onTokenTap: onTokenTap
                        )
                    }
                    if idx < word.inflectionExamples.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}
