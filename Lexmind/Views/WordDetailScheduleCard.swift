//
//  WordDetailScheduleCard.swift
//  Lexmind
//
//  FSRS card metadata row — diagnostic surface that exposes due date,
//  stability, difficulty, rep count, and lapses so power users can
//  spot scheduling issues without digging through the database.
//

import SwiftUI

struct WordDetailScheduleCard: View {
    let card: FSRSCard

    var body: some View {
        WordDetailSectionCard(title: "FSRS Programı", icon: "clock.arrow.circlepath") {
            VStack(alignment: .leading, spacing: 6) {
                row("Durum", value: card.state.label)
                row("Vade", value: card.due.formatted(date: .abbreviated, time: .shortened))
                row("Kararlılık", value: String(format: "%.2f gün", card.stability))
                row("Zorluk", value: String(format: "%.2f / 10", card.difficulty))
                row("Tekrar", value: "\(card.reps)")
                row("Unutma", value: "\(card.lapses)")
            }
        }
    }

    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
