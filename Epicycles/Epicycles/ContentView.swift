//
//  ContentView.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/10/23.
//

import SwiftUI

enum UserPointsType: String, CaseIterable {
    case draw = "Draw"
    case terms = "Terms"
}

struct ContentViewAlertInfo: Identifiable {
    
    enum AlertType {
        case cantOpenFile
        case tooFewPoints
        case exported
    }
    
    let id: AlertType
    let title: String
    let message: String
}

struct ContentView: View {
    
    @State var curvePath:Path = Path()
    @State var curveFourierSeriesPath:Path = Path()
    @State var epicyclesPath:Path = Path()
    @State var epicyclesCirclesPath:Path = Path()
    @State var epicyclesPathTerminator:Path = Path()
    @State var epicyclesCirclesPaths:[Path] = [] // epicyclesCirclesPaths.count = nbrFourierSeriesTerms, adjustable by user
    
    @State var fourierSeriesPoints:[CGPoint] = [] // for path trail
    
    @State var sampleCount = kSampleCount
    
    @State var nbrIntegrationSamples = 2 * kSampleCount
    @State var nbrFourierSeriesTerms = kMaxFourierSeriesTerms // N : -nbrFourierSeriesTerms...nbrFourierSeriesTerms
    
    @State var whichCurve = curves[0]
    
    @State var currentPathViewSize = CGSize.zero
    
    // Custom Fourier Series - draw or specify terms with editor
    @State var userPointsTab:UserPointsType = .terms
    // draw view
    @StateObject var drawAnimatePathViewObservable = DrawAnimatePathViewObservable(pathsPadding: kPathsPadding)
    // amplitude, phase and frequency
    @State var terms:[Term] = (decodeTermsFromDocuments() ?? kDefaultTerms)
    
    // for onOpenURL
    @State var showURLLoadingProgress = false
    
    // Alerts
    @State var hasShownTooFewPointsAlert = false
    @State var contentViewAlertInfo: ContentViewAlertInfo?
    
    @State var epicycleTime: Double = 0
    
    @State var zoomed = false
    @State var showCircles = true
    @State var showRadii = true
    @State var showTerminator = true
    @State var showFourierSeries = true
    @State var showFunction = true
    
    @State var animateTimer:Timer?
    @State var epicyclesAnimating = false
    
    // exporting images to Photos, terms to files
    @State var showSaveToPhotosDialogView = false
    @State var selectedMediaType = kDefaultMediaType
    @State var selectedMediaSize = kDefaultMediaSize
    @State var selectedGIFDuration = kDefaultGIFDuration
    @State var selectedGIFFrameRate = kDefaultGIFFrameRate
    @State var whiteBackground = true
    @State var exportURL:URL? = nil
    @State var showAnimatedGIFProgress = false
    @State var animatedGIFProgressTitle:String = ""
    @State var animatedGIFProgressSubTitle:String?
    @State var animatedGIFProgress:Double = 0
    @State var animatedGIFProgressImage:CGImage?
    
    @State var gifGeneratorCancelled:Bool = false
    @State var gifGenerator:GIFGenerator?
    
    @StateObject var webViewObservable = WebViewObservableObject(urlString: kEpicyclesURL)
    
    @Binding var showSplashScreen:Bool
    
    // options
    @State var showOptionsView = false
    @State var resetOptions = false
    @Binding var lineWidth:[Double]
    @Binding var lineColor:[Color]
    @Binding var trailLength:Double
    
    func userPoints() -> [CGPoint] {
        switch userPointsTab {
            case .draw:
                // Note that drawAnimatePathViewObservable.points are in SwiftUI coordinates with origin top-left, but the mathematical coordinates have origin bottom-left. Flip the drawing points to undo flipping them again in CreatePaths.
                return flipPointsForView(points: drawAnimatePathViewObservable.points, viewSize: currentPathViewSize)
            case .terms:
                return sampleTerms(sampleCount: sampleCount, terms: terms)
        }
    }
    
