//
//  WordDetailRelationsCard.swift
//  Lexmind
//
//  Synonyms / antonyms / related-word chips for the Word detail
//  screen. While Datamuse verification is in flight the card shows a
//  small "Doğrulanıyor…" badge; on a retryable failure it switches to
//  an orange offline pill with a "Tekrar dene" button.
//

import SwiftUI

struct WordDetailRelationsCard: View {
    let word: Word
    let isRegenerating: Bool
    let isVerifying: Bool
    let verifierError: DatamuseError?
    let termExists: (String) -> Bool
    let onTermTap: (String) -> Void
    let onRetryVerification: () -> Void

    private var showsLoading: Bool { word.relations.isEmpty && isRegenerating }

    var body: some View {
        if !word.relations.isEmpty || showsLoading {
            WordDetailSectionCard(title: "İlişkili Kelimeler",
                                  icon: "link",
                                  isWorking: isVerifying) {
                if showsLoading {
                    WordDetailLoadingRow(text: "İlişkiler yükleniyor…")
                        .transition(.opacity)
                } else {
                    content
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: word.relations.count)
            .animation(.easeInOut(duration: 0.25), value: isVerifying)
        }
    }

    private var content: some View {
        let grouped = Dictionary(grouping: word.relations, by: { $0.kind })
        return VStack(alignment: .leading, spacing: 12) {
            if let error = verifierError, error.isRetryable {
                offlineBadge(message: error.userMessage)
            } else if isVerifying {
                WordDetailVerifyingBadge()
            }
            ForEach(RelationKind.allCases) { kind in
                if let items = grouped[kind], !items.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(kind.label, systemImage: kind.symbol)
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        WordDetailChipsRow(
                            items: sortedRelationChips(items),
                            termExists: termExists,
                            onTap: onTermTap
                        )
                    }
                }
            }
        }
    }

    private func offlineBadge(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .font(.subheadline)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("İlişkiler doğrulanamadı, AI önerileri gösteriliyor.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button(action: onRetryVerification) {
                Label("Tekrar dene", systemImage: "arrow.clockwise")
                    .labelStyle(.titleAndIcon)
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.orange)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message). İlişkiler doğrulanamadı.")
    }
}
