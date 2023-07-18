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
    
        // 0-curvePath, 1-curveFourierSeriesPath, 2-epicyclesPath, 3-epicyclesCirclesPath, 4-epicyclesPathTerminator
    @State var lineColor = kLineColor
    @State var lineWidth = kLineWidth
    @State var trailLength = kTrailLength
     
    init() {
        if let url = FileManager.urlForDocumentsOrSubdirectory(subdirectoryName: nil) {
            print("Documents url = \(url)")
        }

        if let savedLineColor = loadColorsFromUserDefaults(forKey: kColorKey) {
            _lineColor = State(initialValue: savedLineColor)
        }
        
        if let savedLineWidth = UserDefaults.standard.array(forKey: kWidthKey) as? [Double] {
            _lineWidth = State(initialValue: savedLineWidth)
        }
        
        if let _ = UserDefaults.standard.object(forKey: kTrailLengthKey) {
            let savedTrailLength = UserDefaults.standard.double(forKey: kTrailLengthKey)
            _trailLength = State(initialValue: savedTrailLength)
        }
        
    }
    
    var body: some Scene {
        
        WindowGroup {
            ContentView(showSplashScreen: $showSplashScreen, lineWidth: $lineWidth, lineColor: $lineColor, trailLength: $trailLength)
        }
        #if os(macOS)
        .defaultSize(width: 600, height: 800)
        #endif
    }
}