    func suggestedNumberFourierSeriesTermsForSampleCount(_ count:Int) -> Int {
            // `nyquist freqeuncy` is defined as half sample rate in hertz
            // https://www.limit-point.com/blog/2023/tone-player/#NyquistfrequencyversusNyquistrate
        let n = (Double(count) / (2 * .pi)) / 2.0
        return min(max(Int(n),1), kMaxFourierSeriesTerms)
    }
    
    func suggestedNumberFourierSeriesTermsForTerms() -> Int {
        let n = highestAbsoluteFrequencyComponent(terms: terms) // terms ARE the Fourier series
        return min(max(Int(n),1), kMaxFourierSeriesTerms)
    }
    
    func setSuggestedNumberFourierSeriesTerms() {

        if whichCurve == curves[curves.count-1] {
            switch userPointsTab {
                case .draw:
                    if drawAnimatePathViewObservable.points.count > kMinimumPointCount {
                        nbrFourierSeriesTerms = suggestedNumberFourierSeriesTermsForSampleCount(drawAnimatePathViewObservable.points.count)
                    }
                    else {
                        nbrFourierSeriesTerms = suggestedNumberFourierSeriesTermsForSampleCount(sampleCount)
                    }
                case .terms:
                    if terms.count > 0 {
                        nbrFourierSeriesTerms = suggestedNumberFourierSeriesTermsForTerms()
                    }
                    else {
                        nbrFourierSeriesTerms = suggestedNumberFourierSeriesTermsForSampleCount(sampleCount)
                    }
            }
        }
        else {
            nbrFourierSeriesTerms = suggestedNumberFourierSeriesTermsForSampleCount(sampleCount)
        }
    }
    
    func hasTooFewPoints() -> Bool {
        var tooFewPoints = false
        switch userPointsTab {
            case .draw:
                if drawAnimatePathViewObservable.points.count <= kMinimumPointCount {
                    tooFewPoints = true
                }
            case .terms:
                if terms.count == 0 {
                    tooFewPoints = true
                }
        }
        
        return tooFewPoints
    }
    
    func updatePaths(size:CGSize, nbrFourierSeriesTerms:Int, curve:Curve) {
                
        // show alert for 'too few points'
        if hasShownTooFewPointsAlert == false, curve == curves[curves.count-1], hasTooFewPoints() {
            
            contentViewAlertInfo = ContentViewAlertInfo(id: .tooFewPoints, title: "Draw or Add Terms", message: "Draw points to define a curve.\n\nOr use the Terms editor for configuring frequency components of a Fourier series that defines the curve.\n\nThe selected number of terms N for the computed series is set to the Nyquist frequency that assumes a uniform sampling rate, based on the number of points drawn, or the highest frequency of the custom Fourier series.\n\nVary N for best results.")
            
            hasShownTooFewPointsAlert = true
        }
        
        (curvePath, curveFourierSeriesPath, epicyclesPath, epicyclesCirclesPath, epicyclesPathTerminator, epicyclesCirclesPaths, fourierSeriesPoints) = CreatePaths(epicycleTime: epicycleTime, sampleCount: sampleCount, size: size, nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: curve, userPoints: userPoints(), boundingRectAllPaths: nil)
    }
    
