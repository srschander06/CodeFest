//
//  RecommendationFeed.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/12/25.
//


import Foundation

struct RecommendationFeed: Decodable {
    let memberID: String
    let recommendations: [String: Category]

    enum CodingKeys: String, CodingKey {
        case memberID = "member_id"
        case recommendations
    }

    struct Category: Decodable {
        let createdAt: Date
        let items: [Item]

        enum CodingKeys: String, CodingKey {
            case createdAt = "created_at"
            case items
        }
    }

    struct Item: Decodable, Identifiable, Hashable {
        var id: String { name }
        let url: String
        let name: String
        let description: String
        let category: String?
        let bestTime: String?
        let dressCode: String?
        let venueType: String?
    }
}

// MARK: - Loader
func loadRecommendations() -> RecommendationFeed? {
    guard let url = Bundle.main.url(forResource: "recommendations_MB789456123", withExtension: "json") else {
        print(" Recommendations JSON not found in bundle.")
        return nil
    }

    do {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let feed = try decoder.decode(RecommendationFeed.self, from: data)
        print(" Loaded \(feed.recommendations.keys.count) recommendation categories")
        return feed
    } catch {
        print(" Failed to decode recommendations:", error)
        return nil
    }
}
