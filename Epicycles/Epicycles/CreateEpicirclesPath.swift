//
//  CreateEpicirclesPath.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/10/23.
//

import SwiftUI

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let deltaX = point.x - self.x
        let deltaY = point.y - self.y
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
        return distance
    }
}

    // MARK: createPath

func CreatePath(points:[CGPoint], close:Bool) -> Path {
    var path = Path()
    
    if points.count > 1 {
        path.move(to: points[0])
        
        for i in 1...points.count-1 {
            path.addLine(to: points[i])
        }
    }
    
    if close {
        path.closeSubpath()
    }
    
    return path
}

func CreateTerminatingCirclePath(points: [CGPoint], circleRadius: CGFloat) -> Path {
    var path = Path()
    
    if circleRadius > 0, let lastPoint = points.last {
        let circleRect = CGRect(x: lastPoint.x - circleRadius,
                                y: lastPoint.y - circleRadius,
                                width: circleRadius * 2,
                                height: circleRadius * 2)
        
        path.addEllipse(in: circleRect)
    }
    
    return path
}

func CreateEpicirclesPath(points: [CGPoint]) -> (Path, [Path]) {
    
    let circlePaths = CreateEpicirclesPaths(points: points)
    
    let circlePath = Path { path in
        for circlePath in circlePaths {
            path.addPath(circlePath)
        }
    }
    
    return (circlePath, circlePaths)
}

func CreateEpicirclesPaths(points: [CGPoint]) -> [Path] {
    
    var paths:[Path] = []
    
    if #available(iOS 16, *) {
        for index in 0..<points.count-1 {
            
            let circlePath = Path { path in
                let center = points[index]
                let radius = points[index].distance(to: points[index+1])
                let startAngle: Angle = .degrees(0)
                let endAngle: Angle = .degrees(360)
                let clockwise = false
                
                path.addArc(center: center, radius: CGFloat(radius), startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
            }
            
            paths.append(circlePath)
        }
    } else {
        
        for index in 0..<points.count-1 {
            
            var path = Path()
            
            let center = points[index]
            
            let radius: CGFloat
            if index < points.count - 1 {
                let nextPoint = points[index + 1]
                radius = center.distance(to: nextPoint)
            } else {
                    // Connect the last point with the first point to form a closed path
                let firstPoint = points[0]
                radius = center.distance(to: firstPoint)
            }
            
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            path.addEllipse(in: rect)
            
            paths.append(path)
        }
    }
    
    return paths
}
