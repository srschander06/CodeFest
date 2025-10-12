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

    private var searchTask: Task<Void, Never>? = nil

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
            let search = MKLocalSearch(request: request)
            do {
                let response = try await search.start()
                results = response.mapItems
            } catch {
                print("Search failed: \(error.localizedDescription)")
                results = []
            }
        }
    }
}
