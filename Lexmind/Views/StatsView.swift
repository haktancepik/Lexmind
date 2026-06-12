//
//  StatsView.swift
//  Lexmind
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var words: [Word]
    @Query(sort: \ReviewLog.reviewedAt, order: .reverse) private var logs: [ReviewLog]

    private struct DayCount: Identifiable {
        let id = UUID()
        let day: Date
        let count: Int
    }

    private struct RatingCount: Identifiable {
        let id = UUID()
        let rating: ReviewRating
        let count: Int
    }

    private struct StateCount: Identifiable {
        let id = UUID()
        let state: CardState
        let count: Int
    }

    private var totals: (total: Int, new: Int, learning: Int, review: Int, relearning: Int) {
        var n = 0, l = 0, r = 0, rl = 0
        for w in words {
            switch w.card?.state ?? .new {
            case .new: n += 1
            case .learning: l += 1
            case .review: r += 1
            case .relearning: rl += 1
            }
        }
        return (words.count, n, l, r, rl)
    }

    private var last14Days: [DayCount] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var buckets: [Date: Int] = [:]
        for offset in 0..<14 {
            if let day = cal.date(byAdding: .day, value: -offset, to: today) {
                buckets[day] = 0
            }
        }
        for log in logs {
            let day = cal.startOfDay(for: log.reviewedAt)
            if buckets[day] != nil {
                buckets[day, default: 0] += 1
            }
        }
        return buckets
            .map { DayCount(day: $0.key, count: $0.value) }
            .sorted { $0.day < $1.day }
    }

    private var ratingCounts: [RatingCount] {
        var dict: [ReviewRating: Int] = [:]
        for log in logs { dict[log.rating, default: 0] += 1 }
        return ReviewRating.allCases.map { RatingCount(rating: $0, count: dict[$0] ?? 0) }
    }

    private var stateCounts: [StateCount] {
        let t = totals
        return [
            StateCount(state: .new, count: t.new),
            StateCount(state: .learning, count: t.learning),
            StateCount(state: .review, count: t.review),
            StateCount(state: .relearning, count: t.relearning)
        ]
    }

    private var accuracy: Double {
        guard !logs.isEmpty else { return 0 }
        let correct = logs.filter { $0.rating != .again }.count
        return Double(correct) / Double(logs.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryGrid
                    reviewsChart
                    ratingChart
                    stateChart
                }
                .padding()
            }
            .navigationTitle("İstatistik")
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statTile("Toplam Kelime", value: "\(totals.total)",
                     icon: "books.vertical.fill", color: .blue)
            statTile("Toplam Tekrar", value: "\(logs.count)",
                     icon: "repeat", color: .green)
            statTile("Başarı Oranı", value: percentString(accuracy),
                     icon: "target", color: .orange)
            statTile("Öğrenilen", value: "\(totals.review)",
                     icon: "checkmark.seal.fill", color: .purple)
        }
    }

    private func statTile(_ title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Spacer()
            }
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(title): \(value)"))
    }

    private var reviewsChart: some View {
        chartCard(title: "Son 14 gün tekrar", icon: "calendar") {
            Chart(last14Days) { item in
                BarMark(
                    x: .value("Gün", item.day, unit: .day),
                    y: .value("Tekrar", item.count)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(4)
                .accessibilityLabel(Text(item.day.formatted(.dateTime.day().month())))
                .accessibilityValue(Text("\(item.count) tekrar"))
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.narrow))
                }
            }
            .accessibilityLabel(Text("Son 14 günün günlük tekrar sayısı grafiği"))
        }
    }

    private var ratingChart: some View {
        chartCard(title: "Cevap dağılımı", icon: "chart.pie.fill") {
            if logs.isEmpty {
                Text("Henüz tekrar yapılmadı.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Chart(ratingCounts) { item in
                    SectorMark(
                        angle: .value("Adet", item.count),
                        innerRadius: .ratio(0.55),
                        angularInset: 1
                    )
                    .foregroundStyle(by: .value("Tepki", item.rating.label))
                    .cornerRadius(4)
                    .accessibilityLabel(Text(item.rating.label))
                    .accessibilityValue(Text("\(item.count) tekrar"))
                }
                .frame(height: 200)
                .chartForegroundStyleScale([
                    ReviewRating.again.label: Color.red,
                    ReviewRating.hard.label: Color.orange,
                    ReviewRating.good.label: Color.green,
                    ReviewRating.easy.label: Color.blue
                ])
                .accessibilityLabel(Text("Cevap derecelendirmelerinin dağılımı"))
            }
        }
    }

    private var stateChart: some View {
        chartCard(title: "Kart durumları", icon: "rectangle.stack.fill") {
            Chart(stateCounts) { item in
                BarMark(
                    x: .value("Adet", item.count),
                    y: .value("Durum", item.state.label)
                )
                .foregroundStyle(by: .value("Durum", item.state.label))
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(Text(item.state.label))
                .accessibilityValue(Text("\(item.count) kelime"))
            }
            .frame(height: 200)
            .chartForegroundStyleScale([
                CardState.new.label: Color.purple,
                CardState.learning.label: Color.blue,
                CardState.review.label: Color.green,
                CardState.relearning.label: Color.orange
            ])
            .accessibilityLabel(Text("FSRS kart durumlarının dağılımı"))
        }
    }

    private func chartCard<C: View>(title: String, icon: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    private func percentString(_ value: Double) -> String {
        let pct = Int((value * 100).rounded())
        return "\(pct)%"
    }
}

#Preview {
    StatsView()
        .modelContainer(PreviewData.container)
}
