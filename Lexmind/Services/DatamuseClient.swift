//
//  DatamuseClient.swift
//  Lexmind
//

import Foundation

actor DatamuseClient {
    static let shared = DatamuseClient()

    enum Endpoint {
        case synonyms
        case antonyms
        case related

        var query: String {
            switch self {
            case .synonyms: return "rel_syn"
            case .antonyms: return "rel_ant"
            case .related:  return "rel_trg"
            }
        }

        var max: Int {
            switch self {
            case .synonyms: return 100
            case .antonyms: return 50
            case .related:  return 100
            }
        }
    }

    private struct Hit: Decodable {
        let word: String
    }

    private let session: URLSession
    private var termsCache: [String: Set<String>] = [:]
    private var existsCache: [String: Bool] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func terms(for word: String, endpoint: Endpoint) async -> Set<String> {
        let key = "\(endpoint.query)|\(word.lowercased())"
        if let cached = termsCache[key] { return cached }

        guard let url = buildURL([
            URLQueryItem(name: endpoint.query, value: word.lowercased()),
            URLQueryItem(name: "max", value: String(endpoint.max))
        ]) else { return [] }

        let result = await fetchWords(from: url)
        termsCache[key] = result
        return result
    }

    func wordExists(_ word: String) async -> Bool {
        let key = word.lowercased()
        if let cached = existsCache[key] { return cached }

        guard let url = buildURL([
            URLQueryItem(name: "sp", value: key),
            URLQueryItem(name: "md", value: "p"),
            URLQueryItem(name: "max", value: "1")
        ]) else { return false }

        let hits = await fetchWords(from: url)
        let exists = hits.contains(key)
        existsCache[key] = exists
        return exists
    }

    private func buildURL(_ items: [URLQueryItem]) -> URL? {
        var components = URLComponents(string: "https://api.datamuse.com/words")
        components?.queryItems = items
        return components?.url
    }

    private func fetchWords(from url: URL) async -> Set<String> {
        var request = URLRequest(url: url)
        request.timeoutInterval = 4
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return []
            }
            let hits = try JSONDecoder().decode([Hit].self, from: data)
            return Set(hits.map { $0.word.lowercased() })
        } catch {
            return []
        }
    }
}
