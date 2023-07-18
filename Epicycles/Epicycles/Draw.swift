//
//  Draw.swift
//  TonePlayer
//
//  Created by Joseph Pagliaro on 2/7/23.
//
import Foundation
import SwiftUI
import CoreServices
import UniformTypeIdentifiers
import Photos

func scaleCGPaths(_ paths: [CGPath], scaleX: CGFloat, scaleY: CGFloat) -> [CGPath] {
    
    var scaledPaths: [CGPath] = []
    
    for path in paths {
        var scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        let scaledPath = path.copy(using: &scaleTransform)
        
        if let scaledPath = scaledPath {
            scaledPaths.append(scaledPath)
        }
    }
    
    return scaledPaths
}

func DrawPathsInContext(context:CGContext, paths:[Path], width:Int, height:Int, lineWidth:[Double], lineColor:[Color], lineCap:[CGLineCap], lineJoin:[CGLineJoin], backgroundColor: Color?, pathScaleFactor:Double, flipCGContext:Bool = true) {
    
    guard paths.count > 0, paths.count == lineWidth.count, paths.count == lineColor.count, paths.count == lineCap.count, paths.count == lineJoin.count  else {
        return
    }
    
    context.setAllowsAntialiasing(true)
    
    if flipCGContext {
        context.translateBy(x: 0, y: Double(height));
        context.scaleBy(x: 1, y: -1)
    }
    
    if let backgroundColor = backgroundColor{
        context.beginPath()
        let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
        context.addRect(rect)
#if os(macOS)
        context.setFillColor(NSColor(backgroundColor).cgColor)
#else
        context.setFillColor(UIColor(backgroundColor).cgColor)
#endif
        
        context.fillPath()
    }
    
    let pathsToScale = paths.map { path in
        path.cgPath
    }
    
    let scaledPaths = scaleCGPaths(pathsToScale, scaleX: pathScaleFactor, scaleY: pathScaleFactor)
    
    for i in 0...scaledPaths.count-1 {
        let scaledPath = scaledPaths[i]
        
        context.setLineWidth(lineWidth[i])
        context.setLineCap(lineCap[i])
        context.setLineJoin(lineJoin[i])
        
#if os(macOS)
        context.setStrokeColor(NSColor(lineColor[i]).cgColor)
#else
        context.setStrokeColor(UIColor(lineColor[i]).cgColor)
#endif
        
        context.beginPath()
        
        context.addPath(scaledPath)
        context.drawPath(using: .stroke)
    }
}

#if os(macOS)

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

func CreateNSImageForPaths(paths:[Path], width: Double, height: Double, lineWidth:[Double], lineColor:[Color], lineCap:[CGLineCap], lineJoin:[CGLineJoin], backgroundColor: Color?, pathScaleFactor:Double) -> NSImage? {
    
    if  ((width == 0) || (height == 0)) {
        return nil
    }
    
    let size = NSSize(width: width, height:height)
    let img = NSImage(size: size)
    
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: NSColorSpaceName.deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0) else {
        return nil
    }
    
    guard let nsGraphicsContext = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
    
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsGraphicsContext
    
    let context = nsGraphicsContext.cgContext
    
    DrawPathsInContext(context: context, paths: paths, width: Int(width), height: Int(height), lineWidth:lineWidth, lineColor:lineColor, lineCap: lineCap, lineJoin: lineJoin, backgroundColor: backgroundColor, pathScaleFactor: pathScaleFactor, flipCGContext: true)
    
    NSGraphicsContext.restoreGraphicsState()
    
    img.addRepresentation(rep)
    
    return img
}
#else
extension UIImage {
    var pngData: Data? {
        return self.pngData()
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

func CreateUIImageForPaths(paths:[Path], width: Double, height: Double, lineWidth:[Double], lineColor:[Color], lineCap:[CGLineCap], lineJoin:[CGLineJoin], backgroundColor: Color?, pathScaleFactor:Double) -> UIImage? {
    
    UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 1.0)
    
    if let context = UIGraphicsGetCurrentContext() {
        
        DrawPathsInContext(context: context, paths: paths, width: Int(width), height: Int(height), lineWidth: lineWidth, lineColor: lineColor, lineCap: lineCap, lineJoin: lineJoin, backgroundColor: backgroundColor, pathScaleFactor: pathScaleFactor, flipCGContext: false)
        
        if let img = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return img
        }
    }
    
    return nil
}
#endif

