//
//  UserProfile.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/11/25.
//

// UserProfile.swift (domain model you actually want to use in the app)
import Foundation


struct UserProfile: Decodable, Identifiable {
    var id: String
    let name: String
    let tier: String
    let bonvoyPoints: UInt
    let memberSince: Date
    let travelPreferences: TravelPreferences


    struct TravelPreferences: Codable {
        let travelStyle: String
        let interests: [String]
    }

    // Map JSON keys to this simpler structure
    enum CodingKeys: String, CodingKey {
        case id = "member_id"
        case first_name
        case last_name
        case elite_status
        case points_balance
        case member_since
        case dining_preferences
        case wellness_preferences
    }

    struct DiningPreferences: Codable {
        let diningStyle: String?
        let cuisinePreferences: [String]?
    }

    private struct WellnessPreferences: Codable {
        let fitness: Fitness?
        struct Fitness: Codable {
            let fitnessClasses: [String]?
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(String.self, forKey: .id)

        // Build full name
        let first = try? c.decode(String.self, forKey: .first_name)
        let last  = try? c.decode(String.self, forKey: .last_name)
        name = [first, last].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")

        tier = (try? c.decode(String.self, forKey: .elite_status)) ?? "Member"
        bonvoyPoints = UInt((try? c.decode(Int.self, forKey: .points_balance)) ?? 0)

        // 🧠Strict date decode: YYYY-MM-DD only
        let dateString = try c.decode(String.self, forKey: .member_since)
        guard let parsed = DateFormatter.yyyyMMdd.date(from: dateString) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: [CodingKeys.member_since],
                debugDescription: "Expected date in yyyy-MM-dd, got \(dateString)"
            ))
        }
        memberSince = parsed

        // Travel prefs from dining + wellness
        let dining = try? c.decode(DiningPreferences.self, forKey: .dining_preferences)
        let wellness = try? c.decode(WellnessPreferences.self, forKey: .wellness_preferences)
        let cuisines = dining?.cuisinePreferences ?? []
        let classes = wellness?.fitness?.fitnessClasses ?? []

        travelPreferences = .init(
            travelStyle: dining?.diningStyle ?? "Unknown",
            interests: cuisines + classes
        )
    }
}




extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df
    }()
}



func loadUserProfile() -> UserProfile? {
    guard let url = Bundle.main.url(forResource: "UserData", withExtension: "json") else {
        print(" JSON not found in bundle.")
        return nil
    }

    do {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.yyyyMMdd)
        let profile = try decoder.decode(UserProfile.self, from: data)
        print(" Loaded user \(profile.name)")
        return profile
    } catch {
        print(" Decode failed:", error)
        return nil
    }
}
