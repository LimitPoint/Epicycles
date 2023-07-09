//
//  Curves.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 6/10/23.
//

import Foundation

struct Curve: Hashable, Identifiable {
    let id = UUID()
    let name: String
}

let curves: [Curve] = [
    Curve(name: "✧"),
    Curve(name: "W"),
    Curve(name: "8"),
    Curve(name: "V"),
    Curve(name: "♡"),
    Curve(name: "∿"),
    Curve(name: "□"),
    Curve(name: "△"),
    Curve(name: "꩜"),
    Curve(name: "?"),
]

// Some from https://elepa.files.wordpress.com/2013/11/fifty-famous-curves.pdf
func curveLookup(curve:Curve) -> (((Double)->Double), ((Double)->Double)) {
    var x:((Double)->Double)
    var y:((Double)->Double)
    
    let curveIndex = curves.firstIndex(of: curve)!+1
    
    switch curveIndex {
        case 1: // Astroid 7
            x = { t in pow(cos(t),7) }
            y = { t in pow(sin(t),7) }
        case 2: // Wave
            x = { t in pow(3 * t,2) }
            y = { t in 15 * t * cos(4 * t) }
        case 3: // Loop
            x = { t in t * t * sin(t) * cos(t) }
            y = { t in t * cos(t/2) }
        case 4: // V
            x = { t in pow(t,3)}
            y = { t in pow(2 * t,2)}
        case 5: // Heart
            x = { t in 16 * pow(sin(t),3) }
            y = { t in 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t) }
        case 6: // sine
            x = { t in t }
            y = { t in wavefunction(t + .pi, 1.0 / (.pi), .pi / 2, 0, .sine) }
        case 7: // square
            x = { t in t }
            y = { t in wavefunction(t + .pi, 1.0 / (.pi), .pi / 2, 0, .square) }
        case 8: // triangle
            x = { t in t }
            y = { t in wavefunction(t + .pi, 1.0 / (.pi), .pi / 2, 0, .triangle) }
        case 9: // Archimedean spiral
            x = { t in (t + .pi) * cos(3 * (t + .pi)) }
            y = { t in (t + .pi) * sin(3 * (t + .pi)) }
        default: // circle
            x = { t in cos(t) }
            y = { t in sin(t) }
    }
    
    return (x,y)
}
