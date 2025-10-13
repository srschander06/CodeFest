//
//  ItineraryGenerator.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/13/25.
//


import Foundation
import FoundationModels
import Observation

@Observable
@MainActor
final class PersonalizedItineraryGenerator {
    private var session: LanguageModelSession
    private(set) var itineraryText: String?
    private(set) var isLoading = false
    private(set) var error: Error?

    init() {
        let instructions = Instructions {
            """
            You are a Marriott Bonvoy concierge.
            Use the user's travel and dining preferences plus local recommendations
            to generate a personalized 1-day itinerary.

            Include morning, afternoon, and evening activities with dining and relaxation suggestions.
            Output short paragraphs for each time period.
            """
        }
        session = LanguageModelSession(instructions: instructions)
    }

    func generatePersonalizedItinerary() async {
        guard let user = loadUserProfile(), let feed = loadRecommendations() else {
            print("❌ Missing local JSON data.")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Pull key recommendation info
            let allItems = feed.recommendations.values.flatMap(\.items)
            let sample = allItems.prefix(6).map { "• \($0.name)" }.joined(separator: "\n")

            let interests = user.travelPreferences.interests.joined(separator: ", ")
            let prompt = Prompt {
                """
                Create a 1-day itinerary in Blacksburg, VA for \(user.name),
                a Marriott Bonvoy \(user.tier) member who enjoys \(interests).

                Sample local places they might like:
                \(sample)

                Include breakfast, midday activity, dinner, and one evening recommendation.
                """
            }

            let response = try await session.respond(to: prompt)
            itineraryText = response.content

        } catch {
            self.error = error
        }
    }
}
