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
    @State private var user: UserProfile? = nil

    // Approximate coordinate for Courtyard by Marriott Blacksburg
    private let hotelCoordinate = CLLocationCoordinate2D(latitude: 37.2298, longitude: -80.4275)
    private let guestCoordinate = CLLocationCoordinate2D(latitude: 37.2298, longitude: -80.4275)

    var body: some View {
        ZStack(alignment: .topLeading) {
            // MARK: - Map Layer (UIKit)
            MapView(center: hotelCoordinate,
                           guestCoordinate: guestCoordinate)
                .ignoresSafeArea()

            // MARK: - Sidebar
            HStack(alignment: .top, spacing: 0) {
                SidebarView()
                    .frame(width: 350)
                    .padding(.top, 60)
                    .shadow(radius: 10)
                Spacer()
            }

            // MARK: - Top Bar
            VStack {
                if let user {
                    topBar(for: user)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                } else {
                    ProgressView("Loading profile…")
                        .padding(.top, 50)
                }
                Spacer()
            }
        }
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}



