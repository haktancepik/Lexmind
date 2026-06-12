//
//  WordQuickLookupCard.swift
//  Lexmind
//

import SwiftUI

struct WordQuickLookupCard: View {
    let phase: QuickLookupService.Phase
    let isAlreadyInLibrary: Bool
    let isAdding: Bool
    var onOpenDetail: ((String) -> Void)? = nil
    let onAddToLibrary: (String) -> Void
    let onRetry: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(14)
        .frame(idealWidth: 280, maxWidth: 320, alignment: .leading)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .idle:
            HStack(spacing: 10) {
                ProgressView()
                Text("Hazırlanıyor…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

        case .loading(let term):
            HStack(spacing: 10) {
                ProgressView()
                Text("\"\(term)\" analiz ediliyor…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

        case .ready(let term, let result):
            readyBody(term: term, result: result)

        case .failed(let term, let message):
            VStack(alignment: .leading, spacing: 8) {
                Label("Anlam alınamadı", systemImage: "exclamationmark.triangle")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                Button {
                    onRetry(term)
                } label: {
                    Label("Tekrar dene", systemImage: "arrow.clockwise")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityHint(Text("\(term) için anlam aramayı yeniden başlatır"))
            }
        }
    }

    @ViewBuilder
    private func readyBody(term: String, result: QuickLookupService.LookupResult) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(term)
                .font(.headline)
            if !result.partOfSpeech.isEmpty {
                Text(result.partOfSpeech)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.blue.opacity(0.15), in: Capsule())
                    .foregroundStyle(.blue)
            }
            Spacer(minLength: 0)
        }

        if !result.ipa.isEmpty {
            Text(result.ipa)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }

        if !result.turkishMeaning.isEmpty {
            Text(result.turkishMeaning)
                .font(.title3.bold())
                .foregroundStyle(.primary)
        }

        if !result.definition.isEmpty {
            Text(result.definition)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }

        familySection(result)
        inflectionSection(result)

        Divider().padding(.vertical, 2)

        if isAlreadyInLibrary {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("Zaten listende")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            if let onOpenDetail {
                Button {
                    onOpenDetail(term)
                } label: {
                    Label("Detayı Aç", systemImage: "arrow.right.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityHint(Text("\(term) kelimesinin detay sayfasını açar"))
            }
        } else {
            Button {
                onAddToLibrary(term)
            } label: {
                HStack(spacing: 6) {
                    if isAdding {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    Text(isAdding ? "Ekleniyor…" : "Listeme Ekle")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(isAdding)
            .accessibilityLabel(Text(isAdding ? "Ekleniyor" : "Listeme ekle"))
            .accessibilityHint(Text("\(term) kelimesini kütüphaneye ekler"))
        }
    }

    @ViewBuilder
    private func familySection(_ result: QuickLookupService.LookupResult) -> some View {
        let root = result.familyRoot
        let members = result.familyMembers
        let isEmpty = root.isEmpty && members.isEmpty
        if isEmpty && result.isStreaming {
            loadingRow(text: "Kelime ailesi yükleniyor…")
                .transition(.opacity)
        } else if !isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Kelime Ailesi")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                if !root.isEmpty {
                    HStack(spacing: 4) {
                        Text("Kök:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(root)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                    }
                }
                if !members.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(members, id: \.self) { member in
                                Text(member)
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color(.tertiarySystemFill), in: Capsule())
                            }
                        }
                    }
                }
            }
            .padding(.top, 2)
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func inflectionSection(_ result: QuickLookupService.LookupResult) -> some View {
        let sentences = Array(result.inflectionExamples.prefix(2))
        if sentences.isEmpty && result.isStreaming {
            loadingRow(text: "Çekim örnekleri yükleniyor…")
                .transition(.opacity)
        } else if !sentences.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text("Çekim Örnekleri")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                ForEach(Array(sentences.enumerated()), id: \.offset) { _, sentence in
                    Text(sentence)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(.top, 2)
            .transition(.opacity)
        }
    }

    private func loadingRow(text: String) -> some View {
        HStack(spacing: 6) {
            ProgressView()
                .controlSize(.mini)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 2)
    }
}
