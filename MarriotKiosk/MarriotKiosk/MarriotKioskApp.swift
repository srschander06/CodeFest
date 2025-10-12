//
//  MarriotKioskApp.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/11/25.
//

import SwiftUI
import SwiftData

@main
struct MarriotKioskApp: App {
    var body: some Scene {
        WindowGroup {
            MapDashboardView()
            
            .preferredColorScheme(.light)
        }
    }
}
