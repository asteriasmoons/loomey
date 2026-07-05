//
//  BookRecommendationService.swift
//  Lumey
//

import Foundation

struct LumeyBookRecommendation: Identifiable, Codable {
    let id = UUID()

    let title: String
    let author: String
    let summary: String
    let coverUrl: String?
    let pages: Int?
    let releaseYear: Int?
    let rating: Double?
    let tags: [String]?
    let source: String?

    enum CodingKeys: String, CodingKey {
        case title
        case author
        case summary
        case coverUrl
        case pages
        case releaseYear
        case rating
        case tags
        case source
    }
}

struct LumeyBookRecommendationsResponse: Codable {
    let recs: [LumeyBookRecommendation]
}

struct LumeyBookRecommendationErrorResponse: Codable {
    let error: String?
    let detail: String?
}

enum LumeyBookRecommendationServiceError: LocalizedError {
    case badURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "The recommendation service URL is invalid."
        case .invalidResponse:
            return "The recommendation service returned an invalid response."
        case .serverError(_, let message):
            return message
        }
    }
}

final class LumeyBookRecommendationService {

    static let shared = LumeyBookRecommendationService()

    private init() {}

    private let baseURL = "https://lystaria-api-production.up.railway.app"

    func fetchRecommendations(for searchText: String) async throws -> [LumeyBookRecommendation] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        print("Book recommendation request started")
        print("Search text:", trimmedSearchText)
        print("Base URL:", baseURL)

        guard let url = URL(string: "\(baseURL)/api/books/recs") else {
            throw LumeyBookRecommendationServiceError.badURL
        }

        let body: [String: String] = [
            "genre": trimmedSearchText
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let rawString = String(data: data, encoding: .utf8) {
            print("Book recommendation response body:")
            print(rawString)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LumeyBookRecommendationServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let backendError = try? JSONDecoder().decode(LumeyBookRecommendationErrorResponse.self, from: data)
            let message = backendError?.detail ?? backendError?.error ?? "Server returned status code \(httpResponse.statusCode)"

            print("Book recommendation HTTP error:", httpResponse.statusCode)
            print("Book recommendation error message:", message)

            throw LumeyBookRecommendationServiceError.serverError(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }

        do {
            let decoded = try JSONDecoder().decode(LumeyBookRecommendationsResponse.self, from: data)
            print("Recommendations loaded:", decoded.recs.count)
            return decoded.recs
        } catch {
            print("Book recommendation JSON decode error:", error)

            if let rawString = String(data: data, encoding: .utf8) {
                print("Failed recommendation JSON:")
                print(rawString)
            }

            throw error
        }
    }
}
