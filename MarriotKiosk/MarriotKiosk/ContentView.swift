//
//  ContentView.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/11/25.
//

import SwiftUI

struct RootTabView : View {
    
    enum Tab: Hashable{
        case home, map, settings
    }
    
    
    var body: some View {
        
    }
}


struct homeView : View {
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}

struct mapView : View {
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}

struct settingsView : View {
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}


#Preview("Kiosk Tabs") {
RootTabView()
}
