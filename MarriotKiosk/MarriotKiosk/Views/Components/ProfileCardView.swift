//
//  ProfileCardView.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/12/25.
//


import SwiftUI

struct ProfileCardView: View {
    let profile: UserProfile
    var onSignOut: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: - Header
            HStack(spacing: 16) {
                Circle()
                    .fill(.regularMaterial)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Text(initials)
                            .font(.largeTitle.bold())
                            .foregroundStyle(.primary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.title3.bold())
                    Text(profile.tier)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            // MARK: - Loyalty Info
            VStack(alignment: .leading, spacing: 8) {
                Label("\(profile.bonvoyPoints) Bonvoy Points", systemImage: "star.fill")
                    .foregroundStyle(.orange)
                Label("Member Since \(formattedDate(profile.memberSince))", systemImage: "calendar")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            Divider()

            // MARK: - Travel Prefs
            VStack(alignment: .leading, spacing: 8) {
                Text("Travel Style")
                    .font(.headline)
                Text(profile.travelPreferences.travelStyle)
                    .font(.subheadline)
                if !profile.travelPreferences.interests.isEmpty {
                    Text("Interests")
                        .font(.headline)
                        .padding(.top, 6)
                    ForEach(profile.travelPreferences.interests, id: \.self) { interest in
                        Label(interest, systemImage: "heart.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // MARK: - Footer Actions
            HStack {
                Button {
                    onSignOut?()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Spacer()
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 12)
    }

    // MARK: - Helpers
    private var initials: String {
        let comps = profile.name.split(separator: " ")
        let firstTwo = comps.prefix(2).compactMap { $0.first }
        return firstTwo.map { String($0).uppercased() }.joined()
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }
}
