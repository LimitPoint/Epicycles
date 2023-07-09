//
//  EpicyclesApp.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/10/23.
//
import SwiftUI

@main
struct EpicyclesApp: App {
    
    // Put here rather than in ContentView so it only appears once, and not for every new window
    @State var showSplashScreen = true
     
    init() {
        if let url = FileManager.urlForDocumentsOrSubdirectory(subdirectoryName: nil) {
            print("Documents url = \(url)")
        }
    }
    
    var body: some Scene {
        
        WindowGroup {
            ContentView(showSplashScreen: $showSplashScreen)
        }
        #if os(macOS)
        .defaultSize(width: 600, height: 800)
        #endif
    }
}