func ImagePathsToPNG(paths:[Path], width: Double, height: Double, lineWidth:[Double], lineColor:[Color], lineCap:[CGLineCap], lineJoin:[CGLineJoin], backgroundColor: Color?, url: URL, pathScaleFactor:Double) -> URL? {
    
    var destinationURL = url
    
    if destinationURL.pathExtension != "png" {
        destinationURL.deletePathExtension()
        destinationURL.appendPathExtension("png")
    }
    
    var outputURL:URL?
    
#if os(macOS)
    if let nsimage = CreateNSImageForPaths(paths: paths, width: width, height: height, lineWidth: lineWidth, lineColor: lineColor, lineCap: lineCap, lineJoin: lineJoin, backgroundColor: backgroundColor, pathScaleFactor: pathScaleFactor) {
        if nsimage.pngWrite(to: destinationURL) {
            outputURL = destinationURL
        }
    }
#else
    if let uiimage = CreateUIImageForPaths(paths: paths, width: width, height: height, lineWidth: lineWidth, lineColor: lineColor, lineCap: lineCap, lineJoin: lineJoin, backgroundColor: backgroundColor, pathScaleFactor: pathScaleFactor) {
        if uiimage.pngWrite(to: destinationURL) {
            outputURL = destinationURL
        }
    }    
#endif
    
    return outputURL
}

func saveImageToPhotos(url: URL) {
    PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized {
            PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                creationRequest?.creationDate = Date()
            } completionHandler: { success, error in
                if success {
                    print("Image saved to Photos app successfully.")
                } else {
                    if let error = error {
                        print("Error saving image to Photos app: \(error.localizedDescription)")
                    } else {
                        print("Unknown error occurred while saving image to Photos app.")
                    }
                }
            }
        }
    }
}

class GIFGenerator {
    
    var isCancelled = false
    
    func cancel() {
        isCancelled = true
    }
    
    func estimateBoundingRect(timeIntervals:Int, sampleCount:Int, size:CGSize, nbrFourierSeriesTerms:Int, curve:Curve, userPoints: [CGPoint]?, progress:@escaping (Int, CGFloat)->Void, completion: @escaping (CGRect?) -> ()) {
        
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.5) {  [weak self] in
            
            guard let self = self else {
                completion(nil)
                return
            }
            
            let delta = 2.0 * .pi / Double(timeIntervals)
            
            var epicycleTime:Double 
            var boundingRects:[CGRect] = []
            
            for i in 0...timeIntervals {
                
                if self.isCancelled {
                    break
                }
                
                epicycleTime = -Double.pi + Double(i) * delta
                
                let paths = CreatePaths(epicycleTime: epicycleTime, sampleCount: sampleCount, size: size, nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: curve, userPoints: userPoints, boundingRectAllPaths: nil)
                
                if let br = BoundingRect(rectangles: [paths.0.boundingRect, paths.1.boundingRect, paths.2.boundingRect, paths.3.boundingRect, paths.4.boundingRect]) {
                    boundingRects.append(br)
                }
                
                progress(i, Double(i)/Double(timeIntervals))
            }
            
            completion(BoundingRect(rectangles: boundingRects))
        }
    }

    func animatedGif(imageCount:Int, duration:CGFloat, imageAtIndex:@escaping (Int)->CGImage?, progress:@escaping (CGFloat, CGImage?)->Void, completion: @escaping (URL?) -> ()) {
        
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.5) { [weak self] in
            
            guard let self = self else {
                completion(nil)
                return
            }
            
            let delay = duration / CGFloat(imageCount)
            
            let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]  as CFDictionary
        
            let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFDelayTime as String): delay]] as CFDictionary
            
            let documentsDirectoryURL: URL? = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileURL: URL? = documentsDirectoryURL?.appendingPathComponent("animated.gif")
            
            if let url = fileURL as CFURL? {
                
                if FileManager.default.fileExists(atPath: fileURL!.path) {
                    do {
                        try FileManager.default.removeItem(atPath: fileURL!.path)
                        
                    } catch _ as NSError {
                    }
                }
                
                    // kUTTypeGIF -> UTType.gif.identifier as CFString
                if let destination = CGImageDestinationCreateWithURL(url, UTType.gif.identifier as CFString, imageCount, nil) {
                    CGImageDestinationSetProperties(destination, fileProperties)
                    for count in 1...imageCount {
                        
                        if self.isCancelled {
                            break
                        }
                        
                        autoreleasepool {
                            let percent = CGFloat(count)/CGFloat(imageCount)
                            
                            if let cgImage = imageAtIndex(count) {
                                CGImageDestinationAddImage(destination, cgImage, frameProperties)
                                progress(percent, cgImage)
                            }
                            else {
                                progress(percent, nil)
                            }
                        }
                    }
                    
                    if self.isCancelled {
                        completion(nil)
                    }
                    else {
                        if !CGImageDestinationFinalize(destination) {
                            completion(nil)
                        }
                        else {
                            completion(fileURL)
                        }
                    }
                }
            }
        }
    }
}

