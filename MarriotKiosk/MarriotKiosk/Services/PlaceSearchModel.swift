//
//  PlaceSearchModel.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/12/25.
//


import Foundation
import MapKit
import Combine

@MainActor
final class PlaceSearchModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [MKMapItem] = []
    @Published var selectedPlace: MKMapItem? = nil

    private var searchTask: Task<Void, Never>? = nil
    private let referenceCoordinate: CLLocationCoordinate2D

    init(referenceCoordinate: CLLocationCoordinate2D) {
        self.referenceCoordinate = referenceCoordinate
    }

    func search() {
        searchTask?.cancel()

        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            results = []
            return
        }

        searchTask = Task {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = q
            request.resultTypes = .pointOfInterest

            // ✅ Focus search region around hotel/user
            request.region = MKCoordinateRegion(
                center: referenceCoordinate,
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            )

            let search = MKLocalSearch(request: request)

            do {
                let response = try await search.start()
                let sorted = response.mapItems.sorted {
                    guard let locA = $0.placemark.location,
                          let locB = $1.placemark.location else { return false }
                    return locA.distance(from: CLLocation(latitude: referenceCoordinate.latitude,
                                                          longitude: referenceCoordinate.longitude)) <
                           locB.distance(from: CLLocation(latitude: referenceCoordinate.latitude,
                                                          longitude: referenceCoordinate.longitude))
                }
                results = sorted
            } catch {
                print("Search failed: \(error.localizedDescription)")
                results = []
            }
        }
    }
}
