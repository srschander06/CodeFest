//
//  HotelCardView.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/12/25.
//


import SwiftUI
import Contacts
import MapKit

struct HotelCardView: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "building.2.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Courtyard by Marriott Blacksburg")
                        .font(.headline)
                    Text("105 Southpark Drive, Blacksburg, VA")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Open 24 hours · Front Desk")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack {
                Button {
                    openInMaps()
                } label: {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.footnote.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)

                Spacer()

                Button {
                    showOnMapPreview()
                } label: {
                    Label("View Map", systemImage: "map.fill")
                        .font(.footnote.bold())
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 5)
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: coordinate,
                                    addressDictionary: [CNPostalAddressStreetKey: "105 Southpark Drive"])
        let item = MKMapItem(placemark: placemark)
        item.name = "Courtyard by Marriott Blacksburg"
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func showOnMapPreview() {
        // For now, same as openInMaps — you can replace with in-app map sheet later
        openInMaps()
    }
}