func BoundingRect(rectangles: [CGRect]) -> CGRect? {
    guard !rectangles.isEmpty else {
            // No rectangles to calculate bounding rectangle
        return nil
    }
    
    var minX = rectangles[0].origin.x
    var maxX = rectangles[0].origin.x + rectangles[0].size.width
    var minY = rectangles[0].origin.y
    var maxY = rectangles[0].origin.y + rectangles[0].size.height
    
    for rect in rectangles {
        minX = min(minX, rect.origin.x)
        maxX = max(maxX, rect.origin.x + rect.size.width)
        minY = min(minY, rect.origin.y)
        maxY = max(maxY, rect.origin.y + rect.size.height)
    }
    
    let width = maxX - minX
    let height = maxY - minY
    
    return CGRect(x: minX, y: minY, width: width, height: height)
}

func BoundingRectAllPaths(epicycleTime:Double, sampleCount:Int, size:CGSize, nbrFourierSeriesTerms:Int, curve:Curve, userPoints: [CGPoint]?) -> CGRect? {
    
    let paths = CreatePaths(epicycleTime: epicycleTime, sampleCount: sampleCount, size: size, nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: curve, userPoints: userPoints, boundingRectAllPaths: nil)
    
    return BoundingRect(rectangles: [paths.0.boundingRect, paths.1.boundingRect, paths.2.boundingRect, paths.3.boundingRect, paths.4.boundingRect])
}

func CreatePaths(epicycleTime:Double, sampleCount:Int, size:CGSize, nbrFourierSeriesTerms:Int, curve:Curve, userPoints: [CGPoint]?, boundingRectAllPaths: CGRect?) -> (Path,Path,Path,Path,Path,[Path], [CGPoint]) {
    
    var points_curve:[CGPoint] = []
    var points_fs:[CGPoint]
    var points_epicycle:[CGPoint]
    
    if curve != curves[curves.count-1] {
        let (x,y) = curveLookup(curve: curve)
        
        points_curve = sampleCurve(sampleCount: sampleCount, x: x, y: y)
        
        let An = fourierCoefficientsForPoints(nbrFourierSeriesTerms: nbrFourierSeriesTerms, points: points_curve)
        
        points_fs = fourierSeriesForCoefficients(sampleCount: points_curve.count, An: An)
        points_epicycle = fourierSeriesEpicyclePoints(epicycleTime, An: An)
        
    }
    else {
        if let userPoints = userPoints, userPoints.count > kMinimumPointCount {
            points_curve = userPoints
            
            let An = fourierCoefficientsForPoints(nbrFourierSeriesTerms: nbrFourierSeriesTerms, points: points_curve)
            
            points_fs = fourierSeriesForCoefficients(sampleCount: points_curve.count, An: An)
            points_epicycle = fourierSeriesEpicyclePoints(epicycleTime, An: An)
        }
        else {
            
            let (x,y) = curveLookup(curve: curves[curves.count-1])
            
            points_curve = sampleCurve(sampleCount: sampleCount, x: x, y: y)
            
            let An = fourierCoefficientsForPoints(nbrFourierSeriesTerms: nbrFourierSeriesTerms, points: points_curve)
            
            points_fs = fourierSeriesForCoefficients(sampleCount: points_curve.count, An: An)
            points_epicycle = fourierSeriesEpicyclePoints(epicycleTime, An: An)
        
        }
    }
    
        // The mathematical and SwiftUI view coordinate system have different origins, bottom left vs top left, resp.
    points_curve = flipPointsForView(points: points_curve, viewSize: size)
    points_fs = flipPointsForView(points: points_fs, viewSize: size)
    points_epicycle = flipPointsForView(points: points_epicycle, viewSize: size)
    
    var points = [points_curve, points_fs, points_epicycle]
    
    if let curve_boundingRect = BoundingRect(points: points_curve) {
        points = ScalePointsIntoView(points: points, boundingRect: curve_boundingRect, viewSize: size, inset: kPathsPadding)
    }
    
    if let boundingRectAllPaths = boundingRectAllPaths {
        points = ScalePointsIntoView(points: points, boundingRect: boundingRectAllPaths, viewSize: size, inset: kPathsPadding)
    }
    
    let curvePath = CreatePath(points: points[0], close: false)
    let curveFourierSeriesPath = CreatePath(points: points[1], close: false)
    let epicyclesPath = CreatePath(points: points[2], close: false)
    let (epicyclesCirclesPath, epicyclesCirclesPaths) = CreateEpicirclesPath(points: points[2])
    let epicyclesPathTerminator = CreateTerminatingCirclePath(points: points[2], circleRadius: 3)
    
    return (curvePath, curveFourierSeriesPath, epicyclesPath, epicyclesCirclesPath, epicyclesPathTerminator, epicyclesCirclesPaths, points[1])
}

