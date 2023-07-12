//
//  FourierSeriesTermsView.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/20/23.
//

import SwiftUI
import UniformTypeIdentifiers

let kDefaultTerms = [
    Term(amplitude: 0.75, phase: 2.0943951023931953, frequencyComponent: -1, color: .red), 
    Term(amplitude: 0.55, phase: 2.792526803190927, frequencyComponent: 2, color: .green),
Term(amplitude: 0.23, phase: 3.490658503988659, frequencyComponent: 5, color: .blue)]

struct TermsAlertInfo: Identifiable {

    enum AlertType {
        case cantImportFile
        case importTerms
        case exportTerms
        case removeTerm
        case removeAllTerms
    }
    
    let id: AlertType
    let title: String
    let message: String
}

struct Term: Identifiable, Equatable, Codable {
    let id = UUID()
    var amplitude: Double // -1...1
    var phase: Double // 0...2 * .pi
    var frequencyComponent: Int // -20...20 
    var color: Color
    
    enum CodingKeys: String, CodingKey {
        case amplitude
        case phase
        case frequencyComponent
        case color
    }
    
    init(amplitude: Double = 0.5, phase: Double = 0.0, frequencyComponent: Int = 1, color: Color = bluePinkColor) {
        self.amplitude = amplitude
        self.phase = phase
        self.frequencyComponent = frequencyComponent
        self.color = color
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        amplitude = try container.decode(Double.self, forKey: .amplitude)
        phase = try container.decode(Double.self, forKey: .phase)
        frequencyComponent = try container.decode(Int.self, forKey: .frequencyComponent)
        
        if let colorData = try container.decodeIfPresent(Data.self, forKey: .color),
           let decodedColor = Color.decode(data: colorData) {
            color = decodedColor
        } else {
            color = .blue // Default color if decoding fails
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amplitude, forKey: .amplitude)
        try container.encode(phase, forKey: .phase)
        try container.encode(frequencyComponent, forKey: .frequencyComponent)
        try container.encode(color.encode(), forKey: .color)
    }
    
    func description() -> String {
        
        let (red, green, blue, opacity) = self.color.rgbaComponents()
        
        return "amplitude: \(amplitude), phase: \(phase), frequencyComponent: \(frequencyComponent), Color (RGBA): \(red), \(green), \(blue), \(opacity)"
    }
}

func encodeTermsToDocuments(terms:[Term], filename:String = "CustomFourierSeries") -> URL? {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return nil
    }
    
    let fileURL = documentsDirectory.appendingPathComponent("\(filename).json")
    
    do {
        let encodedData = try JSONEncoder().encode(terms)
        try encodedData.write(to: fileURL)
    } catch {
        return nil
    }
    
    return fileURL 
}

func decodeTermsFromDocuments(filename:String = "CustomFourierSeries") -> [Term]? {
    
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return nil
    }
    let fileURL = documentsDirectory.appendingPathComponent("\(filename).json")
    
    var decodedTerms:[Term]?
    
    do {
        let jsonData = try Data(contentsOf: fileURL)
        decodedTerms = try JSONDecoder().decode([Term].self, from: jsonData)
    } catch {
    }
    
    return decodedTerms
}

func tryDownloadingUbiquitousItem(_ url: URL, completion: @escaping (URL?) -> ()) {
    
    var downloadedURL:URL?
    
    if FileManager.default.isUbiquitousItem(at: url) {
        
        let queue = DispatchQueue(label: "com.limit-point.startDownloadingUbiquitousItem")
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now()) {
            
            do {
                try FileManager.default.startDownloadingUbiquitousItem(at: url)
                let error:NSErrorPointer = nil
                let coordinator = NSFileCoordinator(filePresenter: nil)
                coordinator.coordinate(readingItemAt: url, options: NSFileCoordinator.ReadingOptions.withoutChanges, error: error) { readURL in
                    downloadedURL = readURL
                }
                if let error = error {
                    print("Can't download the URL: \(error.debugDescription)")
                }
                group.leave()
            }
            catch {
                print("Can't download the URL: \(error.localizedDescription)")
                group.leave()
            }
        }
        
        group.notify(queue: queue, execute: {
            completion(downloadedURL)
        })
    }
    else {
        completion(nil)
    }
}

