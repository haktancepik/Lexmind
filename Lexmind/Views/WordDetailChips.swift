//
//  WordDetailChips.swift
//  Lexmind
//
//  Shared atoms used by `WordDetailFamilyCard` and
//  `WordDetailRelationsCard`: the horizontally-scrolling relation chip
//  row plus the two small status rows (loading + Datamuse verifying)
//  they both display while data is in flight.
//

import SwiftUI

struct WordDetailRelationChip: Hashable {
    let term: String
    let origin: RelationSource
}

struct WordDetailChipsRow: View {
    let items: [WordDetailRelationChip]
    let termExists: (String) -> Bool
    let onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items, id: \.term) { item in
                    chip(for: item)
                }
            }
        }
    }

    private func chip(for item: WordDetailRelationChip) -> some View {
        Button {
            onTap(item.term)
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
                    strokeColor(for: item),
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

    /// Verified chips stay green; AI chips switch between accent (term
    /// already in library — tap navigates) and orange (term unknown —
    /// tap prompts to add).
    private func strokeColor(for item: WordDetailRelationChip) -> Color {
        if item.origin == .verified {
            return Color.green.opacity(0.5)
        }
        return termExists(item.term)
            ? Color.accentColor.opacity(0.4)
            : Color.orange.opacity(0.35)
    }
}

struct WordDetailLoadingRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

struct WordDetailVerifyingBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.mini)
            Text("Doğrulanıyor…")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }
}

/// Sorts relation tuples so verified items lead the row.
func sortedRelationChips(_ relations: [WordRelation]) -> [WordDetailRelationChip] {
    relations
        .map { WordDetailRelationChip(term: $0.targetTerm, origin: $0.origin) }
        .sorted { ($0.origin == .verified ? 0 : 1) < ($1.origin == .verified ? 0 : 1) }
}
