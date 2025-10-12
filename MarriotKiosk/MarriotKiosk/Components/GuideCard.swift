//
//  GuideCard.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/12/25.
//


import SwiftUI

struct GuideCard: View {
    let item: RecommendationFeed.Item
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(item.name, systemImage: "map.fill")
                .labelStyle(.titleAndIcon)
                .font(.headline)
            Text(item.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            Spacer()
            Link(destination: URL(string: item.url)!) {
                Label("View", systemImage: "arrow.up.right")
                    .font(.footnote.bold())
            }
            .tint(.accentColor)
        }
        .frame(width: 240, height: 160, alignment: .topLeading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 5)
    }
}

struct ExploreList: View {
    let title: String
    let items: [RecommendationFeed.Item]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.capitalized)
                .font(.title3.bold())
                .padding(.horizontal, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        GuideCard(item: item)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 8)
    }
}
