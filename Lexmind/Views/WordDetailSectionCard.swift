//
//  WordDetailSectionCard.swift
//  Lexmind
//
//  Shared "regular material" card wrapper used by every section on the
//  Word detail screen. `isWorking` shows a small spinner next to the
//  title — relations/family cards turn it on while Datamuse verification
//  is in flight.
//

import SwiftUI

struct WordDetailSectionCard<Content: View>: View {
    let title: String
    let icon: String
    var isWorking: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(title, systemImage: icon)
                    .font(.headline)
                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                        .transition(.opacity)
                }
                Spacer(minLength: 0)
            }
            .animation(.easeInOut(duration: 0.2), value: isWorking)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
    }
}
