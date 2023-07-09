//
//  Math.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/10/23.
//

import Foundation
import Accelerate

    // Sampling on [-π,π] 
func sample(sampleCount:Int, f: (Double)->Double) -> [Double] {
    let step = (2 * .pi) / Double(sampleCount-1)
    let samples = stride(from: 0, through: sampleCount-1, by: 1).map { f(Double($0) * step - .pi) } // samples.count = sampleCount
    return samples
}

    // Sampling on [-π,π] 
func sampleCurve(sampleCount:Int, x: (Double)->Double, y: (Double)->Double) -> [CGPoint] {
    let step = (2 * .pi) / Double(sampleCount-1)
    let samples = stride(from: 0, through: sampleCount-1, by: 1).map { CGPoint(x: x(Double($0) * step - .pi), y: y(Double($0) * step - .pi)) } // samples.count = sampleCount
    return samples
}

func complexMultiply(_ a:(Double,Double), _ b:(Double,Double)) -> (Double,Double) {
        //  (x   + y   i)(u   + v   i) = (x   u   - y   v  ) + (x   v   + y   u  )i
        //  (a.0 + a.1 i)(b.0 + b.1 i) = (a.0 b.0 - a.1 b.1) + (a.0 b.1 + a.1 b.0)i
    
    return (a.0 * b.0 - a.1 * b.1 , a.0 * b.1 + a.1 * b.0)
}

func complexAdd(_ a:(Double,Double), _ b:(Double,Double)) -> (Double,Double) {
        //  (x   + y   i)(u   + v   i) = (x   + u  ) + (y   + v  )i
        //  (a.0 + a.1 i)(b.0 + b.1 i) = (a.0 + b.0) + (a.1 + b.1)i
    
    return (a.0 + b.0, a.1 + b.1)
}

func e(_ t:Double, _ n:Double) -> (Double,Double) {
    return (cos(n * t), sin(n * t))
}

func cos(_ n:Int, sampleCount:Int) -> [Double] {
    return sample(sampleCount: sampleCount) { t in
        cos(Double(n) * t)
    }
}

func sin(_ n:Int, sampleCount:Int) -> [Double] {
    return sample(sampleCount: sampleCount) { t in
        sin(Double(n) * t)
    }
}

    // MARK: Integration
func integrate(samples:[Double]) -> Double {
    
    let sampleCount = samples.count
    var step = (2 * .pi) / Double(sampleCount-1)
    
    var result = [Double](repeating: 0.0, count: sampleCount)
    
    vDSP_vsimpsD(samples, 1, &step, &result, 1, vDSP_Length(sampleCount))
    
    return result[sampleCount-1]
}
