//
//  LibraryImportSummaryRow.swift
//  Lexmind
//
//  Top summary card at the head of the LibraryImportView list — shows
//  the merged library total and how many of those words are already in
//  the user's collection.
//

import SwiftUI

struct LibraryImportSummaryRow: View {
    let existingTerms: Set<String>

    var body: some View {
        let total = MergedLibrary.all.count
        let alreadyIn = existingTerms.intersection(MergedLibrary.allTermSet).count
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(total) kelime")
                    .font(.headline)
                Text("\(alreadyIn) zaten ekli")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "books.vertical.fill")
                .font(.title)
                .foregroundStyle(.tint)
        }
        .padding(.vertical, 4)
    }
}
