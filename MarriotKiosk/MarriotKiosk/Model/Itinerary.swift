//
//  Itenary.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/12/25.
//


import Foundation
import FoundationModels

@Generable
struct Itinerary: Codable, Equatable, Sendable {
    
    var id: UUID = .init()
    @Guide(description: "Exciting name for a single day Blacksburg trip Itinerary")
    var title: String
    @Guide(.anyOf(landmark.lan))
    var destinationName: String
    var description: String
    var rationale: String
    var days: [DayPlan]
}

@Generable
struct DayPlan: Codable, Equatable, Sendable {
    var title: String
    var subtitle: String
    var destination: String
    var date: Date
    var activities: [Activity]
}


@Generable
struct Activity: Codable, Equatable, Sendable {
    var type: ActivityType
    var title: String
    var description: String
    var location: String?
    var startTime: Date?
    var endTime: Date?
}



@Generable
enum ActivityType: String, Codable, Sendable, CaseIterable {
    case sightseeing
    case dining
    case wellness
    case cultural
    case business
    case leisure
    case transportation
}
