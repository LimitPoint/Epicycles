//
//  SplashScreenView.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/27/23.
//

import SwiftUI

#if os(macOS)
import Quartz

struct QLImage: NSViewRepresentable {
    
    private let name: String
    
    init(_ name: String) {
        self.name = name
    }
    
    func makeNSView(context: NSViewRepresentableContext<QLImage>) -> QLPreviewView {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif")
        else {
            let _ = print("Cannot get image \(name)")
            return QLPreviewView()
        }
        
        let preview = QLPreviewView(frame: .zero, style: .normal)
        preview?.autostarts = true
        preview?.previewItem = url as QLPreviewItem
        
        return preview ?? QLPreviewView()
    }
    
    func updateNSView(_ nsView: QLPreviewView, context: NSViewRepresentableContext<QLImage>) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif")
        else {
            let _ = print("Cannot get image \(name)")
            return
        }
        nsView.previewItem = url as QLPreviewItem
    }
    
    typealias NSViewType = QLPreviewView
}

#else 
import QuickLook

struct QuickLookPreview: UIViewControllerRepresentable {
    let gifFilename: String
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<QuickLookPreview>) -> QLPreviewController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        return previewController
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: UIViewControllerRepresentableContext<QuickLookPreview>) {
        uiViewController.reloadData()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(gifFilename: gifFilename)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let gifFilename: String
        
        init(gifFilename: String) {
            self.gifFilename = gifFilename
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            let gifURL = Bundle.main.url(forResource: gifFilename, withExtension: "gif")!
            return gifURL as QLPreviewItem
        }
    }
}

#endif

struct SplashScreenView: View {
    @Binding var showSplashScreen: Bool
    
    var body: some View {
        ZStack {
            Color.white
                .cornerRadius(10)
                .shadow(radius: 10)
            
            VStack {
                #if os(macOS)
                QLImage("Animation")
                    .frame(width: 200, height: 200) 
                    .padding()
                #else
                QuickLookPreview(gifFilename: "Animation")
                    .frame(width: 200, height: 200) 
                    .padding()
                #endif
                
                Text("Experiment with complex valued Fourier series of the form:")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                
                Image("FourierSeriesForm")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 50) 
                    
                Text("Edit custom series in the Terms view.")
                    .multilineTextAlignment(.center)
                    .padding()
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                
                Text("Select item `?` and the Terms tab.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                
                Button("Dismiss") {
                    showSplashScreen = false
                }
                .padding()
                .foregroundColor(.red)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(width: 300, height: 400)
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView(showSplashScreen: .constant(true))
    }
}