func copyURL(_ url: URL, completion: @escaping (URL?) -> ()) {
    
    let filename = url.lastPathComponent
    
    if let copiedURL = FileManager.documentsURL(filename: "\(filename)", subdirectoryName: nil) {
        
        try? FileManager.default.removeItem(at: copiedURL)
        
        do {
            try FileManager.default.copyItem(at: url, to: copiedURL)
            completion(copiedURL)
        }
        catch {
            tryDownloadingUbiquitousItem(url) { downloadedURL in
                
                if let downloadedURL = downloadedURL {
                    do {
                        try FileManager.default.copyItem(at: downloadedURL, to: copiedURL)
                        completion(copiedURL)
                    }
                    catch {
                        completion(nil)
                    }
                }
                else {
                    completion(nil)
                }
            }
        }
    }
    else {
        completion(nil)
    }
}

func decodeTerms(from url:URL, completion: @escaping ([Term]?) -> ()) {
    
    var decodedTerms:[Term]?
    
    let scoped = url.startAccessingSecurityScopedResource()
    
    copyURL(url) { copiedURL in
        
        if scoped { 
            url.stopAccessingSecurityScopedResource() 
        }
        
        DispatchQueue.main.async {
            if let copiedURL = copiedURL {
                var jsonData:Data?
                
                do {
                    jsonData = try Data(contentsOf: copiedURL)
                    if let jsonData = jsonData {
                        decodedTerms = try JSONDecoder().decode([Term].self, from: jsonData)
                    }
                } catch {
                    if jsonData == nil {
                        print("Can't read contents of \(copiedURL)")
                    }
                    else {
                        if decodedTerms == nil {
                            print("Can't decode contents of \(copiedURL)")
                        }
                    }
                }
            }
            
            completion(decodedTerms)
        }
    }
}

func highestAbsoluteFrequencyComponent(terms: [Term]) -> Int {
    var highestAbsoluteValue = 1
    
    for term in terms {
        let absoluteValue = abs(term.frequencyComponent)
        if absoluteValue > highestAbsoluteValue {
            highestAbsoluteValue = absoluteValue
        }
    }
    
    return highestAbsoluteValue
}

func AvailableFrequencyComponents(_ terms:[Term]) -> [Int] {
        // Filter out frequency components already present in terms array
    let existingComponents = Set(terms.map { $0.frequencyComponent })
    let availableComponents = Array(-20...20).filter { !existingComponents.contains($0) }
    return availableComponents.filter { $0 != 0 }
}

func sampleTerms(sampleCount:Int, terms:[Term]) -> [CGPoint] {
    
    if terms.count == 0 {
        return []
    }
    
    var points:[CGPoint] = [CGPoint](repeating: .zero, count: sampleCount)
    
    let step = (2 * .pi) / Double(sampleCount-1)
    
    for i in 0...sampleCount-1 {
        let t = Double(i) * step - .pi
        var sum:(Double,Double) = (0,0)
        for term in terms {
            var An:(Double,Double)
            An = (term.amplitude * cos(term.phase), term.amplitude * sin(term.phase)) 
            let eint = e(t, Double(term.frequencyComponent))
            sum = complexAdd(sum, complexMultiply(An, eint))  
        }
        
        points[i] = CGPoint(x: sum.0, y: sum.1) 
    }
    
    return points
}

// mapping frequencyComponents to index in the array of Fourier series terms
func fourierSeriesIndexForTerm(term:Term, nbrFourierSeriesTerms:Int) -> Int? {

    let n = term.frequencyComponent // current term frequency component 
    if n != 0 { // 0 is constant term, skip it
        /*
         Map n to i, N = nbrFourierSeriesTerms:
         
         n = 1, -1,  2, -2,  3, -3, ...,    N, -N
         i = 1,  2,  3,  4,  5,  6, ..., 2N-1, 2N
         */
        let i = (n < 0 ? -2 * n : 2 * n - 1)
        let k = i-1 // epicyclesCirclesPaths 0..2N-1
        if k >= 0 && k < nbrFourierSeriesTerms { // range check, user can change nbrFourierSeriesTerms
            return k
        }
    }
    
    return nil
}

extension View {
    
    func frameStyle() -> some View {
        self.padding(2)
            .border(.gray)
            .background(.white)
    }
}

struct FourierSeriesTermView: View {
    @Binding var terms: [Term]
    
    @Binding var term: Term
    var onRemove: () -> Void = {}
    var onAdd: () -> Void = {}
    
    @State var selectedFrequencyComponent: Int = 0
    
    var availableFrequencyComponents: [Int] {
        return AvailableFrequencyComponents(terms)
    }
        
