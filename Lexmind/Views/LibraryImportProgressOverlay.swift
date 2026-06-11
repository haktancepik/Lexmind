//
//  LibraryImportProgressOverlay.swift
//  Lexmind
//
//  Blocking modal that fronts the library import while
//  `LibraryImporter` runs off the main actor. Surfaces a linear bar,
//  the running tally, the latest committed term, and a destructive
//  "İptal" button that cancels the in-flight Task.
//

import SwiftUI

struct LibraryImportProgress: Equatable {
    var total: Int
    var done: Int
    var currentTerm: String
}

struct LibraryImportProgressOverlay: View {
    let progress: LibraryImportProgress
    let canCancel: Bool
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { }
            VStack(spacing: 14) {
                Text("Kelimeler ekleniyor…")
                    .font(.headline)
                ProgressView(value: Double(progress.done),
                             total: Double(max(progress.total, 1)))
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
                    .animation(.linear(duration: 0.15), value: progress.done)
                Text("\(progress.done) / \(progress.total) kelime")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                if !progress.currentTerm.isEmpty {
                    Text(progress.currentTerm)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                Button(role: .destructive, action: onCancel) {
                    Label("İptal", systemImage: "xmark.circle")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 4)
                .disabled(!canCancel)
            }
            .padding(20)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
            )
            .shadow(radius: 12)
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
    }
}
