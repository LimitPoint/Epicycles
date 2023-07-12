//
//  ThumbnailProvider.swift
//  ThumbnailExtension
//
//  Created by Joseph Pagliaro on 6/23/23.
//

import QuickLookThumbnailing
/*
 Don't forget:
 In Build Phases, add target dependencies and set the macOS and iOS filters for the thumbnail extensions for each platform 
 */
// ThumbnailProvider is for saving .epi files for the custom Fourier series of the Terms view
class ThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        let scale: CGFloat = request.scale
        
            // This ensures the document icon aspect ratio matches what is usual (rather than square), namely standard paper size of 8x10
            // can't use scale here
        let aspectRatio:CGFloat = 8.0 / 10.0
            //let aspectRatio:CGFloat = 1
        let thumbnailFrame = CGRect(x: 0, y: 0, width: aspectRatio * request.maximumSize.height, height: request.maximumSize.height)
        
        handler(QLThumbnailReply(contextSize: thumbnailFrame.size, drawing: { (context) -> Bool in
            
            guard FileManager.default.isReadableFile(atPath: request.fileURL.path) else {
                return false
            }
            
            guard let data: Data = try? Data.init(contentsOf: request.fileURL, options: [.uncached]) else {
                return false
            }
            
            guard let terms = try? JSONDecoder().decode([Term].self, from: data) else {
                return false
            }
            
            // Only draw the users Fourier series 
            var userPoints = sampleTerms(sampleCount: kSampleCount, terms: terms)
            
            let viewSize = CGSize(width: thumbnailFrame.size.width * scale, height: thumbnailFrame.size.height * scale)
            
            if let boundingRect = BoundingRect(points: userPoints) {
                userPoints = ScalePointsIntoView(points: [userPoints], boundingRect: boundingRect, viewSize: viewSize, inset: 0)[0]
            }
            
            let curvePath = CreatePath(points: userPoints, close: false)
            
            #if os(macOS)
            DrawPathsInContext(context: context, paths: [curvePath], width: Int(viewSize.width), height: Int(viewSize.height), lineWidth: [1], lineColor: [kLineColor[0]], backgroundColor: nil, pathScaleFactor: 1, flipCGContext: true)
            #else
            DrawPathsInContext(context: context, paths: [curvePath], width: Int(viewSize.width), height: Int(viewSize.height), lineWidth: [1], lineColor: [kLineColor[0]], backgroundColor: nil, pathScaleFactor: 1, flipCGContext: false)
            #endif
            
            
            return true
        }), nil)
    }
}
