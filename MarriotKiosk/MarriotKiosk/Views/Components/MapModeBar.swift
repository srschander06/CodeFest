//
//  MapModeBar.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/12/25.
//

import SwiftUI
import MapKit

struct MapModeBar: View {
    @Binding var selectedStyle: MapStyleOption

    var body: some View {
        HStack(spacing: 16) {
            ForEach(MapStyleOption.allCases) { style in
                Button {
                    withAnimation(.snappy) {
                        selectedStyle = style
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                } label: {
                    Text(style.rawValue)
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            selectedStyle == style
                            ? Color.accentColor.opacity(0.25)
                            : Color.clear
                        )
                        .clipShape(Capsule())
                        .glassEffect()
                }
                .buttonStyle(.plain)
                .glassEffect()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(radius: 4)
    }
}
