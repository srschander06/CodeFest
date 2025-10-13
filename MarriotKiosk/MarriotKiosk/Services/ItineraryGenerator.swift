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
    private(set) var itinerary: Trip.PartiallyGenerated?
    private(set) var isLoading = false
    private(set) var error: Error?

    private var session: LanguageModelSession

    init() {
        let instructions = Instructions {
            """
            You are a Marriott Bonvoy AI Concierge.
            Create structured, personalized itineraries using the Trip schema.
            Each day includes a short summary and three sections: Morning, Afternoon, and Evening.
            Avoid using raw date values; use simple labels like 'Day 1' or 'Oct 13'.
            """
        }
        session = LanguageModelSession(instructions: instructions)
    }

    func generatePersonalizedItinerary() async {
        guard let user = loadUserProfile(), let feed = loadRecommendations() else {
            print("❌ Missing local data.")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let interests = user.travelPreferences.interests.joined(separator: ", ")
            let dining = feed.recommendations["dining"]?.items.prefix(3).map(\.name).joined(separator: ", ") ?? ""
            let attractions = feed.recommendations["attractions"]?.items.prefix(3).map(\.name).joined(separator: ", ") ?? ""
            let nightlife = feed.recommendations["nightlife"]?.items.prefix(2).map(\.name).joined(separator: ", ") ?? ""

            let prompt = Prompt {
                """
                Generate a 2-day personalized itinerary in Blacksburg, VA for Marriott Bonvoy member \(user.name).

                Interests: \(interests)
                Dining: \(dining)
                Attractions: \(attractions)
                Nightlife: \(nightlife)

                Output must conform to the Trip schema (using text labels for dates).
                """
            }

            let stream = session.streamResponse(
                to: prompt,
                generating: Trip.self,
                includeSchemaInPrompt: false,
                options: GenerationOptions(sampling: .greedy)
            )

            for try await partial in stream {
                itinerary = partial.content
            }

        } catch {
            self.error = error
        }
    }

    func prewarmModel() { session.prewarm() }
}