    func startAnimating() {
        animateTimer?.invalidate()
        animateTimer = nil
                
        let interval = 1.0 / 30.0
        let delta = .pi / 100.0
        let schedule = { 
            
            self.animateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                epicycleTime += delta
                if epicycleTime > .pi {
                    epicycleTime = -.pi
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
    
    func stopAnimating() {
        animateTimer?.invalidate()
        animateTimer = nil
    }
    
    func cancelGIFGenerator() {
        gifGenerator?.cancel()
    }
    
    func exportPathsImage()  {
        
        var size:CGSize
        let scaledSampleCount:Int
        var scaledLinewidth:[Double]
        
        switch selectedMediaSize {
            case .small:
                size = CGSize(width: 480, height: 480)
                scaledSampleCount = 1 * sampleCount
                scaledLinewidth = lineWidth.map { w in
                    1 * w
                }
            case .medium:
                size = CGSize(width: 720, height: 720)
                scaledSampleCount = 2 * sampleCount
                scaledLinewidth = lineWidth.map { w in
                    2 * w
                }
            case .large:
                size = CGSize(width: 1080, height: 1080)
                scaledSampleCount = 3 * sampleCount
                scaledLinewidth = lineWidth.map { w in
                    3 * w
                }
        }
        
        self.gifGenerator = nil
        self.exportURL = nil
        
        func exportedAlertMessage() -> String {
            var message:String
            
            if let gifGenerator = gifGenerator, gifGenerator.isCancelled {
                message = "Cancelled!"
            }
            else {
                if let _ = self.exportURL {
                    message = "Success!"
                }
                else {
                    message = "There was a problem saving. Try a smaller size or duration."
                }
            }
            
            return message
        }
        
        DispatchQueue.global().async { 
            
            switch selectedMediaType {
                case .png:
                    let scaleFactor = 1.0
                    
                    let boundingRectAllPaths = BoundingRectAllPaths(epicycleTime: epicycleTime, sampleCount: sampleCount, size: size, nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: whichCurve, userPoints: userPoints())
                    
                    if var boundingRectAllPaths = boundingRectAllPaths {
                        let maxLineWidth = scaledLinewidth.max()!/2.0
                        boundingRectAllPaths = boundingRectAllPaths.insetBy(dx: -maxLineWidth, dy: -maxLineWidth) // adjust for max linwidth/2 
                        
                            // if drawingTerms, draw circles with term colors
                        let drawingTerms = (whichCurve == curves[curves.count-1] && userPointsTab == .terms)
                        
                        self.exportURL = GenerateFrameForTime(epicycleTime: epicycleTime, sampleCount: scaledSampleCount, size: size, scaleFactor: scaleFactor, trailLength: trailLength, lineWidth: scaledLinewidth, lineColor: lineColor, backgroundColor: (whiteBackground ? .white : .clear), nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: whichCurve, userPoints: userPoints(), terms: (drawingTerms ? terms : nil), showFunction: showFunction, showFourierSeries: showFourierSeries, showRadii: showRadii, showCircles: showCircles, showTerminator: showTerminator, boundingRectAllPaths: boundingRectAllPaths)
                        
                        if let outputURL = self.exportURL {
                            print(outputURL)
                            saveImageToPhotos(url: outputURL)
                        }
                        
                        DispatchQueue.main.async {
                            contentViewAlertInfo = ContentViewAlertInfo(id: .exported, title: "Save to Photos", message: exportedAlertMessage())
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            contentViewAlertInfo = ContentViewAlertInfo(id: .exported, title: "Save to Photos", message: exportedAlertMessage())
                        }
                    }
                case .gif:
                    DispatchQueue.main.async {
                        self.animatedGIFProgressTitle = ""
                        self.animatedGIFProgressSubTitle = nil
                        self.animatedGIFProgressImage = nil
                        self.animatedGIFProgress = 0
                        self.showAnimatedGIFProgress = true
                        self.gifGeneratorCancelled = false
                    }
                    
                    let scaleFactor = 1.0
                    
                    let imageCount = selectedGIFFrameRate.rawValue * selectedGIFDuration.rawValue
                    let duration = CGFloat(selectedGIFDuration.rawValue)
                    
                        // if drawingTerms, draw circles with term colors
                    let drawingTerms = (whichCurve == curves[curves.count-1] && userPointsTab == .terms)
                    
                    self.gifGenerator = ImagePathsToAnimatedGIF(curve: whichCurve, userPoints: userPoints(), terms: (drawingTerms ? terms : nil), sampleCount: scaledSampleCount, trailLength: trailLength, nbrFourierSeriesTerms: nbrFourierSeriesTerms, size: size, scaleFactor: scaleFactor, lineWidth: scaledLinewidth, lineColor: lineColor, backgroundColor: (whiteBackground ? .white : .clear), imageCount: imageCount, duration: duration, showFunction: showFunction, showFourierSeries: showFourierSeries, showRadii: showRadii, showCircles: showCircles, showTerminator: showTerminator) { title, percent, image in
                        DispatchQueue.main.async {
                            self.animatedGIFProgressTitle = title
                            self.animatedGIFProgressSubTitle = "\(Int(size.width)) x \(Int(size.height))"
                            self.animatedGIFProgress = percent
                            self.animatedGIFProgressImage = image
                        }
                    } completion: { gifURL in
                        
                        self.exportURL = gifURL
                        
                        if let gifURL = gifURL {
                            print(gifURL)
                            saveImageToPhotos(url: gifURL)  
                        }
                        
                        DispatchQueue.main.async {
                            self.showAnimatedGIFProgress = false
                            contentViewAlertInfo = ContentViewAlertInfo(id: .exported, title: "Save to Photos", message: exportedAlertMessage())
                        }
                    }
            }
        }
    }
    
    var controlsView: some View {
        VStack {
            
            if zoomed {
                HStack {
                    
                    Button(action: {
                        epicycleTime = -.pi/2
                    }) {
                        Image(systemName: "arrow.down")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                   
                    Button(action: {
                        epicycleTime -= (2 * .pi) / 16.0
                    }) {
                        Image(systemName: "minus.square")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    ZStack {
                        Dial(angle: $epicycleTime)
                            .frame(width: 100, height: 100)
                        
                        Button(action: {
                            epicycleTime = 0
                        }) {
                            Image(systemName: "0.circle")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button(action: {
                        epicycleTime += (2 * .pi) / 16.0
                    }) {
                        Image(systemName: "plus.square")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    Button(action: {
                        epicycleTime = .pi/2
                    }) {
                        Image(systemName: "arrow.up")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            else {
                HStack {
                    
                    HStack {
                        Text("t = \(epicycleTime, specifier: "%.2f")")
                            .monospacedDigit()
                        
                        Button(action: {
                            epicycleTime = 0
                        }) {
                            Image(systemName: "0.circle")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack {
                        Text("-π")
                        Slider(value: $epicycleTime, in: -.pi...(.pi))
                        Text("π")
                    }
                }
                .padding(.vertical)
            }
            
            HStack {
                
                HStack {
                    Text("N = \(nbrFourierSeriesTerms)")
                        .monospacedDigit()
                    
                    Button(action: {
                        setSuggestedNumberFourierSeriesTerms()
                    }) {
                        Image(systemName: "wand.and.rays")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Slider(value: Binding(
                    get: { Double(nbrFourierSeriesTerms) },
                    set: { newValue in
                        nbrFourierSeriesTerms = Int(newValue.rounded())
                    }
                ), in: 1...Double(kMaxFourierSeriesTerms), step: 1)
                
            }
            .padding(.vertical)
            
            Picker(selection: $whichCurve, label: Text("")) {
                ForEach(curves) { curve in
                    Text(curve.name).tag(curve)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.vertical)
            
        }
        .onOpenURL { selectedURL in
            showURLLoadingProgress = true
            decodeTerms(from: selectedURL) { decodedTerms in
                showURLLoadingProgress = false
                if let decodedTerms = decodedTerms {
                    whichCurve = curves[curves.count-1]
                    userPointsTab = .terms
                    terms = decodedTerms
                }
                else {
                    contentViewAlertInfo = ContentViewAlertInfo(id: .cantOpenFile, title: "Can't Open File", message: "The URL can not be opened.")
                }
            }
        }
        .overlay(Group {
            if showURLLoadingProgress {          
                ProgressView("Loading...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(tangerine))
            }
        })
        .alert(item: $contentViewAlertInfo, content: { contentViewAlertInfo in
            switch contentViewAlertInfo.id {
                case .cantOpenFile:
                    return Alert(title: Text(contentViewAlertInfo.title),
                                 message: Text(contentViewAlertInfo.message),
                                 dismissButton: .default(Text("OK")))
                case .tooFewPoints:
                    return Alert(title: Text(contentViewAlertInfo.title),
                                 message: Text(contentViewAlertInfo.message),
                                 dismissButton: .default(Text("OK")))
                case .exported:
                    return Alert(title: Text(contentViewAlertInfo.title),
                                 message: Text(contentViewAlertInfo.message),
                                 dismissButton: .default(Text("OK")))
            }
        })
    }
    
    var pathsView: some View {
        
        GeometryReader { geometry in
            
            ZStack {
                
                if showFunction {
                    curvePath
                        .stroke(lineColor[0], style: StrokeStyle(lineWidth: lineWidth[0], lineCap: CGLineCap.round, lineJoin: CGLineJoin.round))
                }
                
                if showFourierSeries {
                    if trailLength > 0, fourierSeriesPoints.count > 1 {
                        ForEach(0 ..< fourierSeriesPoints.count-1, id: \.self) { j in
                            Path { path in
                                path.move(to: fourierSeriesPoints[j])
                                path.addLine(to: fourierSeriesPoints[j+1])
                            }
                            .stroke(lineColor[1].opacity(trailAlpha(j, epicycleTime: epicycleTime, pathPointCount: fourierSeriesPoints.count, trailLength: trailLength)), style: StrokeStyle(lineWidth:  lineWidth[1], lineCap: CGLineCap.butt, lineJoin: CGLineJoin.miter))
                        }
                    }
                    else {
                        curveFourierSeriesPath
                            .stroke(lineColor[1], style: StrokeStyle(lineWidth:  lineWidth[1], lineCap: CGLineCap.round, lineJoin: CGLineJoin.round))
                    }
                }
                
                if showRadii {
                    epicyclesPath
                        .stroke(lineColor[2], style: StrokeStyle(lineWidth:  lineWidth[2], lineCap: CGLineCap.round, lineJoin: CGLineJoin.round))
                }
                
                if showCircles {
                    
                        // if drawingTerms, draw circles with term colors
                    let drawingTerms = (whichCurve == curves[curves.count-1] && userPointsTab == .terms)
                    
                    // For Term view draw circles with term color
                    if drawingTerms {
                        // draw the circle for each term by mapping frequencyComponents to epicyclesCirclesPaths
                        // Note: epicyclesCirclesPaths.count = nbrFourierSeriesTerms
                        if terms.count > 0 {
                            ForEach(0 ..< terms.count, id: \.self) { j in
                                if let k = fourierSeriesIndexForTerm(term: terms[j], nbrFourierSeriesTerms: epicyclesCirclesPaths.count) {
                                    epicyclesCirclesPaths[k]
                                        .stroke(terms[j].color, style: StrokeStyle(lineWidth:  lineWidth[3], lineCap: CGLineCap.round, lineJoin: CGLineJoin.round))
                                }
                            }
                        }
                    }
                    else {
                        epicyclesCirclesPath
                            .stroke(lineColor[3], style: StrokeStyle(lineWidth:  lineWidth[3], lineCap: CGLineCap.round, lineJoin: CGLineJoin.round))
                    }

                }
                
                if showTerminator {
                    epicyclesPathTerminator
                        .stroke(lineColor[4], style: StrokeStyle(lineWidth:  lineWidth[4], lineCap: CGLineCap.round, lineJoin: CGLineJoin.round))
                }
                
            }
            .onChange(of: geometry.size) { newSize in
                currentPathViewSize = geometry.size
                updatePaths(size:newSize, nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: whichCurve)
            }
            .onChange(of: nbrFourierSeriesTerms) { newTerms in
                updatePaths(size: currentPathViewSize, nbrFourierSeriesTerms: newTerms, curve: whichCurve)
            }
            .onChange(of: userPointsTab) { _ in
                if whichCurve != curves[curves.count-1] {
                    whichCurve = curves[curves.count-1]
                }
                setSuggestedNumberFourierSeriesTerms()
                updatePaths(size: currentPathViewSize, nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: whichCurve)
            }
            .onChange(of: terms) { _ in
                if whichCurve != curves[curves.count-1] {
                    whichCurve = curves[curves.count-1]
                }
                setSuggestedNumberFourierSeriesTerms()
                updatePaths(size: currentPathViewSize, nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: whichCurve)
                let _ = encodeTermsToDocuments(terms: terms)
            }
            .onChange(of: epicycleTime) { _ in
                updatePaths(size: currentPathViewSize, nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: whichCurve)
            }
            .onChange(of: whichCurve) { newCurve in
                setSuggestedNumberFourierSeriesTerms()
                updatePaths(size: currentPathViewSize, nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: newCurve)
            }
            .onChange(of: epicyclesAnimating) { newEpicyclesAnimating in
                newEpicyclesAnimating ? startAnimating() : stopAnimating()
            }
            .onAppear {
                currentPathViewSize = geometry.size
                setSuggestedNumberFourierSeriesTerms()
                updatePaths(size:geometry.size, nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: whichCurve)
            }
        }
    }
    
    var pathsViewMenuView: some View {
        HStack(spacing: 16.0) {
            Button(action: {
                withAnimation {
                    zoomed.toggle()
                }
            }) {
                Image(systemName: zoomed ? "minus.magnifyingglass" : "plus.magnifyingglass")
                    .font(.system(size: 18))
            }
            
            Button(action: {
                withAnimation {
                    showCircles.toggle()
                }
            }) {
                Image(systemName: showCircles ? "circle.slash" : "circle")
                    .font(.system(size: 18))
            }
            
            Button(action: {
                withAnimation {
                    showTerminator.toggle()
                }
            }) {
                Image(systemName: showTerminator ? "eye.slash.circle" : "eye.circle")
                    .font(.system(size: 18))
            }
            
            Button(action: {
                withAnimation {
                    showRadii.toggle()
                }
            }) {
                Image(systemName: showRadii ? "bolt.slash" : "bolt")
                    .font(.system(size: 18))
            }
            
            Button(action: {
                withAnimation {
                    showFunction.toggle()
                }
            }) {
                Image(systemName: showFunction ? "pencil.slash" : "pencil")
                    .font(.system(size: 18))
            }
            
            Button(action: {
                withAnimation {
                    showFourierSeries.toggle()
                }
            }) {
                Image(systemName: showFourierSeries ? "star.slash" : "star")
                    .font(.system(size: 18))
            }
            
            Button(action: {
                if epicyclesAnimating {
                    epicyclesAnimating = false
                }
                showSaveToPhotosDialogView = true
            }, label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                }
            })
            .sheet(isPresented: $showSaveToPhotosDialogView) {
                DialogView(selectedMediaType: $selectedMediaType, selectedMediaSize: $selectedMediaSize, selectedGIFDuration: $selectedGIFDuration, selectedGIFFrameRate: $selectedGIFFrameRate, whiteBackground: $whiteBackground, saveAction: {
                    showSaveToPhotosDialogView = false
                    exportPathsImage()
                },
                           cancelAction: {
                    
                    showSaveToPhotosDialogView = false
                })
            }
            
            Button(action: {
                withAnimation {
                    epicyclesAnimating.toggle()
                }
            }) {
                Image(systemName: epicyclesAnimating ? "stop.circle" : "play.circle")
                    .font(.system(size: 18))
            }
            
            Button(action: {
                withAnimation {
                    webViewObservable.isWebViewPresented = true
                }
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 18))
            }
            
            Button(action: {
                showOptionsView = true
            }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18))
            }
        }
        .padding(4)
        .buttonStyle(PlainButtonStyle())
        .background(
            Rectangle()
                .fill(bluePinkColor)
                .cornerRadius(10)
                .shadow(color: Color.gray.opacity(0.5), radius: 3, x: 5, y: 5)
                .opacity(0.5)
        )
    }
    
    var mainView: some View {
        VStack {
            CornerSnappingView { 
                pathsView
                    .padding()
            } snappingView: { 
                pathsViewMenuView
            }
            
            DisclosureGroup("Time and Term Count", isExpanded: $isExpanded) {
                controlsView
            }
            .padding(.horizontal)
            
            if zoomed == false {
                TabView(selection: $userPointsTab) {
                    DrawAnimatePathView(drawAnimatePathViewObservable: drawAnimatePathViewObservable)
                        .padding()
                        .tabItem {
                            Label(UserPointsType.draw.rawValue, systemImage: "pencil")
                        }
                        .tag(UserPointsType.draw)
                    
                    FourierSeriesTermsView(terms: $terms)
                        .padding()
                        .tabItem {
                            Label(UserPointsType.terms.rawValue, systemImage: "slider.horizontal.3")
                        }
                        .tag(UserPointsType.terms)
                }
            }
        }
        .onChange(of: drawAnimatePathViewObservable.isDrawingComplete) { isDrawingComplete in
            if isDrawingComplete == true {
                whichCurve = curves[curves.count-1]
                setSuggestedNumberFourierSeriesTerms()
                updatePaths(size: currentPathViewSize, nbrFourierSeriesTerms: nbrFourierSeriesTerms, curve: whichCurve)
            }
        }
        .onChange(of: gifGeneratorCancelled) { gifGeneratorCancelled in
            if gifGeneratorCancelled {
                gifGenerator?.cancel()
            }
        }
        .onChange(of: lineColor) { newLineColor in
            saveColorsToUserDefaults(colors: newLineColor, forKey: kColorKey)
        }
        .onChange(of: lineWidth) { newLineWidth in
            UserDefaults.standard.set(newLineWidth, forKey: kWidthKey)
        }
        .onChange(of: trailLength) { newTrailLength in
            UserDefaults.standard.set(newTrailLength, forKey: kTrailLengthKey)
        }
        .onChange(of: resetOptions) { newResetOptions in
            if newResetOptions {
                lineWidth = kLineWidth
                lineColor = kLineColor
                trailLength = kTrailLength
                saveColorsToUserDefaults(colors: nil, forKey: kColorKey)
                UserDefaults.standard.removeObject(forKey: kWidthKey)
                UserDefaults.standard.removeObject(forKey: kTrailLengthKey)
                resetOptions = false
            }
        }
        .overlay(Group {
            if showOptionsView {          
                OptionsView(lineWidth: $lineWidth, lineColor: $lineColor, trailLength: $trailLength, resetOptions: $resetOptions, doneAction: {
                    showOptionsView = false
                })
                .padding()
            }
        })
        
    }
    
    @State private var isExpanded:Bool = true
    
    var body: some View {
        
        ZStack {
            
            if webViewObservable.isWebViewPresented {
                WebView(webViewModel: webViewObservable)
            }
            else {
                mainView
            }
            
            if showAnimatedGIFProgress {
                ProgressOverlayView(progress: animatedGIFProgress, progressImage: animatedGIFProgressImage, title: animatedGIFProgressTitle, subTitle: animatedGIFProgressSubTitle, gifGeneratorCancelled: $gifGeneratorCancelled)
            }
            
            if showSplashScreen {
                SplashScreenView(showSplashScreen: $showSplashScreen)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: zoomed)
        .animation(.easeInOut(duration: 0.5), value: isExpanded)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(showSplashScreen: .constant(false), lineWidth: .constant(kLineWidth), lineColor: .constant(kLineColor), trailLength: .constant(kTrailLength))
    }
}

struct ContentView2_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(showSplashScreen: .constant(true), lineWidth: .constant(kLineWidth), lineColor: .constant(kLineColor), trailLength: .constant(kTrailLength))
    }
}


