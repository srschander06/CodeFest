//
//  SidebarView.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/11/25.
//


import SwiftUI

struct SidebarView: View {
    var body: some View {
        ZStack {
            // Persistent background
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .vertical)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search Maps")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    // MARK: - Places Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Places")
                            .font(.headline)
                        HStack(spacing: 16) {
                            Label("Home", systemImage: "house.fill")
                            Label("Work", systemImage: "briefcase.fill")
                            Label("School", systemImage: "graduationcap.fill")
                            Label("Transit", systemImage: "bus.fill")
                        }
                        .labelStyle(.iconOnly)
                        .font(.title3)
                    }

                    Divider()

                    // MARK: - Recents Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recents")
                            .font(.headline)
                        sidebarRow(title: "Virginia Tech", subtitle: "Marked Location", icon: "mappin.circle.fill")
                        sidebarRow(title: "Campbell Arena", subtitle: "495 Plantation Rd", icon: "sportscourt.fill")
                        sidebarRow(title: "Cassell Coliseum", subtitle: "Blacksburg, VA", icon: "building.columns.fill")
                    }

                    Divider()

                    // MARK: - Guides Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Guides")
                            .font(.headline)
                        sidebarRow(title: "Favorites", subtitle: "0 places", icon: "star.fill")

                        Text("Guides We Love")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                guideCard(title: "Hottest Tables", subtitle: "OpenTable", image: "flame.fill")
                                guideCard(title: "Best Pizza", subtitle: "Infatuation", image: "fork.knife")
                                guideCard(title: "Hidden Gems", subtitle: "TripAdvisor", image: "map.fill")
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 360)
        .shadow(radius: 20)
        .padding()
    }

    // MARK: - Reusable Row
    func sidebarRow(title: String, subtitle: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline).bold()
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Reusable Guide Card
    func guideCard(title: String, subtitle: String, image: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: image)
                .font(.largeTitle)
                .foregroundStyle(.tint)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 150, height: 120)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}


#Preview{
    SidebarView()
}