/*
 Computes alpha for color values along the Fourier series path to create a path trail. The path trail starts fully opaque (alpha = 1) at the current epicycleTime, and fades to full transparency (alpha = 0) at the end. The rate of fading is a power, trailLength. 
 */
func trailAlpha(_ j:Int, epicycleTime:Double, pathPointCount:Int, trailLength:Double) -> Double {
    // Add .pi since epicycleTime is in [-.pi, pi]
    let g = ((epicycleTime + .pi) / (2 * .pi)) + ( 1.0 - Double(j)/Double(pathPointCount-1) )
    return pow(1 - g.truncatingRemainder(dividingBy: 1), trailLength)
}

/*
 
 • scaleFactor applies to image size and line widths
 
 • lineWidth, lineColor have 5 elements each for each of the 5 types of curves drawn
 
 • terms are used to color the epicycle circles, and should only be non-nil if the current path is the custom Fourier series path (Terms view)

 */

func GenerateFrameForTime(epicycleTime:Double, sampleCount:Int, size:CGSize, scaleFactor:Double, trailLength:Double, lineWidth:[Double], lineColor:[Color], backgroundColor: Color?, nbrFourierSeriesTerms:Int, curve:Curve, userPoints: [CGPoint]?, terms:[Term]?, showFunction:Bool, showFourierSeries:Bool, showRadii:Bool, showCircles:Bool, showTerminator:Bool, boundingRectAllPaths: CGRect?) -> URL? {
    
    guard lineWidth.count == 5, lineColor.count == 5 else {
        print("lineWidth or lineColor count must be 5")
        return nil
    }
    
    guard let url = FileManager.documentsURL(filename: "Paths", subdirectoryName: nil) else {
        print("output url could not be created")
        return nil
    }
    
    let (curvePath, curveFourierSeriesPath, epicyclesPath, epicyclesCirclesPath, epicyclesPathTerminator, epicyclesCirclesPaths, fourierSeriesPoints) = CreatePaths(epicycleTime: epicycleTime, sampleCount: sampleCount, size: size, nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: curve, userPoints: userPoints, boundingRectAllPaths: boundingRectAllPaths)
    
    let imageWidth = scaleFactor * size.width
    let imageHeight = scaleFactor * size.height
    
    var pathToDraw:[Path] = []
    var pathLineColor:[Color] = []
    var pathLineWidth:[Double] = []
    
    var pathLineCap:[CGLineCap] = []
    var pathLineJoin:[CGLineJoin] = []
    
    if showFunction {
        pathToDraw.append(curvePath)
        pathLineWidth.append(scaleFactor * lineWidth[0])
        pathLineColor.append(lineColor[0])
        pathLineCap.append(CGLineCap.round)
        pathLineJoin.append(CGLineJoin.round)
    }
    
    if showFourierSeries {
        if trailLength > 0, fourierSeriesPoints.count > 1 {
            for j in 0...fourierSeriesPoints.count-2 {
                let path = Path { path in
                    path.move(to: fourierSeriesPoints[j])
                    path.addLine(to: fourierSeriesPoints[j+1])
                }
                pathToDraw.append(path)
                pathLineWidth.append(scaleFactor * lineWidth[1])
                pathLineColor.append(lineColor[1].opacity(trailAlpha(j, epicycleTime: epicycleTime, pathPointCount: fourierSeriesPoints.count, trailLength: trailLength)))
                pathLineCap.append(CGLineCap.butt) // the opacity gradient levels cause a dotted appearance with .round for each
                pathLineJoin.append(CGLineJoin.miter)
            }
        }
        else {
            pathToDraw.append(curveFourierSeriesPath)
            pathLineWidth.append(scaleFactor * lineWidth[1])
            pathLineColor.append(lineColor[1])
            pathLineCap.append(CGLineCap.round)
            pathLineJoin.append(CGLineJoin.round)
        }
    }
    
    if showRadii {
        pathToDraw.append(epicyclesPath)
        pathLineWidth.append(scaleFactor * lineWidth[2])
        pathLineColor.append(lineColor[2])
        pathLineCap.append(CGLineCap.round)
        pathLineJoin.append(CGLineJoin.round)
    }
    
    if showCircles, terms == nil { // don't draw these if drawing circles for terms (below), creates a 'dot' artifact at center
        pathToDraw.append(epicyclesCirclesPath)
        pathLineWidth.append(scaleFactor * lineWidth[3])
        pathLineColor.append(lineColor[3])
        pathLineCap.append(CGLineCap.round)
        pathLineJoin.append(CGLineJoin.round)
    }
    
    if showTerminator {
        pathToDraw.append(epicyclesPathTerminator)
        pathLineWidth.append(scaleFactor * lineWidth[4])
        pathLineColor.append(lineColor[4])
        pathLineCap.append(CGLineCap.round)
        pathLineJoin.append(CGLineJoin.round)
    }
    
    // append the epicyclesCirclesPaths with corresponding terms colors; same lineWidth 
    if showCircles {
        if let terms = terms, terms.count > 0 {
            for j in 0...terms.count-1 { 
                if let k = fourierSeriesIndexForTerm(term: terms[j], nbrFourierSeriesTerms: epicyclesCirclesPaths.count) {
                    pathToDraw.append(epicyclesCirclesPaths[k])
                    pathLineWidth.append(scaleFactor * lineWidth[3])
                    pathLineColor.append(terms[j].color)
                    pathLineCap.append(CGLineCap.round)
                    pathLineJoin.append(CGLineJoin.round)
                }
            }
        }
    }
    
    if let imageURL = ImagePathsToPNG(paths: pathToDraw, width: imageWidth, height: imageHeight, lineWidth: pathLineWidth, lineColor: pathLineColor, lineCap: pathLineCap, lineJoin: pathLineJoin, backgroundColor: backgroundColor, url: url, pathScaleFactor: scaleFactor) {
        
        return imageURL
    }
    
    return nil
}

