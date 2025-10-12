//
//  PlaceDistanceResolver.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/12/25.
//


import Foundation
import MapKit
import Combine

@MainActor
final class PlaceDistanceResolver: ObservableObject {
    private let guestLocation = CLLocation(latitude: 37.19928, longitude: -80.40117)
    @Published var distances: [String: String] = [:]

    func resolveDistance(for name: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = name
        request.region = MKCoordinateRegion(
            center: guestLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )

        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            if let first = response.mapItems.first {
                let placeLoc = first.placemark.location!
                let dist = guestLocation.distance(from: placeLoc)

                let fmt = MKDistanceFormatter()
                fmt.units = .imperial
                let text = fmt.string(fromDistance: dist)
                distances[name] = text
            } else {
                distances[name] = "—"
            }
        } catch {
            print("Distance lookup failed for \(name):", error)
            distances[name] = "—"
        }
    }
}
