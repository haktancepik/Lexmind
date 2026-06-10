//
//  SettingsView.swift
//  Lexmind
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var goals: [DailyGoal]

    private var goal: DailyGoal { goals.first ?? DailyGoal() }

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
        Section("Veri") {
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
            comingSoonRow(
                title: "Tüm verilerimi sil",
                detail: "Faz 2'de aktifleşecek",
                symbol: "trash"
            )
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
            comingSoonRow(
                title: "Gizlilik Politikası",
                detail: "1.10'da bağlanacak",
                symbol: "hand.raised"
            )
            comingSoonRow(
                title: "Kullanım Koşulları",
                detail: "1.10'da bağlanacak",
                symbol: "doc.text"
            )
            comingSoonRow(
                title: "Açık Kaynak Lisansları",
                detail: "1.10'da bağlanacak",
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
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.container)
}
