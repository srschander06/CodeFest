//
//  GuideCard.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/12/25.
//


import SwiftUI
import MapKit

struct GuideCard: View {
    let item: RecommendationFeed.Item
    @State private var showWebView = false
    @EnvironmentObject private var resolver: PlaceDistanceResolver

    /// Parent will inject this closure to move the map
    var onShowInMap: ((CLLocationCoordinate2D) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Label(item.name, systemImage: "mappin.and.ellipse")
                    .labelStyle(.titleAndIcon)
                    .font(.headline)
                Spacer()
                Text(resolver.distances[item.name] ?? "—")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Description
            Text(item.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            Spacer()

            // Buttons Row
            HStack {
                Button {
                    showWebView = true
                } label: {
                    Label("View", systemImage: "arrow.up.right")
                        .font(.footnote.bold())
                }

                Spacer()

                Button {
                    Task { await showInMap() }
                } label: {
                    Label("Show in Map", systemImage: "map")
                        .font(.footnote.bold())
                }
            }
            .tint(.accentColor)
            .sheet(isPresented: $showWebView) {
                if let url = URL(string: item.url) {
                    NavigationStack {
                        WebSheetView(url: url)
                            .navigationTitle(item.name)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Done") { showWebView = false }
                                }
                            }
                    }
                } else {
                    Text("Invalid URL").padding()
                }
            }
        }
        .frame(width: 240, height: 160, alignment: .topLeading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 5)
        .task {
            await resolver.resolveDistance(for: item.name)
        }
    }

    // MARK: - Local Search & Notify Parent
    private func showInMap() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = item.name
        let search = MKLocalSearch(request: request)
        do {
            let result = try await search.start()
            if let found = result.mapItems.first {
                onShowInMap?(found.placemark.coordinate)
            }
        } catch {
            print("❌ Failed to find location for \(item.name):", error.localizedDescription)
        }
    }
}

struct ExploreList: View {
    let title: String
    let items: [RecommendationFeed.Item]
    var onShowInMap: ((CLLocationCoordinate2D) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.capitalized)
                .font(.title3.bold())
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        GuideCard(item: item, onShowInMap: onShowInMap)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 8)
    }
}



import WebKit

struct WebSheetView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        webView.backgroundColor = .clear
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
