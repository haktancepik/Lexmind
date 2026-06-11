//
//  LibraryImportFilterChips.swift
//  Lexmind
//
//  Two horizontal chip rows: CEFR level filter on top, topic filter on
//  the bottom. Bindings flow back to LibraryImportView so the existing
//  filtered/visibleNewCount derivations re-evaluate.
//

import SwiftUI

struct LibraryImportFilterChips: View {
    @Binding var levelFilter: CEFRLevel?
    @Binding var topicFilter: WordTopic?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            levelRow
            topicRow
        }
    }

    private var levelRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CEFRLevel.allCases) { lv in
                    chip(
                        title: lv.label,
                        symbol: "graduationcap",
                        isSelected: levelFilter == lv,
                        tint: libraryImportCEFRColor(lv)
                    ) {
                        levelFilter = (levelFilter == lv) ? nil : lv
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var topicRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WordTopic.allCases) { tp in
                    chip(
                        title: tp.label,
                        symbol: tp.symbol,
                        isSelected: topicFilter == tp,
                        tint: .accentColor
                    ) {
                        topicFilter = (topicFilter == tp) ? nil : tp
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func chip(title: String,
                      symbol: String,
                      isSelected: Bool,
                      tint: Color,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? tint.opacity(0.2) : Color(.tertiarySystemFill))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? tint : .clear, lineWidth: 1)
                )
                .foregroundStyle(isSelected ? tint : Color.primary)
        }
        .buttonStyle(.plain)
    }
}
