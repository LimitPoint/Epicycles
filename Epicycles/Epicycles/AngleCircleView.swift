//
//  AngleCircleView.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 7/4/23.
//

import SwiftUI

struct AngleCircleView: View {
    @Binding var angle: Double
    let radius: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke()
                .background(
                    Circle()
                        .fill(Color.white) // Fill the circle with white
                )
                
            
            Path { path in
                let center = CGPoint(x: radius, y: radius)
                
                path.move(to: center)
                path.addLine(to: pointOnCircle(center: center))
            }
            .stroke()
        }
        .frame(width: radius * 2, height: radius * 2)
    }
    
    private func pointOnCircle(center: CGPoint) -> CGPoint {
        let x = center.x + CGFloat(cos(-angle)) * radius // Negate the angle for counterclockwise
        let y = center.y + CGFloat(sin(-angle)) * radius // Negate the angle for counterclockwise
        
        return CGPoint(x: x, y: y)
    }
}

struct AngleCircleView_Preview: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }
    
    struct PreviewWrapper: View {
        @State private var angle: Double = 0.0
        
        var body: some View {
            VStack {
                AngleCircleView(angle: $angle, radius: 100)
                
                Slider(value: $angle, in: 0...(2 * .pi))
                    .padding(.horizontal)
            }
            .padding()
        }
    }
}
