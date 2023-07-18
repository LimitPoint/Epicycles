//
//  OptionsView.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 7/11/23.
//

import SwiftUI

/*
 If Options are edited for new options, remember that:
 
 1- Options are shared for all windows, and and Bindings in ContentView, initialized in the app init()
 2- Values are set and cleared using onChange in ContentView
 */
struct OptionsView: View {
    
    @Binding var lineWidth:[Double]
    @Binding var lineColor:[Color]
    @Binding var trailLength:Double
    @Binding var resetOptions:Bool
    
    let doneAction: () -> Void
    
    @State var showResetAlert = false
    
    @State var selectedTab: PathType = .curvePath
    
    @State var viewWidth: CGFloat = 300
    @State var viewHeight: CGFloat = 220
    
    func controlsView(at index: Int) -> some View {
        VStack {
            HStack {
                VStack {
                    Slider(value: $lineWidth[index], in: 1...10)
                        .padding(.horizontal)
                    
                    Text("Line Width \(lineWidth[index], specifier: "%.2f")")
                        .monospacedDigit()
                }
                
                ColorPicker("", selection: $lineColor[index])
                    .frame(width: 60, height: 30)
                    .padding()
            }
            
            // Fourier series path trail length
            if index == 1 {
                VStack {
                    Slider(value: $trailLength, in: 0...13)
                        .padding(.horizontal)
                    
                    Text("Trail Length \(trailLength, specifier: "%.2f")")
                        .monospacedDigit()
                }
            }
        }
        
    }
    
    var body: some View {
        
        VStack {
            
            TabView(selection: $selectedTab) {
                ForEach(PathType.allCases, id: \.self) { pathType in
                    controlsView(at: indexForPathType(pathType))
                        .tabItem {
                            Label(pathType.rawValue, systemImage: systemImageForPathType(pathType))
                        }
                        .tag(pathType)
                }
            }
            .padding()
            
            HStack {
                Button(action: {
                    showResetAlert = true
                }) {
                    Text("Reset")
                        .padding()
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: doneAction) {
                    Text("Done")
                        .padding()
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
        }
        .alert(isPresented: $showResetAlert) {
            Alert(title: Text("Reset Line Widths & Colors"), message: Text("Are you sure you want to reset the line widths and colors?\n\nThis cannot be undone."), primaryButton: .destructive(Text("Yes"), action: {
                resetOptions = true
            }), secondaryButton: .cancel())
        }
        .onChange(of: selectedTab) { newSelectedTab in
            if newSelectedTab == .curveFourierSeriesPath {
                viewWidth = 300
                viewHeight = 300
            }
            else {
                viewWidth = 300
                viewHeight = 220
            }
        }
        .frame(width: viewWidth, height: viewHeight)
        .animation(.easeInOut, value: viewHeight)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 10)
        
    }
    
}

struct OptionsViewWrapperView: View {
    
    @State var lineWidth:[Double] = kLineWidth
    @State var lineColor:[Color] = kLineColor
    @State var trailLength:Double = 12
    @State var resetOptions = false
    
    var body: some View {
        OptionsView(lineWidth: $lineWidth, lineColor: $lineColor, trailLength: $trailLength, resetOptions: $resetOptions, doneAction: {})
    }
}

struct OptionsView_Previews: PreviewProvider {
    static var previews: some View {
        OptionsViewWrapperView()
    }
}
