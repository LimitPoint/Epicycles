//
//  CurrentFrameReader.swift
//  ImagePicker
//
//  Created by Alexander Pagliaro on 1/22/21.
//

import Foundation
import SwiftUI

struct CurrentSizeReader: ViewModifier {
    @Binding var currentSize: CGSize
    @State var lastSize:CGSize = .zero // prevents too much view updating if value is stored in a published property of a View's observable object. 
    
    var geometryReader: some View {
        GeometryReader { proxy in
            Color.clear
                .execute {
                    if lastSize != proxy.size {
                        currentSize = proxy.size
                        lastSize = currentSize
                    }
                }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .background(geometryReader)
    }
}

struct CurrentFrameReader: ViewModifier {
    @Binding var currentFrame: CGRect
    
    var coordinateSpace:CoordinateSpace
    
    var geometryReader: some View {
        GeometryReader { proxy in
            Color.clear
                .execute {
                    currentFrame = proxy.frame(in: coordinateSpace)
                }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .background(geometryReader)
    }
}

extension View {
    func execute(_ closure: @escaping () -> Void) -> Self {
        DispatchQueue.main.async {
            closure()
        }
        return self
    }
    
    func currentSizeReader(currentSize: Binding<CGSize>) -> some View {
        modifier(CurrentSizeReader(currentSize: currentSize))
    }
    
    func currentFrameReader(currentFrame: Binding<CGRect>, coordinateSpace:CoordinateSpace) -> some View {
        modifier(CurrentFrameReader(currentFrame: currentFrame, coordinateSpace: coordinateSpace))
    }
}
