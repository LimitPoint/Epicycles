//
//  DrawAnimatePathView.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/10/23.
//

import SwiftUI

private let fileName = "pointsData.plist"

class DrawAnimatePathViewObservable : ObservableObject {
    @Published var points: [CGPoint] = []
    
    @Published var isDrawingComplete = false
    
    @Published var maxPoints = Int.max
    var animateTimer:Timer?
    
    var pathsPadding:Double
    
    init(pathsPadding:Double) {
        if let points = DrawAnimatePathViewObservable.loadFromFile() {
            self.points = points
        }
        
        self.pathsPadding = pathsPadding
    }
    
    func addPoint(_ point: CGPoint) {
        points.append(point)
    }
    
    func startDrawing() {
        isDrawingComplete = false
    }
    
    func completeDrawing() {
        isDrawingComplete = true
        DrawAnimatePathViewObservable.saveToFile(points)
    }
    
    func clearPoints() {
        startDrawing()
        // needs a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.points = []
            self?.completeDrawing()
        }
    }
    
    func startAnimatePath() {
        
        animateTimer?.invalidate()
        animateTimer = nil
        
        maxPoints = 0
        
        let interval = 1.0 / Double(points.count)
        let schedule = { [weak self] in
            
            guard let self = self else {
                return
            }
            
            self.animateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                self.maxPoints += 1
                
                if self.maxPoints > self.points.count-1 {
                    self.maxPoints = 1
                }
            }
        }
        
        if self.animateTimer == nil {
            if Thread.isMainThread {
                schedule()
            }
            else {
                DispatchQueue.main.sync {
                    schedule()
                }
            }
        }
    }
    
    func stopAnimatePath() {
        if maxPoints != Int.max {
            animateTimer?.invalidate()
            animateTimer = nil
            maxPoints = Int.max
        }
    }
    
    func pathForPoints() -> Path {
        
        guard points.count > 0 else  {
            return Path()
        }
        
        return Path { path in
            for index in 0...min(points.count-1,maxPoints)  {
                let point = points[index]
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
    }
    
    func updatePoints(size:CGSize) {
        if let boundingRect = BoundingRect(points: points) {
            points = ScalePointsIntoView(points:[points], boundingRect: boundingRect, viewSize: CGSize(width: size.width, height: size.height), inset: pathsPadding)[0]
        }
    }
    
    static func getDocumentsDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    static func savePoints(_ points: [CGPoint], to url: URL) {
        do {
            let encodedData = try JSONEncoder().encode(points)
            try encodedData.write(to: url)
        } catch {
            print("Error while saving points: \(error)")
        }
    }
    
        // Function to read array of CGPoint from a file
    static func readPoints(from url: URL) -> [CGPoint]? {
        do {
            let data = try Data(contentsOf: url)
            let decodedPoints = try JSONDecoder().decode([CGPoint].self, from: data)
            return decodedPoints
        } catch {
            print("Error while reading points: \(error)")
            return nil
        }
    }
    
    static func saveToFile(_ points:[CGPoint]) {
        guard let fileURL = getDocumentsDirectory()?.appendingPathComponent(fileName) else {
            return
        }
        
        savePoints(points, to: fileURL)
    }
    
    static func loadFromFile() -> [CGPoint]? {
        if let loadedPointsArray = loadFromDocumentsDirectory() {
            return loadedPointsArray
        } else if let loadedPointsArray = loadFromBundleResources() {
            return loadedPointsArray
        }
        
        return nil
    }
    
    static func loadFromDocumentsDirectory() -> [CGPoint]? {
        
        guard let fileURL = getDocumentsDirectory()?.appendingPathComponent(fileName) else {
            return nil
        }
        
        return readPoints(from: fileURL)
    }
    
    static func loadFromBundleResources() -> [CGPoint]? {
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            return nil
        }
        
        return readPoints(from: fileURL)
    }
    
    static func deleteFile() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("File deleted successfully.")
        } catch {
            print("Error deleting file: \(error)")
        }
    }

}

struct DrawAnimatePathView: View {
    @ObservedObject var drawAnimatePathViewObservable:DrawAnimatePathViewObservable
    
    @State var currentPoint:CGPoint = .zero
    @State var isAnimating:Bool = false
    
    var body: some View {
        
        GeometryReader { geometry in
            
            ZStack(alignment: .bottomLeading) {
                
                drawAnimatePathViewObservable.pathForPoints()
                    .stroke(Color.red, lineWidth: 2)
                    .background(Color(red: 0.949, green: 0.949, blue: 0.97, opacity: 1.0))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                drawAnimatePathViewObservable.startDrawing()
                                isAnimating = false
                                currentPoint = value.location
                                if currentPoint.x > 0 && currentPoint.x < geometry.size.width {
                                    if currentPoint.y > 0 && currentPoint.y < geometry.size.height {
                                        drawAnimatePathViewObservable.addPoint(currentPoint)
                                    }
                                }
                            }
                            .onEnded { _ in
                                drawAnimatePathViewObservable.completeDrawing()
                            }
                    )
                
                
                HStack {
                    
                    VStack(alignment: .leading) {
                        Text("Points: \(drawAnimatePathViewObservable.points.count)")
                        Text("Width: \(String(format: "%.2f", geometry.size.width)), Height: \(String(format: "%.2f", geometry.size.height))")
                        Text("Current Point: \(String(format: "%.2f", currentPoint.x)), \(String(format: "%.2f", currentPoint.y))")
                    }
                    .font(.caption)
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isAnimating.toggle()
                        }
                    }) {
                        Image(systemName: isAnimating ? "stop.circle" : "play.circle")
                            .font(.system(size: 24))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        drawAnimatePathViewObservable.clearPoints()
                        isAnimating = false
                    }) {
                        Text("Clear")
                    }
                    .padding()
                    .buttonStyle(PlainButtonStyle())
                }
                
            }
            .onChange(of: isAnimating) { isAnimating in
                if isAnimating {
                    drawAnimatePathViewObservable.startAnimatePath()
                }
                else {
                    drawAnimatePathViewObservable.stopAnimatePath()
                }
            }
            .onChange(of: geometry.size) { newSize in
                drawAnimatePathViewObservable.updatePoints(size: newSize)
            }
        }
    }
}
