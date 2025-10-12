//
//  UserProfile.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/11/25.
//

import Foundation

struct UserProfile: Codable, Identifiable {
    var id: String
    let name: String
    let tier: String
    let bonvoyPoints: UInt
    let memberSince: Date
    let travelPreferences: TravelPreferences

    enum CodingKeys: String, CodingKey {
        case id, name, tier
        case bonvoyPoints = "bonvoy_points"
        case memberSince = "member_since"
        case travelPreferences = "travel_preferences"
    }

    struct TravelPreferences: Codable {
        let travelStyle: String
        let interests: [String]

        enum CodingKeys: String, CodingKey {
            case travelStyle = "travel_style"
            case interests
        }
    }
}

// MARK: - DateFormatter helper
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"              // matches your JSON
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df
    }()
}

// MARK: - Loader
func loadUserProfile() -> UserProfile? {
    guard let url = Bundle.main.url(forResource: "UserData", withExtension: "json") else {
        print("JSON file not found in bundle.")
        return nil
    }

    do {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.yyyyMMdd)
        let profile = try decoder.decode(UserProfile.self, from: data)
        print("Successfully loaded user: \(profile.name)")
        return profile
    } catch {
        print("Failed to decode UserProfile:", error)
        return nil
    }
}

