//
//  SidebarView.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/11/25.
//

import SwiftUI
import MapKit

struct SidebarView: View {
    @State private var showProfile = false
    @State private var profile: UserProfile? = loadUserProfile()
    @State private var feed: RecommendationFeed? = loadRecommendations()
    @StateObject private var searchModel = PlaceSearchModel()
    @StateObject private var uber = UberEstimateModel()

    // Hardcode hotel as the reference
    private let hotelCoordinate = CLLocationCoordinate2D(latitude: 37.2309, longitude: -80.4236)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .vertical)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 28) {

                    // MARK: - Search Bar + Avatar
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Search nearby places", text: $searchModel.query)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .onSubmit { searchModel.search() }
                            .onChange(of: searchModel.query) { _ in
                                // slight debounce behavior
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    searchModel.search()
                                }
                            }

                        Spacer()

                        Button {
                            showProfile.toggle()
                        } label: {
                            Circle()
                                .fill(.thinMaterial)
                                .frame(width: 36, height: 36)
                                .overlay(Text(profileInitial).font(.headline.bold()))
                        }
                        .popover(isPresented: $showProfile) {
                            if let profile {
                                ProfileCardView(profile: profile) { showProfile = false }
                                    .padding()
                                    .presentationBackground(.ultraThinMaterial)
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    
                    // MARK: - Hotel Info Card
                                      HotelCardView(coordinate: hotelCoordinate)

                    // MARK: - Search Results
                    if !searchModel.results.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Results near you")
                                .font(.headline)
                            ForEach(searchModel.results, id: \.self) { item in
                                Button {
                                    uber.estimate(from: hotelCoordinate, to: item.placemark.coordinate)
                                } label: {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundStyle(.tint)
                                        VStack(alignment: .leading) {
                                            Text(item.name ?? "Unknown Place")
                                                .font(.subheadline.bold())
                                            if let address = item.placemark.title {
                                                Text(address)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.forward.circle.fill")
                                            .font(.title3)
                                            .symbolRenderingMode(.hierarchical)
                                    }
                                    .padding(8)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

                    // MARK: - Uber Estimate Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ride Estimate")
                            .font(.headline)
                        HStack {
                            Image(systemName: "car.fill")
                                .font(.title)
                                .foregroundStyle(.tint)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(uber.estimateText)
                                    .font(.title3.bold())
                                Text(uber.regionalAverage())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 4)
                    }

                    Divider()

                    // MARK: - Explore Recommendations
                    if let feed {
                        ForEach(feed.recommendations.sorted(by: { $0.key < $1.key }), id: \.key) { key, category in
                            ExploreList(title: key, items: category.items)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
        .frame(width: 380)
        .shadow(radius: 20)
    }

    private var profileInitial: String {
        guard let n = profile?.name.split(separator: " ").first else { return "?" }
        return String(n.prefix(1)).uppercased()
    }
}
