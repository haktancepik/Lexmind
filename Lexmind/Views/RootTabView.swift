//
//  RootTabView.swift
//  Lexmind
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Bugün", systemImage: "sun.max.fill") {
                HomeView()
            }

            Tab("Kelimeler", systemImage: "books.vertical.fill") {
                WordsListView()
            }

            Tab("Çalış", systemImage: "brain.head.profile") {
                StudyView()
            }

            Tab("İstatistik", systemImage: "chart.bar.xaxis") {
                StatsView()
            }

            Tab("Ayarlar", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    RootTabView()
        .modelContainer(PreviewData.container)
}
