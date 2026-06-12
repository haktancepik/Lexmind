//
//  RootTabView.swift
//  Lexmind
//
//  Tab selection is persisted in @AppStorage so deep-link shortcuts
//  (e.g. "Bu desteyi çalış" from DeckDetailView) can switch tabs by
//  writing the same key. Selection survives app relaunch by design.
//

import SwiftUI
import SwiftData

enum RootTab: Int, Hashable {
    case home = 0
    case words = 1
    case decks = 2
    case study = 3
    case stats = 4
    case settings = 5
}

struct RootTabView: View {
    @AppStorage("rootTabSelection") private var selectionRaw: Int = RootTab.home.rawValue

    private var selection: Binding<Int> {
        Binding(get: { selectionRaw }, set: { selectionRaw = $0 })
    }

    var body: some View {
        TabView(selection: selection) {
            Tab("Bugün", systemImage: "sun.max.fill", value: RootTab.home.rawValue) {
                HomeView()
            }

            Tab("Kelimeler", systemImage: "books.vertical.fill", value: RootTab.words.rawValue) {
                WordsListView()
            }

            Tab("Desteler", systemImage: "rectangle.stack.fill", value: RootTab.decks.rawValue) {
                DecksView()
            }

            Tab("Çalış", systemImage: "brain.head.profile", value: RootTab.study.rawValue) {
                StudyView()
            }

            Tab("İstatistik", systemImage: "chart.bar.xaxis", value: RootTab.stats.rawValue) {
                StatsView()
            }

            Tab("Ayarlar", systemImage: "gearshape.fill", value: RootTab.settings.rawValue) {
                SettingsView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    RootTabView()
        .modelContainer(PreviewData.container)
        .environment(EntitlementsService())
}
