//
//  TrafficMapView.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/11/25.
//


import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    let center: CLLocationCoordinate2D
    let guestCoordinate: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)

        // Configure hybrid map with realistic elevation
        let config = MKHybridMapConfiguration(elevationStyle: .realistic)
        config.showsTraffic = true
        config.pointOfInterestFilter = .includingAll
        mapView.preferredConfiguration = config

        // Camera setup
        let camera = MKMapCamera(lookingAtCenter: center,
                                 fromDistance: 75,
                                 pitch: 55,
                                 heading: 135)
        mapView.setCamera(camera, animated: false)

        // Add Marriott annotation
        let hotelPin = MKPointAnnotation()
        hotelPin.title = "Marriott at Virginia Tech"
        hotelPin.coordinate = center
        mapView.addAnnotation(hotelPin)

        // Add Guest annotation
        let guestPin = MKPointAnnotation()
        guestPin.title = "Guest Location"
        guestPin.coordinate = guestCoordinate
        mapView.addAnnotation(guestPin)

        // Aesthetics
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.isZoomEnabled = true
        mapView.showsCompass = false
        mapView.showsScale = false

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Could update region or refresh annotations if data changes
    }
}
