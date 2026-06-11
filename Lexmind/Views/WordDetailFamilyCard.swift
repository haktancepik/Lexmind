//
//  WordDetailFamilyCard.swift
//  Lexmind
//
//  Word family card: the root term (if known) and member chips that
//  branch off it. The card only shows up when there's something to
//  display — or while AI enrichment is in flight (showsLoading).
//

import SwiftUI

struct WordDetailFamilyCard: View {
    let word: Word
    let isRegenerating: Bool
    let isVerifying: Bool
    let hasVerifierError: Bool
    let termExists: (String) -> Bool
    let onTermTap: (String) -> Void

    private var hasRoot: Bool { word.familyRoot?.isEmpty == false }
    private var hasMembers: Bool { !word.familyMembers.isEmpty }
    private var showsLoading: Bool { !hasRoot && !hasMembers && isRegenerating }

    var body: some View {
        if hasRoot || hasMembers || showsLoading {
            WordDetailSectionCard(title: "Kelime Ailesi",
                                  icon: "person.3",
                                  isWorking: isVerifying) {
                if showsLoading {
                    WordDetailLoadingRow(text: "Kelime ailesi yükleniyor…")
                        .transition(.opacity)
                } else {
                    content
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: word.familyMembers.count)
            .animation(.easeInOut(duration: 0.25), value: isVerifying)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isVerifying && !hasVerifierError {
                WordDetailVerifyingBadge()
            }
            if let root = word.familyRoot, !root.isEmpty {
                HStack(spacing: 6) {
                    Text("Kök:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button {
                        onTermTap(root)
                    } label: {
                        Text(root)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            if hasMembers {
                let verifiedSet = Set(word.familyMembersVerifiedRaw)
                WordDetailChipsRow(
                    items: word.familyMembers.map {
                        WordDetailRelationChip(
                            term: $0,
                            origin: verifiedSet.contains($0.lowercased()) ? .verified : .ai
                        )
                    },
                    termExists: termExists,
                    onTap: onTermTap
                )
            }
        }
    }
}
