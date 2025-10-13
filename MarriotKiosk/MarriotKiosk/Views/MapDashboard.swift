//
//  ContentView.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/11/25.
//

import SwiftUI
import MapKit

enum MapStyleOption: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case satellite = "Satellite"
    case hybrid3D = "3D"

    var id: String { rawValue }
}

struct MapDashboardView: View {
    // MARK: - State
    @State private var user: UserProfile? = nil
    @State private var mapView = MKMapView()
    @State private var recenterTrigger = false
    @State private var mapStyle: MapStyleOption = .standard

    private let hotelCoordinate = CLLocationCoordinate2D(latitude: 37.19928, longitude: -80.40117)
    private let guestCoordinate = CLLocationCoordinate2D(latitude: 37.19928, longitude: -80.40117)

    var body: some View {
        ZStack(alignment: .topLeading) {
            // MARK: - Map Layer
            MapViewWrapper(mapView: $mapView,
                           center: hotelCoordinate,
                           guestCoordinate: guestCoordinate,
                           recenterTrigger: $recenterTrigger,
                           mapStyle: $mapStyle)
                .ignoresSafeArea()

            // MARK: - Sidebar
            HStack(alignment: .top, spacing: 0) {
                SidebarView()
                    .frame(width: 350)
                    .padding(.top, 60)
                    .padding(.leading, 24)
                    .shadow(radius: 10)
                Spacer()
            }

            // MARK: - Top Controls
            VStack(spacing: 12) {
                MapModeBar(selectedStyle: $mapStyle)
                    .padding(.top, 20)

                HStack {
                    Spacer()
                    Button {
                        withAnimation(.snappy) {
                            recenterTrigger.toggle()
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        Label("Recenter", systemImage: "location.fill")
                            .labelStyle(.iconOnly)
                            .font(.title2.bold())
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 3)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 5)
                }
                Spacer()
            }
        }
        .task { user = loadUserProfile() }
    }
}




#Preview {
    MapDashboardView()
}
