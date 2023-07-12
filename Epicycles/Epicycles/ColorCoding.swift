//
//  ColorCoding.swift
//  Epicycles
//
//  Created by Joseph Pagliaro on 7/11/23.
//

import SwiftUI

func RGBAComponents(from cgColor: CGColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
    if let components = cgColor.components {
        let numberOfComponents = cgColor.numberOfComponents
        
        if numberOfComponents == 1 {
                // Grayscale color (white)
            let white = components[0]
            return (white, white, white, 1.0) // Set alpha to 1.0
        } else if numberOfComponents == 3 {
                // RGB color (no alpha)
            let red = components[0]
            let green = components[1]
            let blue = components[2]
            return (red, green, blue, 1.0) // Set alpha to 1.0
        } else if numberOfComponents == 4 {
                // RGBA color (with alpha)
            let red = components[0]
            let green = components[1]
            let blue = components[2]
            let alpha = components[3]
            return (red, green, blue, alpha)
        }
    }
    
        // Return default values if unable to get color components
    return (0.0, 0.0, 0.0, 1.0)
}

extension Color {
    struct ColorData: Codable {
        let red: Double
        let green: Double
        let blue: Double
        let opacity: Double
    }
    
    func rgbaComponents() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var cgColor:CGColor
        
#if os(macOS)
        cgColor = NSColor(self).cgColor
#else
        cgColor = UIColor(self).cgColor
#endif
        
        return RGBAComponents(from: cgColor)
    }
    
    func encode() -> Data? {
        
        let (red, green, blue, opacity) = self.rgbaComponents()
        
        let colorData = ColorData(red: Double(red),
                                  green: Double(green),
                                  blue: Double(blue),
                                  opacity: Double(opacity))
        
        do {
            return try JSONEncoder().encode(colorData)
        } catch {
            print("Error encoding color:", error)
            return nil
        }
    }
    
    static func decode(data: Data) -> Color? {
        do {
            let colorData = try JSONDecoder().decode(ColorData.self, from: data)
            let color = Color(red: colorData.red,
                              green: colorData.green,
                              blue: colorData.blue,
                              opacity: colorData.opacity)
            return color
        } catch {
            print("Error decoding color:", error)
            return nil
        }
    }
}

func loadColorsFromUserDefaults(forKey key: String) -> [Color]? {
    guard let encodedData = UserDefaults.standard.object(forKey: key) as? Data,
          let colorData = try? JSONDecoder().decode([Data].self, from: encodedData) else {
        return nil
    }
    
    let colors = colorData.compactMap { Color.decode(data: $0) }
    return colors
}

func saveColorsToUserDefaults(colors: [Color]?, forKey key: String) {
    if let colors = colors {
        let colorData = colors.map { $0.encode() }
        let encodedData = try? JSONEncoder().encode(colorData)
        UserDefaults.standard.set(encodedData, forKey: key)
    } else {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

