//
//  PersonalizedItineraryButton.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/13/25.
//

import SwiftUI

struct PersonalizedItineraryView: View {
    @State private var generator = PersonalizedItineraryGenerator()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let text = generator.itineraryText {
                    Text(text)
                        .font(.body)
                        .padding()
                        .transition(.opacity)
                } else if generator.isLoading {
                    ProgressView("Generating itinerary...")
                        .padding(.top, 60)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 64))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, .secondary)
                        Text("Generate a personalized itinerary")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                }

                Button {
                    Task { await generator.generatePersonalizedItinerary() }
                } label: {
                    Label("Generate Itinerary", systemImage: "airplane.departure")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(generator.isLoading)
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Your Trip Plan")
    }
}
