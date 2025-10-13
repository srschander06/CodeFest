//
//  Trip.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/13/25.
//


import Foundation
import CoreLocation
import FoundationModels

import Foundation
import FoundationModels

@Generable
struct Trip: Codable, Identifiable, Hashable {
    var id = UUID()
    var destination: String
    @Guide(description: "Start date of the trip, as a readable string like 'Oct 13 2025'")
    var startDateText: String
    @Guide(description: "End date of the trip, as a readable string like 'Oct 15 2025'")
    var endDateText: String
    var travelerName: String?
    var notes: String?
    var days: [DayPlan]
}

@Generable
struct DayPlan: Codable, Identifiable, Hashable {
    var id = UUID()
    @Guide(description: "Readable label for this day, such as 'Day 1' or 'Arrival Day'")
    var dayLabel: String
    @Guide(description: "Short summary of the day's theme.")
    var summary: String?
    @Guide(description: "Sections like Morning, Afternoon, Evening.")
    var sections: [ItinerarySection]
}

@Generable
struct ItinerarySection: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var description: String?
    var activities: [Activity]
}

@Generable
struct Activity: Codable, Identifiable, Hashable {
    var id = UUID()
    @Guide(description: "Name of the activity or venue.")
    var name: String
    @Guide(description: "Optional time as a readable string like '8 AM' or 'Evening'.")
    var timeText: String?
    @Guide(description: "Name of the location, e.g. 'Marriott at VT'.")
    var locationName: String?
    var notes: String?
}
