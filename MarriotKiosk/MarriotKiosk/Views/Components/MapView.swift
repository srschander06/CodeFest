//
//  TrafficMapView.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/11/25.
//


import SwiftUI
import MapKit
import CoreLocation
struct MapViewWrapper: UIViewRepresentable {
    @Binding var mapView: MKMapView
    let center: CLLocationCoordinate2D
    let guestCoordinate: CLLocationCoordinate2D
    @Binding var recenterTrigger: Bool
    @Binding var mapStyle: MapStyleOption
    

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        applyConfiguration(to: mapView)
        setCamera(on: mapView)

        // Hotel pin
        let hotelPin = MKPointAnnotation()
        hotelPin.title = "Courtyard by Marriott Blacksburg"
        hotelPin.coordinate = center
        mapView.addAnnotation(hotelPin)

        // Focus listener
        NotificationCenter.default.addObserver(forName: .focusMapOnLocation, object: nil, queue: .main) { note in
            if let coord = note.object as? CLLocationCoordinate2D {
                let pin = MKPointAnnotation()
                pin.title = "Recommended Spot"
                pin.coordinate = coord
                mapView.addAnnotation(pin)
                let camera = MKMapCamera(lookingAtCenter: coord, fromDistance: 250, pitch: 50, heading: 0)
                mapView.setCamera(camera, animated: true)
            }
        }
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if recenterTrigger {
            setCamera(on: uiView)
        }
        applyConfiguration(to: uiView)
    }

    private func applyConfiguration(to mapView: MKMapView) {
        switch mapStyle {
        case .standard:
            mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat)
        case .satellite:
            mapView.preferredConfiguration = MKImageryMapConfiguration()
        case .hybrid3D:
            let config = MKHybridMapConfiguration(elevationStyle: .realistic)
            config.showsTraffic = true
            mapView.preferredConfiguration = config
        }
    }

    private func setCamera(on mapView: MKMapView) {
        let camera = MKMapCamera(lookingAtCenter: center, fromDistance: 120, pitch: 55, heading: 135)
        mapView.setCamera(camera, animated: true)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, MKMapViewDelegate {}
}


extension Notification.Name { static let focusMapOnLocation = Notification.Name("focusMapOnLocation") }
