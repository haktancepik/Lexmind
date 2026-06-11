//
//  StudyRatingControls.swift
//  Lexmind
//
//  Bottom action row for the study card. Before reveal it's a single
//  "Cevabı Göster" button; after reveal it's four FSRS rating buttons
//  with a per-rating interval preview. The interval and rating colors
//  are owned here so the rest of the view doesn't have to know FSRS.
//

import SwiftUI

struct StudyRatingControls: View {
    let word: Word
    let revealed: Bool
    let session: StudySession
    let onReveal: () -> Void
    let onRate: (ReviewRating) -> Void

    var body: some View {
        if revealed {
            ratingRow
        } else {
            revealButton
        }
    }

    private var ratingRow: some View {
        HStack(spacing: 10) {
            ForEach(ReviewRating.allCases, id: \.self) { rating in
                Button {
                    onRate(rating)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: rating.symbol)
                        Text(rating.label).font(.caption.bold())
                        Text(session.previewInterval(for: word, rating: rating))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(Self.color(for: rating))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    private var revealButton: some View {
        Button(action: onReveal) {
            Label("Cevabı Göster", systemImage: "eye")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    static func color(for rating: ReviewRating) -> Color {
        switch rating {
        case .again: return .red
        case .hard:  return .orange
        case .good:  return .green
        case .easy:  return .blue
        }
    }
}
