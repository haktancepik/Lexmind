//
//  StudyAnswerCard.swift
//  Lexmind
//
//  Front + back of the study card. `StudyPromptCard` shows the term
//  (and, once revealed, the IPA). `StudyAnswerCard` shows the gloss,
//  examples, inflections, family, and relation web — and lets tappable
//  tokens bubble back to the parent (StudyView) for popover lookup.
//

import SwiftUI
import UIKit

struct StudyPromptCard: View {
    let word: Word
    let revealed: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text(word.displayName)
                .font(.system(size: 44, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
            if revealed && !word.ipa.isEmpty {
                Text(word.ipa)
                    .font(.system(.title3, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.regularMaterial)
        )
    }
}

struct StudyAnswerCard: View {
    let word: Word
    let termExists: (String) -> Bool
    let onTokenTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            badges
            meanings
            examplesSection
            inflectionsSection
            familySection
            relationsSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Sections

    private var badges: some View {
        HStack(spacing: 8) {
            if !word.partOfSpeech.isEmpty {
                badge(word.partOfSpeech, color: .blue)
            }
            if !word.countability.isEmpty,
               word.countability.lowercased() != "n/a" {
                badge(word.countability, color: .purple)
            }
        }
    }

    @ViewBuilder
    private var meanings: some View {
        if !word.turkishMeaning.isEmpty {
            Text(word.turkishMeaning)
                .font(.title2.bold())
        }
        if !word.definition.isEmpty {
            tappable(text: word.definition, baseUIColor: .secondaryLabel)
        }
    }

    @ViewBuilder
    private var examplesSection: some View {
        if !word.examples.isEmpty {
            Divider().padding(.vertical, 4)
            Text("Örnekler").font(.headline)
            ForEach(Array(word.examples.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    tappable(text: line,
                             highlightedTerm: word.term.lowercased(),
                             baseUIColor: .label)
                }
                .font(.callout)
            }
        }
    }

    @ViewBuilder
    private var inflectionsSection: some View {
        if !word.inflectionExamples.isEmpty {
            Divider().padding(.vertical, 4)
            Text("Çekim Örnekleri").font(.headline)
            ForEach(Array(word.inflectionExamples.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    tappable(text: line,
                             highlightedTerm: word.familyRoot?.lowercased() ?? word.term.lowercased(),
                             baseUIColor: .label)
                }
                .font(.callout)
            }
        }
    }

    @ViewBuilder
    private var familySection: some View {
        let hasRoot = (word.familyRoot?.isEmpty == false)
        let hasMembers = !word.familyMembers.isEmpty
        if hasRoot || hasMembers {
            Divider().padding(.vertical, 4)
            Text("Kelime Ailesi").font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                if let root = word.familyRoot, !root.isEmpty {
                    HStack(spacing: 6) {
                        Text("Kök:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            onTokenTap(root)
                        } label: {
                            Text(root)
                                .font(.caption.bold())
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.15), in: Capsule())
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if hasMembers {
                    let verifiedSet = Set(word.familyMembersVerifiedRaw)
                    relationChipsRow(items: word.familyMembers.map {
                        (term: $0,
                         origin: verifiedSet.contains($0.lowercased()) ? RelationSource.verified : .ai)
                    })
                }
            }
        }
    }

    @ViewBuilder
    private var relationsSection: some View {
        if !word.relations.isEmpty {
            Divider().padding(.vertical, 4)
            Text("Kelime Ağı").font(.headline)
            let grouped = Dictionary(grouping: word.relations, by: { $0.kind })
            VStack(alignment: .leading, spacing: 10) {
                ForEach(RelationKind.allCases) { kind in
                    if let items = grouped[kind], !items.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(kind.label, systemImage: kind.symbol)
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            relationChipsRow(items: sortedItems(items))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Building blocks

    private func sortedItems(_ relations: [WordRelation]) -> [(term: String, origin: RelationSource)] {
        relations
            .map { (term: $0.targetTerm, origin: $0.origin) }
            .sorted { ($0.origin == .verified ? 0 : 1) < ($1.origin == .verified ? 0 : 1) }
    }

    private func relationChipsRow(items: [(term: String, origin: RelationSource)]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items, id: \.term) { item in
                    Button {
                        onTokenTap(item.term)
                    } label: {
                        HStack(spacing: 4) {
                            Text(item.term)
                                .font(.caption.weight(.medium))
                            Image(systemName: item.origin.symbol)
                                .font(.caption2)
                                .foregroundStyle(item.origin == .verified ? .green : .orange)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                        .overlay(
                            Capsule().stroke(
                                item.origin == .verified
                                    ? Color.green.opacity(0.5)
                                    : Color.orange.opacity(0.35),
                                style: StrokeStyle(
                                    lineWidth: 1,
                                    dash: item.origin == .verified ? [] : [3, 2]
                                )
                            )
                        )
                        .foregroundStyle(termExists(item.term) ? Color.accentColor : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func tappable(text: String,
                          highlightedTerm: String? = nil,
                          baseUIColor: UIColor) -> some View {
        TappableText(
            text: text,
            highlightedTerm: highlightedTerm,
            baseColor: baseUIColor,
            onTokenTap: { term in onTokenTap(term) }
        )
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}
