//
//  PersonalizedItineraryButton.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/13/25.
//
import SwiftUI
import PDFKit
import UIKit // for UIGraphicsPDFRenderer

struct PersonalizedItineraryView: View {
    @State private var generator = PersonalizedItineraryGenerator()
    var autoGenerate: Bool = false
    @State private var pdfURL: URL? = nil

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Floating Export Button
            HStack {
                Spacer()
                Button {
                    Task { await exportToPDF() }
                } label: {
                    Label("Export PDF", systemImage: "doc.fill")
                        .labelStyle(.iconOnly)
                        .font(.title3.bold())
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                        .shadow(radius: 3, y: 2)
                }
                .padding(.trailing, 16)
                .padding(.top, 16)
            }

            // MARK: - Itinerary Content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: - Share Button
            if let pdfURL {
                ShareLink(item: pdfURL) {
                    Label("Share Itinerary (AirDrop, Mail…)", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .padding(.bottom, 12)
            }
        }
        .background(Color(.systemBackground))
        .presentationCornerRadius(24)
        .task {
            if autoGenerate, generator.itinerary == nil {
                await generator.generatePersonalizedItinerary()
            }
        }
    }

    // MARK: - Main Content
    @ViewBuilder
    private var content: some View {
        if let trip = generator.itinerary {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let destination = trip.destination {
                        Text(destination)
                            .font(.largeTitle.bold())
                            .padding(.bottom, 8)
                    }

                    if let days = trip.days {
                        ForEach(days, id: \.id) { day in
                            VStack(alignment: .leading, spacing: 8) {
                                if let label = day.dayLabel {
                                    Text(label).font(.headline)
                                }
                                if let summary = day.summary {
                                    Text(summary)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                if let sections = day.sections {
                                    ForEach(sections, id: \.id) { section in
                                        VStack(alignment: .leading, spacing: 4) {
                                            if let title = section.title {
                                                Text(title).font(.subheadline.bold())
                                            }
                                            if let activities = section.activities {
                                                ForEach(activities, id: \.id) { activity in
                                                    if let name = activity.name {
                                                        Text("• \(name)").font(.footnote)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                            Divider()
                        }
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        } else if generator.isLoading {
            ProgressView("Generating itinerary…")
                .padding()
        } else {
            Button {
                Task { await generator.generatePersonalizedItinerary() }
            } label: {
                Label("Generate Personalized Itinerary", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}

// MARK: - PDF Export Helper
extension PersonalizedItineraryView {
    @MainActor
    func exportToPDF() async {
        let pageSize = CGSize(width: 612, height: 792) // US Letter size
        let pageRect = CGRect(origin: .zero, size: pageSize)

        // Render the SwiftUI content into CoreGraphics
        let renderer = ImageRenderer(content: content.frame(width: pageSize.width, height: pageSize.height))

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Personalized Itinerary",
            kCGPDFContextAuthor as String: "Marriott Concierge"
        ]

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let data = pdfRenderer.pdfData { ctx in
            ctx.beginPage()
            renderer.render { _, render in
                let cg = ctx.cgContext
                cg.saveGState()
                cg.translateBy(x: 0, y: pageRect.height)
                cg.scaleBy(x: 1, y: -1)
                render(cg)
                cg.restoreGState()
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Itinerary.pdf")
        do {
            try data.write(to: url, options: .atomic)
            pdfURL = url
            print("✅ PDF exported to:", url)
        } catch {
            print("❌ Failed to write PDF:", error)
        }
    }
}

#Preview {
    PersonalizedItineraryView(autoGenerate: true)
}
