//
//  OnboardingView.swift
//  Lexmind
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var goals: [DailyGoal]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("preferredCEFRLevel") private var preferredCEFRRaw = ""

    @State private var currentPage = 0
    @State private var selectedLevel: CEFRLevel? = nil
    @State private var dailyNew: Int = 10
    @State private var dailyReviews: Int = 50
    @State private var showLibrary = false
    @State private var libraryInitialLevel: CEFRLevel? = nil

    private static let pageCount = 4

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    levelPage.tag(1)
                    goalPage.tag(2)
                    libraryPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                bottomBar
            }
        }
        .sheet(isPresented: $showLibrary, onDismiss: complete) {
            LibraryImportView(initialLevel: libraryInitialLevel)
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        pageScaffold(
            symbol: "brain.head.profile",
            tint: LinearGradient(colors: [.purple, .blue],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing),
            title: "Lexmind'a hoş geldin",
            subtitle: "İngilizce kelimeleri FSRS spaced repetition ile öğren, gerçekten kalıcı yap."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                bulletRow(icon: "brain", text: "FSRS algoritması: bilimsel olarak optimize edilmiş tekrar zamanlaması")
                bulletRow(icon: "books.vertical", text: "5000+ kelimelik hazır CEFR seviyeli kütüphane")
                bulletRow(icon: "book.pages", text: "Apple Intelligence ile bağlamlı okuma metinleri")
            }
            .padding(.top, 8)
        }
    }

    private var levelPage: some View {
        pageScaffold(
            symbol: "graduationcap.fill",
            tint: LinearGradient(colors: [.orange, .pink],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing),
            title: "İngilizce seviyen?",
            subtitle: "Kütüphaneyi sana göre filtreleyeceğiz. Emin değilsen sonra Ayarlar'dan değiştirebilirsin."
        ) {
            VStack(spacing: 8) {
                ForEach(CEFRLevel.allCases) { level in
                    levelButton(level)
                }
                Button {
                    selectedLevel = nil
                } label: {
                    Text("Şu an seçmek istemiyorum")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var goalPage: some View {
        pageScaffold(
            symbol: "target",
            tint: LinearGradient(colors: [.green, .teal],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing),
            title: "Günlük hedef",
            subtitle: "Her gün ne kadar zaman ayırabilirsin? Sonra Ayarlar'dan ayarlayabilirsin."
        ) {
            VStack(spacing: 16) {
                Stepper(value: $dailyNew, in: 0...50, step: 5) {
                    LabeledContent("Yeni kelime", value: "\(dailyNew)")
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.regularMaterial)
                )

                Stepper(value: $dailyReviews, in: 5...200, step: 5) {
                    LabeledContent("Günlük tekrar", value: "\(dailyReviews)")
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.regularMaterial)
                )

                Text("Önerilen: 10 yeni / 50 tekrar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var libraryPage: some View {
        pageScaffold(
            symbol: "books.vertical.fill",
            tint: LinearGradient(colors: [.indigo, .purple],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing),
            title: "Kelime kütüphanesi",
            subtitle: "5000+ CEFR seviyeli kelimeden başlangıç için birkaçını ekleyelim mi?"
        ) {
            VStack(spacing: 12) {
                if let suggested = selectedLevel {
                    levelSuggestionCard(for: suggested)
                    fullLibraryButton(prominent: false, label: "Tüm kütüphaneyi göster")
                } else {
                    fullLibraryButton(prominent: true, label: "Hazır kütüphaneden ekle")
                }

                Button {
                    persistChoices()
                    complete()
                } label: {
                    Text("Şimdilik atla, kendim ekleyeceğim")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func fullLibraryButton(prominent: Bool, label: String) -> some View {
        if prominent {
            Button {
                persistChoices()
                libraryInitialLevel = nil
                showLibrary = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "books.vertical")
                    Text(label).font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        } else {
            Button {
                persistChoices()
                libraryInitialLevel = nil
                showLibrary = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "books.vertical")
                    Text(label).font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    @ViewBuilder
    private func levelSuggestionCard(for level: CEFRLevel) -> some View {
        let count = MergedLibrary.filtered(level: level, topic: nil).count
        Button {
            persistChoices()
            libraryInitialLevel = level
            showLibrary = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Senin için önerilen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(level.label) destesi — \(count) kelime")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 14) {
            pageDots
            if currentPage < Self.pageCount - 1 {
                Button {
                    withAnimation { currentPage += 1 }
                } label: {
                    Text("Devam")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<Self.pageCount, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: i == currentPage ? 18 : 6, height: 6)
                    .animation(.easeInOut, value: currentPage)
            }
        }
    }

    // MARK: - Reusable bits

    @ViewBuilder
    private func pageScaffold<Content: View, Tint: ShapeStyle>(
        symbol: String,
        tint: Tint,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: symbol)
                    .font(.system(size: 56))
                    .foregroundStyle(tint)
                    .padding(.top, 28)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.largeTitle.bold())
                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private func bulletRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func levelButton(_ level: CEFRLevel) -> some View {
        let isSelected = selectedLevel == level
        Button {
            selectedLevel = level
        } label: {
            HStack {
                Text(level.label)
                    .font(.headline)
                    .frame(width: 40, alignment: .leading)
                Text(levelDescription(level))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(.tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func levelDescription(_ level: CEFRLevel) -> String {
        switch level {
        case .a1: return "Başlangıç"
        case .a2: return "Temel"
        case .b1: return "Orta öncesi"
        case .b2: return "Orta üstü"
        case .c1: return "İleri"
        case .c2: return "Uzman"
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.accentColor.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Persistence

    private func persistChoices() {
        preferredCEFRRaw = selectedLevel?.rawValue ?? ""
        let target = goals.first ?? {
            let new = DailyGoal()
            context.insert(new)
            return new
        }()
        target.newCardsPerDay = dailyNew
        target.reviewsPerDay = dailyReviews
        try? context.save()
    }

    private func complete() {
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView()
        .modelContainer(PreviewData.container)
}
