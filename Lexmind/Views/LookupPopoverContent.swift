//
//  LookupPopoverContent.swift
//  Lexmind
//
//  Standard wrapper around WordQuickLookupCard used by StudyView,
//  ReadingPassageView, and WordDetailView. Owns the `if let lookup`
//  guard and the retry/add closure bridging so callsites only pass
//  service + state + the add-to-library handler.
//

import SwiftUI

struct LookupPopoverContent: View {
    let lookup: QuickLookupService?
    let isAlreadyInLibrary: Bool
    let isAdding: Bool
    let words: [Word]
    var onOpenDetail: ((String) -> Void)? = nil
    let onAdd: (String) async -> Void

    var body: some View {
        if let lookup {
            WordQuickLookupCard(
                phase: lookup.phase,
                isAlreadyInLibrary: isAlreadyInLibrary,
                isAdding: isAdding,
                onOpenDetail: onOpenDetail,
                onAddToLibrary: { term in
                    Task { await onAdd(term) }
                },
                onRetry: { term in
                    Task { await lookup.lookup(term: term, in: words) }
                }
            )
        }
    }
}
