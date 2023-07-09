//
//  CornerSnappingView
//
//  Created by Alex Pagliaro on 1/2/2021.
//
import SwiftUI

struct CornerSnappingView<ContentView: View, SnappingView: View>: View {
    
    let contentView: ContentView
    let snappingView: SnappingView
    
    init(@ViewBuilder contentView: @escaping () -> ContentView, @ViewBuilder snappingView: @escaping () -> SnappingView) {
        self.contentView = contentView()
        self.snappingView = snappingView()
    }
    
    @State var alignment: Alignment = .bottomLeading
    @GestureState var dragAmount: CGSize = .zero
    @State var snappingViewFrame: CGRect = .zero
    
    let coordinateSpace = CoordinateSpace.named("ZStack")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: alignment) {
                contentView
                snappingView
                    .padding()
                    .offset(dragAmount)
                    .animation(.spring(response: 0.4, dampingFraction: 0.9, blendDuration: 0), value: dragAmount)
                    .currentFrameReader(currentFrame: $snappingViewFrame, coordinateSpace: coordinateSpace)
                    .gesture(
                        DragGesture(coordinateSpace: coordinateSpace)
                            .updating($dragAmount) { value, state, transaction in
                                // prevent the snapping view from leaving bounds of parent
                                // adjust the current frame by the current drag translation
                                var snappingViewFrameOffset = snappingViewFrame
                                snappingViewFrameOffset.origin.x = snappingViewFrame.origin.x + value.translation.width
                                snappingViewFrameOffset.origin.y = snappingViewFrame.origin.y + value.translation.height
                                // only allow updating state if frame is within bounds of parent
                                var updatedTranslation = state
                                if snappingViewFrameOffset.maxX < geometry.size.width,
                                   snappingViewFrameOffset.minX > 0 {
                                    updatedTranslation.width = value.translation.width
                                }
                                if snappingViewFrameOffset.maxY < geometry.size.height,
                                   snappingViewFrameOffset.minY > 0 {
                                    updatedTranslation.height = value.translation.height
                                }
                                state = updatedTranslation
                            }
                            .onEnded({ (value) in
                                // check which quadrant the midpoint of the frame is located
                                // adjust the current frame by the final drag translation
                                var snappingViewFrameOffset = snappingViewFrame
                                // use the predicted end translation for more natural feeling transition
                                let translation = value.predictedEndTranslation
                                snappingViewFrameOffset.origin.x = snappingViewFrame.origin.x + translation.width
                                snappingViewFrameOffset.origin.y = snappingViewFrame.origin.y + translation.height
                                // update state depending on which quadrant the midpoint is
                                switch (snappingViewFrameOffset.midX, snappingViewFrameOffset.midY) {
                                    case (let x, let y) where x < geometry.size.width / 2 && y < geometry.size.height / 2 :
                                        alignment = .topLeading
                                    case (let x, let y) where x >= geometry.size.width / 2 && y < geometry.size.height / 2:
                                        alignment = .topTrailing
                                    case (let x, let y) where x >= geometry.size.width / 2 && y >= geometry.size.height / 2:
                                        alignment = .bottomTrailing
                                    default:
                                        alignment = .bottomLeading
                                }
                            })
                    )
            }
            .coordinateSpace(name: "ZStack")
        }
    }
}

struct CornerSnappingViewModifier<SnappingView: View>: ViewModifier {
    
    let snappingView: SnappingView
    
    init(@ViewBuilder snappingView: @escaping () -> SnappingView) {
        self.snappingView = snappingView()
    }
    
    func body(content: Content) -> some View {
        
        CornerSnappingView { 
            content
        } snappingView: { 
            snappingView
        }   
    }
}

extension View {
    func cornerSnappingView<SnappingView: View>(_ content: SnappingView) -> some View {
        return self.modifier(CornerSnappingViewModifier(snappingView: {
            content
        }))
    }
}

struct CornerSnappingView_Previews: PreviewProvider {
    static var previews: some View {
        CornerSnappingView { 
            Rectangle().foregroundColor(.clear).border(Color.yellow, width: 5)
            
        } snappingView: { 
            Circle().foregroundColor(.red).frame(width: 100, height: 100, alignment: .center)
        }
    }
}
