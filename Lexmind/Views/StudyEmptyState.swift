//
//  StudyEmptyState.swift
//  Lexmind
//
//  Shown when the session queue is empty — either because the user
//  finished what was due, or because the active deck has nothing to
//  study right now. Surfaces the deck picker (so the user can switch
//  scope without leaving the screen) and offers a "Okuma Metni Oluştur"
//  shortcut when the session produced at least one review.
//

import SwiftUI

struct StudyEmptyState: View {
    let sessionReviewed: Int
    let activeDeck: WordDeck?
    let onRequestReading: (() -> Void)?
    let onDismiss: () -> Void
    @ViewBuilder var deckPicker: () -> StudyDeckPicker

    var body: some View {
        VStack(spacing: 16) {
            deckPicker()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Harika iş! 🎉")
                .font(.title2.bold())
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if sessionReviewed > 0, let onRequestReading {
                Button {
                    onDismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        onRequestReading()
                    }
                } label: {
                    Label("Okuma Metni Oluştur", systemImage: "book.pages")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Button("Bitir", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var message: String {
        if sessionReviewed > 0 {
            return "Bu oturumda \(sessionReviewed) kelime gözden geçirdin."
        }
        if let activeDeck {
            return "\"\(activeDeck.name)\" destesinde şu an çalışılacak bir şey yok."
        }
        return "Şu an çalışılacak bir şey yok."
    }
}
