//
//  ContentView.swift
//  Lexmind
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        RootTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
}
