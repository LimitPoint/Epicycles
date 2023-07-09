//
//  ProgressOverlayView.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/15/23.
//

import SwiftUI

struct ProgressOverlayView: View {
    let progress: Double
    let progressImage: CGImage?
    let title: String
    let subTitle: String?
    
    @Binding var gifGeneratorCancelled:Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.90)
                .cornerRadius(10)
                .shadow(radius: 10)
    
            VStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                if let subTitle = subTitle {
                    Text(subTitle)
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                if let progressImage = progressImage {
                    ZStack {
                        Rectangle()
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        
                        Image(decorative: progressImage, scale: 1.0, orientation: .up)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(8)
                    }
                    .frame(height: 100)
                }
                
                ProgressBar(progress: progress)
                    .frame(height: 8)
                    .padding(.horizontal, 20)
                
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                Button(action: {
                    gifGeneratorCancelled = true
                }) {
                    Text("Cancel")
                }
                .padding()
                .foregroundColor(.red)
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
        .frame(width: 200, height: 100)
    }
}

struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.3))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                Rectangle()
                    .foregroundColor(Color.blue)
                    .frame(width: geometry.size.width * CGFloat(progress), height: geometry.size.height)
            }
        }
    }
}
