//
//  LocationManager.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/11/25.
//

import CoreLocation


@Observable
final class LocationManager : NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var location : CLLocationCoordinate2D?
    
    override init() {
           super.init()
           manager.delegate = self
           manager.desiredAccuracy = kCLLocationAccuracyBest
           manager.requestWhenInUseAuthorization()
           manager.startUpdatingLocation()
       }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
          location = locations.last?.coordinate
    }
}
