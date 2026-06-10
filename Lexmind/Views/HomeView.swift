//
//  HomeView.swift
//  Lexmind
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query private var words: [Word]
    @Query private var goals: [DailyGoal]
    @Query(sort: \ReviewLog.reviewedAt, order: .reverse) private var reviewLogs: [ReviewLog]

    @State private var showAddWord = false
    @State private var showStudy = false
    @State private var showLibrary = false
    @State private var showReading = false

    private var goal: DailyGoal {
        goals.first ?? DailyGoal()
    }

    private func ensureGoalExists() {
        guard goals.isEmpty else { return }
        context.insert(DailyGoal())
        try? context.save()
    }

    private var dueCount: Int {
        words.filter { ($0.card?.isDue ?? true) }.count
    }

    private var newCount: Int {
        words.filter { ($0.card?.state ?? .new) == .new }.count
    }

    private var reviewedTodayCount: Int {
        let cal = Calendar.current
        return reviewLogs.filter { cal.isDateInToday($0.reviewedAt) }.count
    }

    private var streak: Int {
        guard !reviewLogs.isEmpty else { return 0 }
        let cal = Calendar.current
        var streakDays = 0
        var cursor = Date()
        let logsByDay = Dictionary(grouping: reviewLogs) { cal.startOfDay(for: $0.reviewedAt) }
        while logsByDay[cal.startOfDay(for: cursor)] != nil {
            streakDays += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streakDays
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if words.isEmpty {
                        emptyHeroCard
                    } else {
                        heroCard
                        if reviewedTodayCount > 0 {
                            readingCard
                        }
                        statsRow
                        if !nextDueWords.isEmpty {
                            upcomingSection
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Lexmind")
            .onAppear(perform: ensureGoalExists)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showAddWord = true
                        } label: {
                            Label("Yeni Kelime", systemImage: "plus")
                        }
                        Button {
                            showLibrary = true
                        } label: {
                            Label("Hazır Kütüphane", systemImage: "books.vertical")
                        }
                    } label: {
                        Label("Ekle", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddWord) {
                AddWordView()
            }
            .sheet(isPresented: $showLibrary) {
                LibraryImportView()
            }
            .fullScreenCover(isPresented: $showStudy) {
                StudyView(onRequestReading: {
                    showReading = true
                })
            }
            .sheet(isPresented: $showReading) {
                NavigationStack {
                    ReadingPassageView()
                }
            }
        }
    }

    private var nextDueWords: [Word] {
        words
            .filter { $0.card != nil }
            .sorted { ($0.card?.due ?? .now) < ($1.card?.due ?? .now) }
            .prefix(5)
            .map { $0 }
    }

    private var emptyHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(.purple)
                Text("Hadi başlayalım")
                    .font(.title2.bold())
                Spacer()
            }

            Text("Henüz kelime eklemedin. İlk kelimelerini ekleyerek FSRS döngüsünü başlat.")
                .font(.body)
                .foregroundStyle(.secondary)

            Button {
                showLibrary = true
            } label: {
                Label("Hazır Kütüphaneden Ekle", systemImage: "books.vertical.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 4)

            Button {
                showAddWord = true
            } label: {
                Label("Tek Kelime Ekle", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                Text(greeting)
                    .font(.title2.bold())
                Spacer()
            }

            Text(dueCount > 0
                 ? "Bugün gözden geçirilecek **\(dueCount)** kelimen var."
                 : "Bugünlük tüm tekrarlarını tamamladın 🎉")
                .font(.body)

            ProgressView(value: Double(reviewedTodayCount),
                         total: Double(max(goal.reviewsPerDay, 1)))
                .tint(.accentColor)

            HStack {
                Label("\(reviewedTodayCount)/\(goal.reviewsPerDay) tekrar",
                      systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Label("\(streak) gün serisi", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Button {
                showStudy = true
            } label: {
                Label(dueCount > 0 ? "Çalışmaya Başla" : "Yeni Kelime Öğren",
                      systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    private var readingCard: some View {
        NavigationLink {
            ReadingPassageView()
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "book.pages.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(colors: [.purple, .pink],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Bugünün Okuma Metni")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text("Bugün çalıştığın \(reviewedTodayCount) tekrar üzerinden bağlamlı bir metin.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
            )
        }
        .buttonStyle(.plain)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(words.count)", label: "Toplam", icon: "books.vertical.fill", tint: .blue)
            statCard(value: "\(newCount)", label: "Yeni", icon: "sparkles", tint: .purple)
            statCard(value: "\(dueCount)", label: "Bekleyen", icon: "clock.badge.exclamationmark", tint: .orange)
        }
    }

    private func statCard(value: String, label: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Yaklaşan tekrarlar").font(.headline)
            ForEach(nextDueWords) { word in
                NavigationLink {
                    WordDetailView(word: word)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(word.term).font(.body.bold())
                            Text(word.partOfSpeech)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let due = word.card?.due {
                            Text(due, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                Divider()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Günaydın 👋"
        case 12..<17: return "İyi günler 👋"
        case 17..<22: return "İyi akşamlar 👋"
        default: return "Merhaba 👋"
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewData.container)
}