    var colorRemoveAddView: some View {
        HStack {
            ColorPicker("", selection: $term.color)
                .frame(width: 60, height: 30)
                
            Button(action: onRemove) {
                Image(systemName: "minus.circle")
                    .foregroundColor(.red)
            }
            .padding()
            
            if availableFrequencyComponents.count > 0 {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.red)
                }
                .padding(.trailing)
            }
            
        }
        .frameStyle()
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("r: \(String(format: "%.2f", term.amplitude))")
                    .frameStyle()
                Slider(value: $term.amplitude, in: -1...1)
                    .frameStyle()
                
                HStack {
                    Text("θ: \(String(format: "%.2f", term.phase))")
                        .frameStyle()
                    Spacer()
                    AngleCircleView(angle: $term.phase, radius: 10)
                }
                Slider(value: $term.phase, in: 0...(2 * .pi))
                    .frameStyle()
            }
            
            VStack(alignment: .leading) {
                Text("n: \(term.frequencyComponent)")
                    .frameStyle()
                
                Menu {
                    ForEach(availableFrequencyComponents, id: \.self) { frequency in
                        Button(action: {
                            selectedFrequencyComponent = frequency
                        }) {
                            Text("\(frequency)")
                        }
                    }
                } label: {
                    Text("Select Frequency")
                        .foregroundColor(.black)
                        .padding(3)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
                .id(UUID())
                
                colorRemoveAddView
                    .frameStyle()
            }
            .onChange(of: selectedFrequencyComponent) { selectedFrequencyComponent in
                term.frequencyComponent = selectedFrequencyComponent
            }
            
        }
        .background(term.color) // Set the background color using term.color
    }
}

struct FourierSeriesTermsView: View {
    @Binding var terms: [Term]
    
    @State private var showFileImporter: Bool = false
    @State private var showFileExporter: Bool = false
    @State var exportURL:URL? = nil
    @State var importURL:URL? = nil
    
        // open url
    @State var showURLLoadingProgress = false
    
    @State var termIndexToRemove:Int?
    
    @State var termsAlertInfo: TermsAlertInfo?
    
    var availableFrequencyComponents: [Int] {
        return AvailableFrequencyComponents(terms)
    }
    