func ImagePathsToAnimatedGIF(curve:Curve, userPoints: [CGPoint]?, terms: [Term]?, sampleCount:Int, trailLength: Double, nbrFourierSeriesTerms:Int, size:CGSize, scaleFactor:Double, lineWidth:[Double], lineColor:[Color], backgroundColor: Color?, imageCount:Int, duration:CGFloat, showFunction:Bool, showFourierSeries:Bool, showRadii:Bool, showCircles:Bool, showTerminator:Bool, progress:@escaping (String, CGFloat, CGImage?)->Void, completion: @escaping (URL?) -> Void) -> GIFGenerator {
    
    let gifGenerator = GIFGenerator()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        
        gifGenerator.estimateBoundingRect(timeIntervals: imageCount, sampleCount: sampleCount, size: size, nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: curve, userPoints: userPoints) { _, percent in
            progress("Preparing…", percent, nil)
        } completion: { estimatedBoundingRect in
            if var estimatedBoundingRect = estimatedBoundingRect {
                let maxLineWidth = lineWidth.max()!/2.0
                estimatedBoundingRect = estimatedBoundingRect.insetBy(dx: -maxLineWidth, dy: -maxLineWidth) // adjust for max linwidth/2 
                gifGenerator.animatedGif(imageCount: imageCount, duration: duration) { i in
                    if let imageFrameURL = GenerateFrameForTime(epicycleTime: (Double(i-1) * (2.0 * .pi) / Double(imageCount)), sampleCount: sampleCount, size: size, scaleFactor: scaleFactor, trailLength: trailLength, lineWidth:lineWidth, lineColor:lineColor, backgroundColor: backgroundColor, nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: curve, userPoints: userPoints, terms: terms, showFunction: showFunction, showFourierSeries: showFourierSeries, showRadii: showRadii, showCircles: showCircles, showTerminator: showTerminator, boundingRectAllPaths: estimatedBoundingRect), let ciimage = CIImage(contentsOf: imageFrameURL) {
                        return ciimage.cgimage()
                    } 
                    return nil
                } progress: { percent, cgImage in
                    progress("Generating GIF…", percent, cgImage)
                } completion: { url in
                    completion(url)
                }
            }
            else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    return gifGenerator
}
