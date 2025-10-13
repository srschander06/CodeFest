//
//  PersonalizedItineraryButton.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/13/25.
//

import SwiftUI

struct PersonalizedItineraryView: View {
    @State private var generator = PersonalizedItineraryGenerator()
    var autoGenerate: Bool = false

    var body: some View {
        VStack {
            if let trip = generator.itinerary {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if let destination = trip.destination {
                            Text(" \(destination)")
                                .font(.title.bold())
                        }
                        if let days = trip.days {
                            ForEach(days, id: \.id) { day in
                                VStack(alignment: .leading, spacing: 8) {
                                    if let label = day.dayLabel {
                                        Text(label).font(.headline)
                                    }
                                    if let summary = day.summary {
                                        Text(summary)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    if let sections = day.sections {
                                        ForEach(sections, id: \.id) { section in
                                            VStack(alignment: .leading, spacing: 4) {
                                                if let title = section.title {
                                                    Text(title).font(.subheadline.bold())
                                                }
                                                if let activities = section.activities {
                                                    ForEach(activities, id: \.id) { activity in
                                                        if let name = activity.name {
                                                            Text("• \(name)")
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .padding()
                }
                .animation(.easeInOut, value: trip)
            } else if generator.isLoading {
                ProgressView("Generating itinerary…")
            } else {
                Button {
                    Task { await generator.generatePersonalizedItinerary() }
                } label: {
                    Label("Generate Personalized Itinerary", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .navigationTitle("Marriott Concierge")
        .task {
            if autoGenerate, generator.itinerary == nil {
                      await generator.generatePersonalizedItinerary()
                  }
              }
    }
}