    func handleImportedURL() {
        
        guard let selectedURL = importURL else {
            return
        }
        
        showURLLoadingProgress = true
        decodeTerms(from: selectedURL) { decodedTerms in
            showURLLoadingProgress = false
            if let decodedTerms = decodedTerms {
                terms = decodedTerms
            }
            else {
                termsAlertInfo = TermsAlertInfo(id: .cantImportFile, title: "Import Terms", message: "The file could not be read or decoded.")
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                VStack {
                    Text("Amplitude r, Phase θ, Frequency n")
                        .multilineTextAlignment(.leading)
                    
                    Text("Corresponding circle has selected color.")
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                }
                
                HStack {
                    if terms.count > 0 {
                        Button(action: {
                            exportURL = nil
                            showFileExporter = true 
                        }) {
                            Text("Export…")
                                .foregroundColor(.blue)
                        }
                        .padding(.leading)
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button(action: {
                        showFileImporter = true
                    }) {
                        Text("Import…")
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .buttonStyle(PlainButtonStyle())
                    
                    if terms.count > 0 {
                        Button(action: {
                            termsAlertInfo = TermsAlertInfo(id: .removeAllTerms, title: "Remove All Terms", message: "Are you sure you want to remove all terms?\n\nThis cannot be undone unless you save the current terms first.")
                        }) {
                            Text("Remove All (\(terms.count))…")
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing)
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                }
                
                if terms.count == 0 {
                    VStack {
                        HStack {
                            Button(action: addTerm) {
                                Text("Add Term")
                            }
                            
                            Spacer()
                            Text("No Terms")
                            Spacer()
                            
                            Button(action: addTerms) {
                                Text("Add Terms")
                            }
                        }
                        .padding(EdgeInsets(top: 2, leading: 3, bottom: 2, trailing: 3))

                        
                        Text("Add Random Terms")
                    }
                    
                }
                else {
                    VStack {
                        ForEach(terms.indices, id: \.self) { index in
                            FourierSeriesTermView(terms: $terms, term: $terms[index], onRemove: {
                                termIndexToRemove = index
                                termsAlertInfo = TermsAlertInfo(id: .removeTerm, title: "Remove Term", message: "Are you sure you want to remove term n = \(terms[index].frequencyComponent) ?\n\nThis cannot be undone unless you save the current terms first.")
                            }, onAdd: {
                                addTerm()
                            })
                            .border(Color.gray, width: 1)
                        }
                    }
                }
            }
        }
        .fileExporter(isPresented: $showFileExporter, document: EpicyclesDocument(terms: terms), contentType: .epicyclesDocument, defaultFilename: "Terms.epi") { result in
            if case .success = result {
                do {
                    exportURL = try result.get()
                    termsAlertInfo = TermsAlertInfo(id: .exportTerms, title: "Export Terms", message: "Success!")
                }
                catch {
                    termsAlertInfo = TermsAlertInfo(id: .exportTerms, title: "Export Terms", message: "Oops - something went wrong while exporting.")
                }
            } 
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.epicyclesDocument], allowsMultipleSelection: false) { result in
            do {
                importURL = try result.get().first
                termsAlertInfo = TermsAlertInfo(id: .importTerms, title: "Import Terms", message: "Are you sure you want to replace the current terms?\n\nThis cannot be undone unless you save the current terms first.")
            } catch {
                print(error.localizedDescription)
                termsAlertInfo = TermsAlertInfo(id: .cantImportFile, title: "Import Terms", message: "Oops - something went wrong while importing.")
            }
        }
        .overlay(Group {
            if showURLLoadingProgress {          
                ProgressView("Loading...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(tangerine))
            }
        })
        .alert(item: $termsAlertInfo, content: { termsAlertInfo in
            switch termsAlertInfo.id {
                case .cantImportFile:
                    return Alert(title: Text(termsAlertInfo.title),
                                 message: Text(termsAlertInfo.message),
                                 dismissButton: .default(Text("OK")))
                    
                case .importTerms:
                    return Alert(title: Text(termsAlertInfo.title),
                                 message: Text(termsAlertInfo.message),
                                 primaryButton: .destructive(Text("Yes")) {
                        handleImportedURL()
                    }, secondaryButton: .cancel())
                    
                case .exportTerms:
                    return Alert(title: Text(termsAlertInfo.title),
                                 message: Text(termsAlertInfo.message),
                                 dismissButton: .default(Text("OK")))
                    
                case .removeTerm:
                    return Alert(title: Text(termsAlertInfo.title),
                                 message: Text(termsAlertInfo.message),
                                 primaryButton: .destructive(
                                    Text("Yes"),
                                    action: {
                                        if let indexToRemove = termIndexToRemove {
                                            removeTerm(at: indexToRemove)
                                            termIndexToRemove = nil
                                        }
                                    }
                                 ),
                                 secondaryButton: .cancel())
                    
                case .removeAllTerms:
                    return Alert(title: Text(termsAlertInfo.title),
                                 message: Text(termsAlertInfo.message),
                                 primaryButton: .destructive(
                                    Text("Yes"),
                                    action: {
                                        removeAllTerms()
                                    }
                                 ),
                                 secondaryButton: .cancel())
                    
            }
        })


    }
    
    private func addTerm() {
        if availableFrequencyComponents.count > 0 {
            var term = Term()
            
                // set properties to random values
            term.amplitude = Double.random(in: 0.0...1.0)
            term.phase = Double.random(in: 0.0...1.0)
            
            if let randomFrequency = availableFrequencyComponents.randomElement() {
                term.frequencyComponent = randomFrequency
            }
            
            let red = Double.random(in: 0.5...1.0)
            let green = Double.random(in: 0.5...1.0)
            let blue = Double.random(in: 0.5...1.0)
            term.color = Color(red: red, green: green, blue: blue)
            
            terms.append(term)
        }
        
    }
    
    private func addTerms() {
        let n = Int.random(in: 2...7)
        for _ in 0..<n {
            addTerm()
        }
    }
    
    private func removeTerm(at index: Int) {
        terms.remove(at: index)
    }
    
    private func removeLastTerm() {
        if terms.count > 0 {
            terms.removeLast()
        }
    }
    
    private func removeAllTerms() {
        terms.removeAll()
    }
}

struct FourierSeriesTermsWrapperView: View {
    @State var terms:[Term] = kDefaultTerms

    var body: some View {
        FourierSeriesTermsView(terms: $terms)
    }
}

struct FourierSeriesTermsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FourierSeriesTermsWrapperView()
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}

struct FourierSeriesTermWrapperView: View {
    @State var terms:[Term] = kDefaultTerms
    @State private var term: Term = Term(amplitude: 0.5, phase: 0, frequencyComponent: 1)
    
    var body: some View {
        FourierSeriesTermView(terms: $terms, term: $term)
            .border(.red)
    }
}

struct FourierSeriesTermView_Previews: PreviewProvider {
    static var previews: some View {
        FourierSeriesTermWrapperView()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
