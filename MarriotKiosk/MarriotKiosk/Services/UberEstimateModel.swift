//
//  UberEstimateModel.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/12/25.
//


import Foundation
import MapKit
import Combine

@MainActor
final class UberEstimateModel: ObservableObject {
    @Published var estimateText: String = "—"
    @Published var distanceMiles: Double = 0

    func estimate(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let originLoc = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let destLoc = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        let distance = originLoc.distance(from: destLoc) / 1609.34 // meters → miles
        distanceMiles = distance

        // Fake pricing formula (similar to UberX base rate)
        let base = 3.50
        let perMile = 2.25
        let cost = base + (distance * perMile)
        estimateText = String(format: "$%.2f - $%.2f", cost * 0.9, cost * 1.1)
    }

    func regionalAverage() -> String {
        switch distanceMiles {
        case 0..<1: return "Short hop — around $8 avg"
        case 1..<3: return "Mid-range — about $15 avg"
        default: return "Longer trip — roughly $25–30 avg"
        }
    }
}
