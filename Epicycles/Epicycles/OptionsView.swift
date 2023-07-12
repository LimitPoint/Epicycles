//
//  OptionsView.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 7/11/23.
//

import SwiftUI

struct OptionsView: View {
    
    @Binding var lineWidth:[Double]
    @Binding var lineColor:[Color]
    @Binding var resetOptions:Bool
    
    let doneAction: () -> Void
    
    @State var showResetAlert = false
    
    func controlsView(at index: Int) -> some View {
        HStack {
            VStack {
                Slider(value: $lineWidth[index], in: 1...10)
                    .padding(.horizontal)
                
                Text("\(lineWidth[index], specifier: "%.2f")")
                    .monospacedDigit()
            }
            
            ColorPicker("", selection: $lineColor[index])
                .frame(width: 60, height: 30)
                .padding()
        }
    }
    
    var body: some View {
        
        VStack {
            
            TabView {
                controlsView(at: 3)
                    .tabItem {
                        Label("Circles", systemImage: "circle")
                    }
                    .tag(0)
                
                controlsView(at: 4)
                    .tabItem {
                        Label("f(t)", systemImage: "eye.circle")
                    }
                    .tag(1)
                
                controlsView(at: 2)
                    .tabItem {
                        Label("Radii", systemImage: "bolt")
                    }
                    .tag(2)
                
                controlsView(at: 0)
                    .tabItem {
                        Label("f", systemImage: "pencil")
                    }
                    .tag(3)
                
                controlsView(at: 1)
                    .tabItem {
                        Label("Σ", systemImage: "star")
                    }
                    .tag(4)
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
        .frame(width:300, height:220)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 10)
        
    }
    
}

struct OptionsViewWrapperView: View {
    
    @State var lineWidth:[Double] = kLineWidth
    @State var lineColor:[Color] = kLineColor
    @State var resetOptions = false
    
    var body: some View {
        OptionsView(lineWidth: $lineWidth, lineColor: $lineColor, resetOptions: $resetOptions, doneAction: {})
    }
}

struct OptionsView_Previews: PreviewProvider {
    static var previews: some View {
        OptionsViewWrapperView()
    }
}
