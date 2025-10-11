//
//  Place.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/11/25.
//

import SwiftUI
import CoreLocation



struct Place: Identifiable, Codable {
    var id = UUID()
    let name: String
    let hours: String
    let description: String
    let coordinate: CodableCoordinate
    let category : CategoryType
    
}


struct CodableCoordinate: Codable {
    let latitude: Double
    let longitude: Double
    
    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum CategoryType: String, CaseIterable, Codable{
    case dining = "Dining"
    case attractions = "Attractions"
    case shopping = "Shopping"
    case nightlife = "Night Life"
}

