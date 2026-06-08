//
//  TappableText.swift
//  Lexmind
//

import SwiftUI
import UIKit

struct TappableText: UIViewRepresentable {
    let text: String
    let highlightedTerm: String?
    var highlightedTerms: Set<String> = []
    var textStyle: UIFont.TextStyle = .body
    var baseColor: UIColor = .label
    let onTokenTap: (String) -> Void

    func makeUIView(context: Context) -> TappableTextView {
        let textView = TappableTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.adjustsFontForContentSizeCategory = true
        textView.isUserInteractionEnabled = true
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false
        textView.addGestureRecognizer(tap)
        context.coordinator.textView = textView
        return textView
    }

    func updateUIView(_ uiView: TappableTextView, context: Context) {
        context.coordinator.onTokenTap = onTokenTap

        let font = UIFont.preferredFont(forTextStyle: textStyle)
        let attr = NSMutableAttributedString(string: text)
        let full = NSRange(location: 0, length: (text as NSString).length)
        attr.addAttribute(.font, value: font, range: full)
        attr.addAttribute(.foregroundColor, value: baseColor, range: full)

        let highlighted = highlightedTerm?.lowercased()
        let tokens = Tokenizer.tokenize(text)
        var location = 0
        for token in tokens {
            let length = (token.display as NSString).length
            let range = NSRange(location: location, length: length)
            location += length

            if case .word(let normalized) = token.kind {
                if normalized == highlighted || highlightedTerms.contains(normalized) {
                    let bold = UIFont.systemFont(ofSize: font.pointSize, weight: .bold)
                    attr.addAttribute(.font, value: bold, range: range)
                    attr.addAttribute(.foregroundColor, value: UIColor.tintColor, range: range)
                    attr.addAttribute(.lexmindTerm, value: normalized, range: range)
                } else if Tokenizer.stopWords.contains(normalized) {
                    attr.addAttribute(.foregroundColor,
                                      value: baseColor.withAlphaComponent(0.55),
                                      range: range)
                } else {
                    attr.addAttribute(.lexmindTerm, value: normalized, range: range)
                }
            }
        }

        uiView.attributedText = attr
        uiView.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: TappableTextView, context: Context) -> CGSize? {
        let width = proposal.width ?? .greatestFiniteMagnitude
        let target = CGSize(width: width, height: .greatestFiniteMagnitude)
        return uiView.sizeThatFits(target)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        weak var textView: TappableTextView?
        var onTokenTap: ((String) -> Void)?

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            guard let textView, let attributed = textView.attributedText else { return }

            let layoutManager = textView.layoutManager
            let textContainer = textView.textContainer
            let inset = textView.textContainerInset

            var location = recognizer.location(in: textView)
            location.x -= inset.left
            location.y -= inset.top

            let charIndex = layoutManager.characterIndex(for: location,
                                                        in: textContainer,
                                                        fractionOfDistanceBetweenInsertionPoints: nil)
            guard charIndex >= 0, charIndex < attributed.length else { return }

            if let term = attributed.attribute(.lexmindTerm, at: charIndex, effectiveRange: nil) as? String {
                onTokenTap?(term)
            }
        }
    }
}

// MARK: - UITextView subclass

final class TappableTextView: UITextView {}

// MARK: - Custom attribute key

extension NSAttributedString.Key {
    static let lexmindTerm = NSAttributedString.Key("lexmindTerm")
}

// MARK: - Tokenization

struct DisplayToken {
    enum Kind {
        case word(normalized: String)
        case separator
    }
    let display: String
    let kind: Kind
}

enum Tokenizer {

    static let stopWords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "if", "of", "to", "in", "on",
        "at", "by", "for", "with", "as", "is", "are", "was", "were", "be",
        "been", "being", "am", "i", "you", "he", "she", "it", "we", "they",
        "me", "him", "her", "us", "them", "my", "your", "his", "its", "our",
        "their", "this", "that", "these", "those", "do", "does", "did",
        "have", "has", "had", "will", "would", "can", "could", "should",
        "may", "might", "must", "not", "no", "yes", "so", "than", "then",
        "there", "here", "when", "while", "who", "whom", "whose", "what",
        "which", "where", "why", "how", "from", "into", "onto", "out", "up",
        "down", "over", "under", "again", "very", "just", "also", "too"
    ]

    static func tokenize(_ input: String) -> [DisplayToken] {
        var tokens: [DisplayToken] = []
        var currentWord = ""
        var currentSep = ""

        func flushWord() {
            guard !currentWord.isEmpty else { return }
            let display = currentWord
            let normalized = normalize(display)
            if normalized.isEmpty {
                currentSep.append(display)
            } else {
                tokens.append(DisplayToken(display: display, kind: .word(normalized: normalized)))
            }
            currentWord = ""
        }

        func flushSep() {
            guard !currentSep.isEmpty else { return }
            tokens.append(DisplayToken(display: currentSep, kind: .separator))
            currentSep = ""
        }

        for scalar in input.unicodeScalars {
            let ch = Character(scalar)
            if isWordChar(scalar) {
                if !currentSep.isEmpty { flushSep() }
                currentWord.append(ch)
            } else {
                if !currentWord.isEmpty { flushWord() }
                currentSep.append(ch)
            }
        }
        flushWord()
        flushSep()
        return tokens
    }

    private static func isWordChar(_ scalar: Unicode.Scalar) -> Bool {
        if CharacterSet.letters.contains(scalar) { return true }
        if scalar == "'" || scalar == "\u{2019}" || scalar == "-" { return true }
        return false
    }

    private static func normalize(_ display: String) -> String {
        var key = display.lowercased()
        while let first = key.first, first == "'" || first == "\u{2019}" || first == "-" {
            key.removeFirst()
        }
        while let last = key.last, last == "'" || last == "\u{2019}" || last == "-" {
            key.removeLast()
        }
        if key.hasSuffix("'s") || key.hasSuffix("\u{2019}s") {
            key = String(key.dropLast(2))
        }
        guard key.unicodeScalars.contains(where: { CharacterSet.letters.contains($0) }) else {
            return ""
        }
        return key
    }
}
