//
//  DatamuseClient.swift
//  Lexmind
//

import Foundation
import os

enum DatamuseError: Error, Equatable, Sendable {
    case offline
    case timeout
    case serverError(Int)
    case invalidResponse
    case invalidQuery

    var userMessage: String {
        switch self {
        case .offline:         return "Sözlük servisine bağlanılamadı"
        case .timeout:         return "Sözlük servisi yanıt vermedi"
        case .serverError:     return "Sözlük servisi geçici olarak yanıt vermiyor"
        case .invalidResponse: return "Sözlük yanıtı işlenemedi"
        case .invalidQuery:    return "Sözlük sorgusu hazırlanamadı"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .offline, .timeout, .serverError: return true
        case .invalidResponse, .invalidQuery:  return false
        }
    }
}

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

    func terms(for word: String, endpoint: Endpoint) async -> Result<Set<String>, DatamuseError> {
        let key = "\(endpoint.query)|\(word.lowercased())"
        if let cached = termsCache[key] { return .success(cached) }

        guard let url = buildURL([
            URLQueryItem(name: endpoint.query, value: word.lowercased()),
            URLQueryItem(name: "max", value: String(endpoint.max))
        ]) else { return .failure(.invalidQuery) }

        let result = await fetchWords(from: url, retriesRemaining: 1)
        if case .success(let set) = result { termsCache[key] = set }
        return result
    }

    func wordExists(_ word: String) async -> Result<Bool, DatamuseError> {
        let key = word.lowercased()
        if let cached = existsCache[key] { return .success(cached) }

        guard let url = buildURL([
            URLQueryItem(name: "sp", value: key),
            URLQueryItem(name: "md", value: "p"),
            URLQueryItem(name: "max", value: "1")
        ]) else { return .failure(.invalidQuery) }

        let hitsResult = await fetchWords(from: url, retriesRemaining: 1)
        switch hitsResult {
        case .success(let hits):
            let exists = hits.contains(key)
            existsCache[key] = exists
            return .success(exists)
        case .failure(let err):
            return .failure(err)
        }
    }

    private func buildURL(_ items: [URLQueryItem]) -> URL? {
        var components = URLComponents(string: "https://api.datamuse.com/words")
        components?.queryItems = items
        return components?.url
    }

    private func fetchWords(from url: URL, retriesRemaining: Int) async -> Result<Set<String>, DatamuseError> {
        var request = URLRequest(url: url)
        request.timeoutInterval = 4
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            guard (200..<300).contains(http.statusCode) else {
                return .failure(.serverError(http.statusCode))
            }
            do {
                let hits = try JSONDecoder().decode([Hit].self, from: data)
                return .success(Set(hits.map { $0.word.lowercased() }))
            } catch {
                Log.network.error("Datamuse decode failed: \(error.localizedDescription)")
                return .failure(.invalidResponse)
            }
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut:
                if retriesRemaining > 0 {
                    return await fetchWords(from: url, retriesRemaining: retriesRemaining - 1)
                }
                return .failure(.timeout)
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .dnsLookupFailed,
                 .internationalRoamingOff,
                 .dataNotAllowed:
                return .failure(.offline)
            default:
                return .failure(.offline)
            }
        } catch {
            return .failure(.invalidResponse)
        }
    }
}
