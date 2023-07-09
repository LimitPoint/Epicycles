//
//  Component.swift
//  TonePlayer
//
//  Created by Joseph Pagliaro on 2/12/23.
//

import Foundation
import SwiftUI

    // Note : wavefunctions should have values <= 1.0, otherwise they are clipped in sample generation
    // Partial sum value of the fourier series can exceed 1
enum WaveFunctionType: String, Codable, CaseIterable, Identifiable {
    case sine = "Sine"
    case square = "Square"
    case squareFourier = "Square Fourier"
    case triangle = "Triangle"
    case triangleFourier = "Triangle Fourier"
    case sawtooth = "Sawtooth"
    case sawtoothFourier = "Sawtooth Fourier"
    var id: Self { self }
}

func sine(_ t:Double) -> Double {
    return sin(2 * .pi * t)
}

func square(_ t:Double) -> Double {
    if t < 0.5 {
        return 1
    }
    return -1
}

func triangle(_ t:Double) -> Double {
    if t < 0.25 {
        return 4 * t
    }
    else if t >= 0.25 && t < 0.75 {
        return -4 * t + 2
    }
    return 4 * t - 4
}

func sawtooth(_ t:Double) -> Double {
    return t 
}

func square_fourier_series(_ t:Double, _ n:Int) -> Double {
    
    var sum = 0.0
    
    for i in stride(from: 1, through: n * 2, by: 2) {
        let a = Double(i)
        sum += ((1.0 / a) * sin(2 * a * .pi * t))
    }
    
    return (4.0 / .pi) * sum
}

func triangle_fourier_series(_ t:Double, _ n:Int) -> Double {
    
    var sum = 0.0
    
    for i in stride(from: 1, through: n, by: 2) {
        let a = Double(i)
        sum += ((pow(-1,(a-1)/2) / pow(a, 2.0)) * sin(2 * a * .pi * t))
    }
    
    return (8.0 / pow(.pi, 2.0)) * sum
}

func sawtooth_fourier_series(_ t:Double, _ n:Int) -> Double {
    
    var sum = 0.0
    
    for i in 1...n {
        sum += sin(Double(i) * 2.0 * .pi * t) / Double(i)
    }
    
    return 0.5 + (-1.0 / .pi) * sum
}

func unitFunction( _ type: WaveFunctionType) -> ((Double)->Double) {
    
    let fourierSeriesTermCount = 3
    
    switch type {
        case .sine:
            return sine(_:)
        case .square:
            return square(_:)
        case .triangle:
            return triangle(_:)
        case .sawtooth:
            return sawtooth(_:)
        case .squareFourier:
            return { t in square_fourier_series(t, fourierSeriesTermCount) }
        case .triangleFourier:
            return { t in triangle_fourier_series(t, fourierSeriesTermCount) }
        case .sawtoothFourier:
            return { t in sawtooth_fourier_series(t, fourierSeriesTermCount) }
    }
}

func wavefunction(_ t:Double, _ frequency:Double, _ amplitude:Double, _ offset:Double, _ type: WaveFunctionType) -> Double {
    
    let x = frequency * t + offset
    
    let p = x.truncatingRemainder(dividingBy: 1)
    
    return amplitude * unitFunction(type)(p)
}

struct Component {
    var type:WaveFunctionType
    
    var frequency:Double
    var amplitude:Double
    var offset:Double
    
    func value(x:Double) -> Double {
        return wavefunction(x, frequency, amplitude, offset, type)
    }
}
