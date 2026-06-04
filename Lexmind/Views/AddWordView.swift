//
//  AddWordView.swift
//  Lexmind
//

import SwiftUI
import SwiftData

struct AddWordView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var term: String = ""
    @State private var analyzer = WordAnalyzer()
    @State private var analysis: WordAnalysis?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    @State private var partOfSpeech = ""
    @State private var ipa = ""
    @State private var countability = ""
    @State private var definition = ""
    @State private var turkishMeaning = ""
    @State private var examples: [String] = ["", "", "", "", ""]
    @State private var notes = ""
    @State private var level: CEFRLevel? = nil
    @State private var selectedTopics: Set<WordTopic> = []
    @State private var familyRoot: String = ""
    @State private var familyMembers: [String] = []
    @State private var synonyms: [String] = []
    @State private var antonyms: [String] = []
    @State private var relatedWords: [String] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Kelime") {
                    HStack {
                        TextField("İngilizce kelime", text: $term)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit(runAnalysis)
                        Button(action: runAnalysis) {
                            if isAnalyzing {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "sparkles")
                            }
                        }
                        .disabled(term.trimmingCharacters(in: .whitespaces).isEmpty || isAnalyzing)
                        .buttonStyle(.borderedProminent)
                    }
                    if let message = analyzer.availabilityMessage {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if let error = errorMessage {
                        Label(error, systemImage: "xmark.octagon.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Analiz") {
                    TextField("Tür (noun / verb …)", text: $partOfSpeech)
                    TextField("IPA (/ˈwɜːrd/)", text: $ipa)
                    TextField("Sayılabilirlik", text: $countability)
                    TextField("Türkçe karşılık", text: $turkishMeaning)
                    TextField("Tanım", text: $definition, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Örnek Cümleler (5)") {
                    ForEach(0..<examples.count, id: \.self) { i in
                        TextField("Cümle \(i + 1)", text: $examples[i], axis: .vertical)
                            .lineLimit(1...3)
                    }
                }

                Section("Seviye & Konu") {
                    Picker("CEFR Seviyesi", selection: $level) {
                        Text("Belirsiz").tag(CEFRLevel?.none)
                        ForEach(CEFRLevel.allCases) { lv in
                            Text(lv.label).tag(CEFRLevel?.some(lv))
                        }
                    }
                    NavigationLink {
                        TopicMultiSelectView(selection: $selectedTopics)
                    } label: {
                        HStack {
                            Text("Konular")
                            Spacer()
                            Text(selectedTopics.isEmpty ? "Seç" :
                                 selectedTopics.map { $0.label }.sorted().joined(separator: ", "))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Section("Notlar") {
                    TextField("Kişisel notların", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle("Yeni Kelime")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet", action: save)
                        .disabled(term.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func runAnalysis() {
        let cleaned = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleaned.isEmpty else { return }
        errorMessage = nil
        isAnalyzing = true
        Task {
            defer { isAnalyzing = false }
            do {
                let result = try await analyzer.analyze(term: cleaned)
                analysis = result
                applyAnalysis(result)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func applyAnalysis(_ a: WordAnalysis) {
        partOfSpeech = a.partOfSpeech
        ipa = a.ipa
        countability = a.countability
        definition = a.definition
        turkishMeaning = a.turkishMeaning
        var newExamples = a.examples
        while newExamples.count < 5 { newExamples.append("") }
        examples = Array(newExamples.prefix(5))
        if let lv = CEFRLevel(rawValue: a.cefrLevel.uppercased()) {
            level = lv
        }
        let parsedTopics = a.topics.compactMap { WordTopic(rawValue: $0.lowercased()) }
        if !parsedTopics.isEmpty {
            selectedTopics = Set(parsedTopics)
        }
        familyRoot = a.familyRoot.lowercased()
        familyMembers = a.familyMembers.map { $0.lowercased() }
        synonyms = a.synonyms.map { $0.lowercased() }
        antonyms = a.antonyms.map { $0.lowercased() }
        relatedWords = a.related.map { $0.lowercased() }
    }

    private func save() {
        let cleanedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanedTerm.isEmpty else { return }

        let filteredExamples = examples
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let trimmedRoot = familyRoot.trimmingCharacters(in: .whitespacesAndNewlines)
        let word = Word(
            term: cleanedTerm,
            partOfSpeech: partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines),
            ipa: ipa.trimmingCharacters(in: .whitespacesAndNewlines),
            countability: countability.trimmingCharacters(in: .whitespacesAndNewlines),
            definition: definition.trimmingCharacters(in: .whitespacesAndNewlines),
            turkishMeaning: turkishMeaning.trimmingCharacters(in: .whitespacesAndNewlines),
            examples: filteredExamples,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            level: level,
            topics: Array(selectedTopics),
            familyRoot: trimmedRoot.isEmpty ? nil : trimmedRoot,
            familyMembers: familyMembers
        )
        let card = FSRSCard()
        card.word = word
        word.card = card
        context.insert(word)

        for term in synonyms where !term.isEmpty {
            word.relations.append(WordRelation(kind: .synonym, targetTerm: term, source: word))
        }
        for term in antonyms where !term.isEmpty {
            word.relations.append(WordRelation(kind: .antonym, targetTerm: term, source: word))
        }
        for term in relatedWords where !term.isEmpty {
            word.relations.append(WordRelation(kind: .related, targetTerm: term, source: word))
        }

        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = "Kaydedilemedi: \(error.localizedDescription)"
        }
    }
}

private struct TopicMultiSelectView: View {
    @Binding var selection: Set<WordTopic>

    var body: some View {
        List {
            Section {
                ForEach(WordTopic.allCases, id: \.id) { topic in
                    Button {
                        if selection.contains(topic) {
                            selection.remove(topic)
                        } else {
                            selection.insert(topic)
                        }
                    } label: {
                        HStack {
                            Label(topic.label, systemImage: topic.symbol)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selection.contains(topic) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Konular")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AddWordView()
        .modelContainer(PreviewData.container)
}
