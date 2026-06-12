//
//  SettingsView.swift
//  Lexmind
//

import SwiftUI
import SwiftData
import os

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var goals: [DailyGoal]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("preferredCEFRLevel") private var preferredCEFRRaw = ""
    @AppStorage("activeDeckID") private var activeDeckIDRaw = ""
    @AppStorage("rootTabSelection") private var rootTabSelection = 0

    @State private var showWipeConfirm = false
    @State private var wipeError: String?

    private var goal: DailyGoal { goals.first ?? DailyGoal() }

    /// Marketing copy promises a Turkish-language privacy policy hosted on the
    /// project's GitHub Pages site. URLs are stable across releases; flip the
    /// Pages source once the static markdown is in place.
    private static let privacyPolicyURL = URL(string: "https://haktancepik.github.io/Lexmind/privacy")!
    private static let termsURL = URL(string: "https://haktancepik.github.io/Lexmind/terms")!

    private var versionLabel: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                headerSection
                dailyGoalSection
                notificationsSection
                languageSection
                dataSection
                proSection
                aboutSection
            }
            .navigationTitle("Ayarlar")
            .onAppear(perform: ensureGoalExists)
            .confirmationDialog(
                "Tüm verilerin silinecek",
                isPresented: $showWipeConfirm,
                titleVisibility: .visible
            ) {
                Button("Tüm verilerimi sil", role: .destructive) { wipeAllData() }
                Button("Vazgeç", role: .cancel) { }
            } message: {
                Text("Kelime listesi, ilerleme, desteler ve okuma metinleri kalıcı olarak silinecek. Bu işlem geri alınamaz.")
            }
            .alert("Silinemedi", isPresented: .constant(wipeError != nil)) {
                Button("Tamam") { wipeError = nil }
            } message: {
                Text(wipeError ?? "")
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            VStack(spacing: 10) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .blue],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                Text("Lexmind")
                    .font(.title2.bold())
                Text("FSRS tabanlı kelime öğrenme")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .listRowBackground(Color.clear)
        }
    }

    private var dailyGoalSection: some View {
        Section("Günlük Hedef") {
            Stepper(value: Binding(get: { goal.newCardsPerDay },
                                   set: { goal.newCardsPerDay = $0 }),
                    in: 0...100, step: 5) {
                LabeledContent("Yeni kelime", value: "\(goal.newCardsPerDay)")
            }
            Stepper(value: Binding(get: { goal.reviewsPerDay },
                                   set: { goal.reviewsPerDay = $0 }),
                    in: 5...500, step: 5) {
                LabeledContent("Günlük tekrar", value: "\(goal.reviewsPerDay)")
            }
        }
    }

    private var notificationsSection: some View {
        Section("Bildirimler") {
            comingSoonRow(
                title: "Günlük hatırlatma",
                detail: "Faz 2'de aktifleşecek",
                symbol: "bell"
            )
        }
    }

    private var languageSection: some View {
        Section("Dil") {
            LabeledContent {
                Text("Türkçe")
                    .foregroundStyle(.secondary)
            } label: {
                Label("Uygulama dili", systemImage: "globe")
            }
            comingSoonRow(
                title: "İngilizce",
                detail: "Faz 3'te eklenecek",
                symbol: "character.book.closed"
            )
        }
    }

    private var dataSection: some View {
        Section {
            comingSoonRow(
                title: "Verilerimi dışa aktar",
                detail: "Faz 2'de aktifleşecek",
                symbol: "square.and.arrow.up"
            )
            comingSoonRow(
                title: "Verilerimi içe aktar",
                detail: "Faz 2'de aktifleşecek",
                symbol: "square.and.arrow.down"
            )
            Button(role: .destructive) {
                showWipeConfirm = true
            } label: {
                Label("Tüm verilerimi sil", systemImage: "trash")
            }
        } header: {
            Text("Veri")
        } footer: {
            Text("Silme işlemi geri alınamaz. CloudKit eşitleme aktif değilken sadece bu cihazdaki kayıtlar etkilenir.")
                .font(.caption)
        }
    }

    private var proSection: some View {
        Section("Lexmind Pro") {
            comingSoonRow(
                title: "Pro'ya geç",
                detail: "Faz 2'de aktifleşecek",
                symbol: "crown"
            )
        }
    }

    private var aboutSection: some View {
        Section("Hakkında") {
            Link(destination: Self.privacyPolicyURL) {
                Label("Gizlilik Politikası", systemImage: "hand.raised")
            }
            Link(destination: Self.termsURL) {
                Label("Kullanım Koşulları", systemImage: "doc.text")
            }
            comingSoonRow(
                title: "Açık Kaynak Lisansları",
                detail: "Faz 3'te eklenecek",
                symbol: "books.vertical"
            )
            LabeledContent {
                Text(versionLabel)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
            } label: {
                Label("Sürüm", systemImage: "number")
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func comingSoonRow(title: String, detail: String, symbol: String) -> some View {
        LabeledContent {
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        } label: {
            Label(title, systemImage: symbol)
                .foregroundStyle(.secondary)
        }
    }

    private func ensureGoalExists() {
        guard goals.isEmpty else { return }
        context.insert(DailyGoal())
        try? context.save()
    }

    /// One-shot wipe of every SwiftData entity plus the AppStorage keys
    /// that survive uninstall-equivalent reset. Bounces the user back
    /// into onboarding so they hit the empty-state hero card instead of
    /// a "0 due, 0 streak" ghost screen.
    private func wipeAllData() {
        do {
            // Order doesn't matter for cascading deletes since relations
            // are inverse-declared; SwiftData handles dependent rows.
            try context.delete(model: ReviewLog.self)
            try context.delete(model: FSRSCard.self)
            try context.delete(model: WordRelation.self)
            try context.delete(model: Word.self)
            try context.delete(model: WordDeck.self)
            try context.delete(model: DailyReadingPassage.self)
            try context.delete(model: DailyGoal.self)
            try context.save()

            // Reset the per-user UX state so the next launch behaves like
            // a fresh install. Subscription receipts (Faz 2) intentionally
            // stay — those belong to the Apple ID, not the data store.
            preferredCEFRRaw = ""
            activeDeckIDRaw = ""
            rootTabSelection = 0
            hasCompletedOnboarding = false

            ReviewPromptManager.resetForTesting()
            Log.app.info("All user data wiped via Settings")
        } catch {
            Log.data.error("Wipe failed: \(error.localizedDescription)")
            wipeError = error.localizedDescription
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.container)
}
