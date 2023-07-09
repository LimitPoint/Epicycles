//
//  ScalePointsIntoView.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/10/23.
//

import Foundation

    // MARK: fit path
func BoundingRect(points: [CGPoint]) -> CGRect? {
    guard let firstPoint = points.first else {
        return nil
    }
    
    var minX = firstPoint.x
    var minY = firstPoint.y
    var maxX = firstPoint.x
    var maxY = firstPoint.y
    
    for point in points {
        minX = min(minX, point.x)
        minY = min(minY, point.y)
        maxX = max(maxX, point.x)
        maxY = max(maxY, point.y)
    }
    
    let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    return rect
}

// The mathematical and SwiftUI view coordinate system have different origins, bottom left vs top left, resp.
// SwiftUI : top left 
// Math : bottom left 
func flipPointsForView(points:[CGPoint], viewSize:CGSize) -> [CGPoint] {
    return points.map { point in
        CGPoint(x: point.x, y: viewSize.height - point.y)
    }
}

func fitRectInside(rect: CGRect, insideRect: CGRect) -> CGRect {
    let aspectRatioRect = rect.size.width / rect.size.height
    let aspectRatioInsideRect = insideRect.size.width / insideRect.size.height
    
    var transformedRect = rect
    
    if aspectRatioRect > aspectRatioInsideRect {
        let newWidth = insideRect.size.width
        let newHeight = newWidth / aspectRatioRect
        let yOffset = (insideRect.size.height - newHeight) / 2.0
        transformedRect = CGRect(x: insideRect.origin.x, y: insideRect.origin.y + yOffset, width: newWidth, height: newHeight)
    } else {
        let newHeight = insideRect.size.height
        let newWidth = newHeight * aspectRatioRect
        let xOffset = (insideRect.size.width - newWidth) / 2.0
        transformedRect = CGRect(x: insideRect.origin.x + xOffset, y: insideRect.origin.y, width: newWidth, height: newHeight)
    }
    
    return transformedRect
}

func scaleAndTranslateAffineTransformForRect(rect: CGRect, scale: CGFloat, origin: CGPoint) -> CGAffineTransform {
    var transform = CGAffineTransform.identity
    
        // Apply scaling
    let scaleTransform = transform.scaledBy(x: scale, y: scale)
    
        // Apply translation
    let translationX = origin.x - rect.origin.x * scale
    let translationY = origin.y - rect.origin.y * scale
    let translationTransform = transform.translatedBy(x: translationX, y: translationY)
    
    transform = scaleTransform.concatenating(translationTransform)
    
    return transform
}

func applyAffineTransformToPoints(points: [[CGPoint]], affineTransform: CGAffineTransform) -> [[CGPoint]] {
    var transformedPoints = [[CGPoint]]()
    
    for subArray in points {
        var transformedSubArray = [CGPoint]()
        
        for point in subArray {
            let transformedPoint = point.applying(affineTransform)
            transformedSubArray.append(transformedPoint)
        }
        
        transformedPoints.append(transformedSubArray)
    }
    
    return transformedPoints
}

func ScalePointsIntoView(points:[[CGPoint]], boundingRect:CGRect, viewSize:CGSize, inset:Double) -> [[CGPoint]] {
    
    let dRect = CGRect(origin: CGPoint(x: 0, y: 0), size: viewSize).insetBy(dx: inset, dy: inset)
    
    let plotRect = fitRectInside(rect: boundingRect, insideRect: dRect)
    
    let scale = (plotRect.width / boundingRect.width)
    let origin = plotRect.origin
    
    let affineTransform = scaleAndTranslateAffineTransformForRect(rect: boundingRect, scale: scale, origin: origin)
    
    return applyAffineTransformToPoints(points: points, affineTransform: affineTransform)
    
}
