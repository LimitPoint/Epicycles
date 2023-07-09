//
//  DialogView.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/16/23.
//

import SwiftUI

enum MediaSize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    
    var description: String {
        switch self {
            case .small:
                return "480 x 480"
            case .medium:
                return "720 x 720"
            case .large:
                return "1080 x 1080"
        }
    }
}

enum MediaType: String, CaseIterable {
    case png = "PNG"
    case gif = "GIF"
    
    var description: String {
        switch self {
            case .png:
                return "Snapshot at the current time."
            case .gif:
                return "Animation composed of equally spaced snapshots in time."
        }
    }
}

enum GIFDuration: Int, CaseIterable, Identifiable {
    case one = 2
    case three = 3
    case five = 5
    case seven = 7
    case eleven = 11
    
    var id: Int { rawValue }
    
    var displayName: String {
        "\(rawValue) sec"
    }
}

enum GIFFrameRate: Int, CaseIterable, Identifiable {
    case twentyFour = 24
    case thirty = 30
    case sixty = 60
    
    var id: Int { rawValue }
    
    var displayName: String {
        "\(rawValue) fps"
    }
}

let kDefaultMediaType = MediaType.gif
let kDefaultMediaSize = MediaSize.medium
let kDefaultGIFDuration = GIFDuration.seven
let kDefaultGIFFrameRate = GIFFrameRate.twentyFour

struct DialogView: View {
    
    @Binding var selectedMediaType: MediaType
    @Binding var selectedMediaSize: MediaSize
    
    @Binding var selectedGIFDuration: GIFDuration
    @Binding var selectedGIFFrameRate: GIFFrameRate
    
    @Binding var whiteBackground: Bool
    
    let saveAction: () -> Void
    let cancelAction: () -> Void
    
    var body: some View {
        VStack {
            Text("Save to Photos")
                .font(.title)
                .padding()
            
            Text("Reduce N for faster processing.")
            
            VStack {
                Picker(selection: $selectedMediaType, label: Text("Type")) {
                    Text(MediaType.gif.rawValue).tag(MediaType.gif)
                    Text(MediaType.png.rawValue).tag(MediaType.png)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Text(selectedMediaType.description)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
            }
            
            if selectedMediaType == .gif {
                
                Text("Select frame rate and duration:")
                
                HStack {
                    
                    Menu(selectedGIFDuration.displayName) {
                        ForEach(GIFDuration.allCases) { duration in
                            Button(action: {
                                selectedGIFDuration = duration
                            }) {
                                Text(duration.displayName)
                            }
                        }
                    }
                    .foregroundColor(.blue)
                    
                    Text("@")
                    
                    Menu(selectedGIFFrameRate.displayName) {
                        ForEach(GIFFrameRate.allCases) { frameRate in
                            Button(action: {
                                selectedGIFFrameRate = frameRate
                            }) {
                                Text(frameRate.displayName)
                            }
                        }
                    }
                    .foregroundColor(.blue)
                    
                }
            }
            
            VStack {
                Picker(selection: $selectedMediaSize, label: Text("Size")) {
                    Text(MediaSize.small.rawValue).tag(MediaSize.small)
                    Text(MediaSize.medium.rawValue).tag(MediaSize.medium)
                    Text(MediaSize.large.rawValue).tag(MediaSize.large)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Text(selectedMediaSize.description)
                    .lineLimit(nil) 
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
            }
            
            
            Toggle("White Background", isOn: $whiteBackground)
        
            HStack {
                
                Button(action: {
                    selectedMediaType = kDefaultMediaType
                    selectedMediaSize = kDefaultMediaSize
                    selectedGIFDuration = kDefaultGIFDuration
                    selectedGIFFrameRate = kDefaultGIFFrameRate
                }) {
                    Text("Reset")
                        .padding()
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: saveAction) {
                    Text("Save")
                        .padding()
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: cancelAction) {
                    Text("Cancel")
                        .padding()
                        .foregroundColor(.red)
                        
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
        .animation(.easeInOut(duration: 0.5), value: selectedMediaType)
        .onChange(of: selectedMediaType, perform: { newValue in
            selectedMediaSize = .medium
        })
        .frame(width:300)
    }
}

struct DialogViewExampleView: View {
    @State var selectedMediaSize = MediaSize.medium
    @State var selectedMediaType = MediaType.gif
    
    @State var selectedGIFDuration = GIFDuration.seven
    @State var selectedGIFFrameRate = GIFFrameRate.twentyFour
    
    @State var whiteBackground = true
    
    var body: some View {
        VStack {
            DialogView(selectedMediaType: $selectedMediaType, selectedMediaSize: $selectedMediaSize, selectedGIFDuration: $selectedGIFDuration, selectedGIFFrameRate: $selectedGIFFrameRate, whiteBackground: $whiteBackground, saveAction: {},
                       cancelAction: {})
        }
    }
}

struct DialogView_Previews: PreviewProvider {
    static var previews: some View {
        DialogViewExampleView()
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

