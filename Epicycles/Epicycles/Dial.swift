//
//  Dial.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/11/23.
//

import SwiftUI

struct Dial: View {
    @Binding var angle: Double
    @GestureState private var dragOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
                
                Path { path in
                    let radius = min(geometry.size.width, geometry.size.height) / 2
                    let startPoint = center
                    let endPoint = CGPoint(x: center.x + radius * cos(CGFloat(angle)), y: center.y - radius * sin(CGFloat(angle)))
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                }
                .stroke(Color.red, lineWidth: 10) // Set the width of the radial line to 10
            }
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onChanged { value in
                        let touchLocation = value.location
                        let dx = touchLocation.x - center.x
                        let dy = touchLocation.y - center.y
                        angle = Double(atan2(-dy, dx))
                        if angle < 0 {
                            angle += 2 * .pi
                        }
                    }
            )
        }
    }
}

struct DialPreviewView: View {
    @State private var angle: Double = 0.0
    
    var body: some View {
        VStack {
            Dial(angle: $angle)
                .frame(width: 200, height: 200)
            
            Text("Current Angle: \(angle - .pi)")
                .font(.headline)
                .padding()
        }
    }
}

struct Dial_Previews: PreviewProvider {
    static var previews: some View {
        DialPreviewView()
    }
}
