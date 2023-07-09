//
//  FourierSeries.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/10/23.
//

import Foundation
import Accelerate

    // MARK: Fourier Series

func fourierSeriesForCoefficients(sampleCount:Int, An:[(Double, Double)]) -> [CGPoint] { 
    
    let step = (2 * .pi) / Double(sampleCount-1)
    
    let samples = stride(from: 0, through: sampleCount-1, by: 1).map { fourierSeriesEpicyclePoints(Double($0) * step - .pi, An:An).last! } // samples.count = sampleCount  
    
    return samples
    
}

func fourierSeriesEpicyclePoints(_ t:Double, An:[(Double, Double)]) -> [CGPoint] {
    
    let terms = fourierSeriesTerms(t, An: An)
    
    var points:[CGPoint] = [CGPoint](repeating: .zero, count: terms.count)
    
    var sum = terms[0]
    points[0] = CGPoint(x: sum.0, y: sum.1)
    
    for i in 1...terms.count-1 {
        sum = complexAdd(sum, terms[i])
        points[i] = CGPoint(x: sum.0, y: sum.1) 
    }
    
    return points
}

func fourierCoefficientsForPoints(nbrFourierSeriesTerms:Int, points:[CGPoint]) -> [(Double, Double)] {
    
    let x = points.map { p in
        Double(p.x)
    }
    
    let y = points.map { p in
        Double(p.y)
    }
    
    return fourierCoeffients_xy(N: nbrFourierSeriesTerms, x: x, y: y)
}

/*
 The following two `fourierSeries` functions are not actually used in the implementation. 
 
 The function `CreatePaths` instead uses the following functions:
 
 fourierSeriesForCoefficients
 fourierSeriesEpicyclePoints
 fourierCoefficientsForPoints
 */
func fourierSeries(_ t:Double, An:[(Double, Double)]) -> CGPoint {
    return fourierSeries(terms: fourierSeriesTerms(t, An: An))
}

func fourierSeries(terms:[(Double, Double)]) -> CGPoint {
    
    var sum = terms[0]
    
    for i in 1...terms.count-1 {
        sum = complexAdd(sum, terms[i])
    }
    
    return CGPoint(x: sum.0, y: sum.1)
}

    // 1st term is constant
func fourierSeriesTerms(_ t:Double, An:[(Double, Double)]) -> [(Double, Double)] {
    
    var terms:[(Double, Double)] = []
        // f(t) = Σ An e^(int), -N,N
    let N = (An.count - 1) / 2
    
    var n = 0.0
    terms.append(complexMultiply(An[N] , e(t, n))) // 1st is constant term
    
    for i in 1...N {
        n = Double(i)
        terms.append(complexMultiply(An[i + N] , e(t, n)))
        terms.append(complexMultiply(An[-i + N] , e(t, -n)))
    }
    
    return terms
}

func fourierCoeffients_xy(N:Int, x:[Double], y:[Double]) -> [(Double, Double)] {
    
    var An:[(Double, Double)] = [(Double, Double)](repeating: (0.0, 0.0), count: 2*N+1)
    
    for n in -N...N {
        let fc = fourierCoeffient_xy(n: n, x: x, y: y)
        An[n + N] = (fc.0, fc.1)
    }
    
    return An
}

func fourierCoeffient_xy(n:Int, x:[Double], y:[Double]) -> (Double, Double) {
    var cx:(Double, Double) = (0,0)
    var cy:(Double, Double) = (0,0)
    
        // An = (1/2π) ∫ f(t)e^(-int) dt, [-π,π] 
        // e^(-int) = cos(n t) - i sin(n t)
        //
        // cx(n) = (1/(2π) ∫ x(t) e^(-i n t), [-π,π] 
        // cy(n) = (1/(2π) ∫ y(t) e^(-i n t), [-π,π] 
    
    let sampleCount = x.count
    
    let cosn = cos(n, sampleCount: sampleCount)
    let sinn = sin(n, sampleCount: sampleCount)
    
        // cx(n) = cx.0 + i cx.1
    cx.0 = (1.0/(.pi * 2)) * integrate(samples: vDSP.multiply(x, cosn))
    
    cx.1 = -(1.0/(.pi * 2)) * integrate(samples: vDSP.multiply(x, sinn))
    
        // cy(n) = cy.0 + i cy.1
    cy.0 = (1.0/(.pi * 2)) * integrate(samples: vDSP.multiply(y, cosn))
    
    cy.1 = -(1.0/(.pi * 2)) * integrate(samples: vDSP.multiply(y, sinn))
    
        // return as a complex number tuple
    /*
     (cx.0 + i cx.1) + i (cy.0 + i cy.1)
     = cx.0 + i cx.1 + i cy.0 - cy.1
     = (cx.0 - cy.1) + i (cx.1 + cy.0)
     */
    return (cx.0 - cy.1, cx.1 + cy.0)
}
