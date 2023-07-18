//
//  Constants.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/23/23.
//

import Foundation
import SwiftUI

let kEpicyclesURL = "https://www.limit-point.com/blog/2023/epicycles/"
let kFourierSeriesURL = "https://en.wikipedia.org/wiki/Fourier_series"
let kEulersFormulaURL = "https://en.wikipedia.org/wiki/Euler%27s_formula"
let kEpicycleURL = "https://en.wikipedia.org/wiki/Deferent_and_epicycle"

let kMinimumPointCount = 20

let kMaxFourierSeriesTerms = 100
let kSampleCount = 1000

let tangerine = Color(red: 0.98, green: 0.57, blue: 0.21, opacity:0.9)
let bluePinkColor = Color(red: 230/255, green: 160/255, blue: 200/255)

// Indices:
// 0-curvePath, 1-curveFourierSeriesPath, 2-epicyclesPath, 3-epicyclesCirclesPath, 4-epicyclesPathTerminator
var kLineColor = [Color.orange, Color.black, Color.red, Color.blue, Color.green]
var kLineWidth = [3.0, 1.0, 1.0, 1.0, 1.0]
var kTrailLength = 0.0

let kPathsPadding = 10.0

// OptionsView
let kColorKey = "lineColor"
let kWidthKey = "lineWidth"
let kTrailLengthKey = "trailLength"

enum PathType: String, CaseIterable, Identifiable  {
    case curvePath = "f"
    case curveFourierSeriesPath = "Σ"
    case epicyclesPath = "Radii"
    case epicyclesCirclesPath = "Circles"
    case epicyclesPathTerminator = "f(t)"
    var id: Self { self }
}

var kPathTypeSystemImageNames = ["pencil", "star", "bolt", "circle", "eye.circle"]

func indexForPathType(_ pathType:PathType) -> Int {
    return PathType.allCases.firstIndex(where: { $0 == pathType })!
}

func systemImageForPathType(_ pathType:PathType) -> String {
    return kPathTypeSystemImageNames[indexForPathType(pathType)]
}
