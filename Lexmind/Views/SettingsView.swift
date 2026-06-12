//
//  SettingsView.swift
//  Lexmind
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import os

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var goals: [DailyGoal]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("preferredCEFRLevel") private var preferredCEFRRaw = ""
    @AppStorage("activeDeckID") private var activeDeckIDRaw = ""
    @AppStorage("rootTabSelection") private var rootTabSelection = 0

    @AppStorage("notif.dailyEnabled") private var notifEnabled = false
    @AppStorage("notif.reminderHour") private var notifHour = 19
    @AppStorage("notif.reminderMinute") private var notifMinute = 30

    @State private var notifAuthorization: NotificationScheduler.AuthorizationResult = .notDetermined
    @State private var notifDeniedMessage: String?

    @State private var showWipeConfirm = false
    @State private var wipeError: String?

    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var showImportPicker = false
    @State private var importSummary: BackupService.ImportSummary?
    @State private var pendingImportData: Data?
    @State private var importError: String?
    @State private var importSuccessMessage: String?

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
            .task { notifAuthorization = await NotificationScheduler.currentAuthorizationStatus() }
            .alert("Bildirim izni reddedildi", isPresented: .constant(notifDeniedMessage != nil)) {
                Button("Tamam") { notifDeniedMessage = nil }
            } message: {
                Text(notifDeniedMessage ?? "")
            }
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
            .alert("Dışa aktarılamadı", isPresented: .constant(exportError != nil)) {
                Button("Tamam") { exportError = nil }
            } message: {
                Text(exportError ?? "")
            }
            .sheet(isPresented: .constant(exportURL != nil), onDismiss: { exportURL = nil }) {
                if let url = exportURL {
                    ShareLink(item: url) {
                        Label("Yedeği paylaş", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .presentationDetents([.medium])
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportPicked(result)
            }
            .sheet(isPresented: .constant(importSummary != nil), onDismiss: {
                pendingImportData = nil
            }) {
                if let summary = importSummary {
                    importConfirmSheet(summary: summary)
                }
            }
            .alert("İçe aktarılamadı", isPresented: .constant(importError != nil)) {
                Button("Tamam") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
            .alert("İçe aktarıldı", isPresented: .constant(importSuccessMessage != nil)) {
                Button("Tamam") { importSuccessMessage = nil }
            } message: {
                Text(importSuccessMessage ?? "")
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
        Section {
            Toggle(isOn: Binding(
                get: { notifEnabled },
                set: { newValue in Task { await handleNotifToggle(newValue) } }
            )) {
                Label("Günlük hatırlatma", systemImage: "bell")
            }
            if notifEnabled {
                DatePicker(
                    "Hatırlatma saati",
                    selection: Binding(
                        get: { dateFromHourMinute() },
                        set: { newDate in handleTimeChanged(newDate) }
                    ),
                    displayedComponents: [.hourAndMinute]
                )
            }
        } header: {
            Text("Bildirimler")
        } footer: {
            if notifAuthorization == .denied {
                Text("iOS Ayarlar'dan Lexmind için bildirim iznini açmadan hatırlatma planlanamaz.")
                    .font(.caption)
            } else if notifEnabled {
                Text("Her gün seçtiğin saatte bekleyen tekrar için tek bildirim gönderilir.")
                    .font(.caption)
            }
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
            Button {
                runExport()
            } label: {
                Label("Verilerimi dışa aktar", systemImage: "square.and.arrow.up")
            }
            Button {
                showImportPicker = true
            } label: {
                Label("Verilerimi içe aktar", systemImage: "square.and.arrow.down")
            }
            Button(role: .destructive) {
                showWipeConfirm = true
            } label: {
                Label("Tüm verilerimi sil", systemImage: "trash")
            }
        } header: {
            Text("Veri")
        } footer: {
            Text("Dışa aktarma kelimelerini, ilerlemeni, kullanıcı destelerini ve geçmişini tek bir JSON dosyasına yazar. Silme geri alınamaz.")
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

    // MARK: - Notifications

    /// Reacts to the daily-reminder toggle. If turning on, we lazily
    /// ask for system permission (App Store guideline 5.4: prompt only
    /// in response to user action). If the user denies, the toggle
    /// snaps back off so the UI never lies about what's scheduled.
    @MainActor
    private func handleNotifToggle(_ newValue: Bool) async {
        if newValue {
            let status = await NotificationScheduler.currentAuthorizationStatus()
            notifAuthorization = status

            let granted: Bool
            switch status {
            case .granted:
                granted = true
            case .notDetermined:
                granted = await NotificationScheduler.requestAuthorization()
                notifAuthorization = granted ? .granted : .denied
            case .denied:
                granted = false
            }

            guard granted else {
                notifEnabled = false
                notifDeniedMessage = "Hatırlatma kurabilmek için iOS Ayarlar → Bildirimler → Lexmind'tan izin vermen gerekiyor."
                return
            }

            notifEnabled = true
            await NotificationScheduler.scheduleDailyReminder(hour: notifHour, minute: notifMinute)
        } else {
            notifEnabled = false
            NotificationScheduler.cancelDailyReminder()
        }
    }

    private func dateFromHourMinute() -> Date {
        var components = DateComponents()
        components.hour = notifHour
        components.minute = notifMinute
        return Calendar.current.date(from: components) ?? Date()
    }

    private func handleTimeChanged(_ newDate: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
        notifHour = components.hour ?? 19
        notifMinute = components.minute ?? 30
        guard notifEnabled, notifAuthorization == .granted else { return }
        Task {
            await NotificationScheduler.scheduleDailyReminder(hour: notifHour, minute: notifMinute)
        }
    }

    // MARK: - Backup / Restore

    private func runExport() {
        let service = BackupService(context: context)
        do {
            let data = try service.export()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            let stamp = formatter.string(from: .now)
                .replacingOccurrences(of: ":", with: "-")
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("lexmind-backup-\(stamp).json")
            try data.write(to: url, options: .atomic)
            exportURL = url
            Log.data.info("Backup exported — \(data.count) bytes")
        } catch {
            Log.data.error("Backup export failed: \(error.localizedDescription)")
            exportError = error.localizedDescription
        }
    }

    private func handleImportPicked(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importError = error.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            let needsScope = url.startAccessingSecurityScopedResource()
            defer { if needsScope { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                let service = BackupService(context: context)
                let summary = try service.importPayload(data: data, dryRun: true)
                pendingImportData = data
                importSummary = summary
            } catch {
                Log.data.error("Backup import dry-run failed: \(error.localizedDescription)")
                importError = error.localizedDescription
            }
        }
    }

    @ViewBuilder
    private func importConfirmSheet(summary: BackupService.ImportSummary) -> some View {
        NavigationStack {
            Form {
                Section("Yedek özeti") {
                    LabeledContent("Şema sürümü", value: "v\(summary.payloadVersion)")
                    LabeledContent("Toplam kelime", value: "\(summary.totalWordsInPayload)")
                    LabeledContent("Yeni eklenecek", value: "\(summary.newWords)")
                    LabeledContent("Zaten ekli (atlanır)", value: "\(summary.skippedExistingWords)")
                    LabeledContent("Tekrar logları", value: "\(summary.logsInPayload)")
                    LabeledContent("Yeni kullanıcı destesi", value: "\(summary.newUserDecks)")
                    LabeledContent("Günlük hedef", value: summary.goalReplaced ? "Üzerine yazılacak" : "—")
                }
                Section {
                    Button("İçe aktarmayı onayla") {
                        applyImport()
                    }
                    .frame(maxWidth: .infinity)
                }
                Section {
                    Button("Vazgeç", role: .cancel) {
                        importSummary = nil
                        pendingImportData = nil
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("İçe aktar")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private func applyImport() {
        guard let data = pendingImportData else {
            importSummary = nil
            return
        }
        let service = BackupService(context: context)
        do {
            let final = try service.importPayload(data: data, dryRun: false)
            importSummary = nil
            pendingImportData = nil
            importSuccessMessage = "\(final.newWords) yeni kelime, \(final.newUserDecks) yeni deste eklendi."
        } catch {
            Log.data.error("Backup import apply failed: \(error.localizedDescription)")
            importSummary = nil
            pendingImportData = nil
            importError = error.localizedDescription
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
