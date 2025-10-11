//
//  ContentView.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/11/25.
//

import SwiftUI
import MapKit


struct MapDashboardView: View {
    // MARK: - State
    @State private var position: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 37.2296, longitude: -80.4273),
            distance: 75,
            heading: 135,
            pitch: 55
        )
    )

    @State private var user: UserProfile? = nil
    private let guestCoordinate = CLLocationCoordinate2D(latitude: 37.2301, longitude: -80.4265)

    var body: some View {
        ZStack {
            // MARK: - Map Layer
            Map(position: $position) {
                Annotation("Marriott at Virginia Tech",
                           coordinate: CLLocationCoordinate2D(latitude: 37.2296, longitude: -80.4273)) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.red, .white)
                }

                Annotation("Guest Location", coordinate: guestCoordinate) {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            // MARK: - Overlay UI
            VStack {
                // Top bar with dynamic user info
                if let user {
                    topBar(for: user)
                } else {
                    ProgressView("Loading profile…")
                        .padding(.top, 50)
                }

                Spacer()

                // Sidebar (static for now)
                HStack {
                    Spacer()
                    dashboardSidebar
                }
            }
        }
        // Load user once when view appears
        .task {
            user = loadUserProfile()
        }
    }

    // MARK: - Top Bar
    @ViewBuilder
    func topBar(for user: UserProfile) -> some View {
        HStack {
            Label("Marriott Bonvoy", systemImage: "building.2.crop.circle")
                .font(.title3.bold())
                .foregroundStyle(.black)
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Welcome, \(user.name) 👋")
                    .font(.headline)
                    .foregroundStyle(.black)
                Text("\(user.tier) • \(user.bonvoyPoints) pts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding([.top, .horizontal])
    }

    // MARK: - Sidebar
    private var dashboardSidebar: some View {
        VStack(spacing: 24) {
            dashboardCard(title: "Your Stay", icon: "bed.double.fill", subtitle: "Room 421 • Checked in")
            dashboardCard(title: "Dining", icon: "fork.knife.circle.fill", subtitle: "Open till 10:00 PM")
            dashboardCard(title: "Concierge", icon: "person.text.rectangle.fill", subtitle: "Ask about local tours")
            Spacer()
        }
        .padding()
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding()
    }

    // MARK: - Reusable Card
    @ViewBuilder
    func dashboardCard(title: String, icon: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    MapDashboardView()
}
