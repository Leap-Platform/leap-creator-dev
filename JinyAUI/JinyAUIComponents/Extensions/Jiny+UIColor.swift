//
//  Jiny+UIColor.swift
//  JinyDemo
//
//  Created by mac on 08/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit

public extension UIColor {

    /// returns string from UIColor.
    /// - Parameters:
    ///   - color: color of type UIColor.
    class func stringFromUIColor(color: UIColor) -> String {
        
        let components = color.cgColor.components
        
        var result = [CGFloat?]()
        
        result = Array(repeating: nil, count: 4)
        
        // last index is for alpha.
        
        result[result.count-1] = components?.last
        
        for (index, component) in (components ?? []).enumerated() {
            
            if index != ((components?.count ?? 0)-1) {
            
               result[index] = component
            }
        }
        
        return "[\(result[0] ?? 0), \(result[1] ?? 0), \(result[2] ?? 0), \(result[result.count-1] ?? 0.0)]"
    }
    
    /// returns color from color string.
    /// - Parameters:
    ///   - string: string of color.
    class func colorFromString(string: String) -> UIColor {
        
        let componentsString = string.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
        
        let components = componentsString.components(separatedBy: ", ")
        
        var result = [String?]()
        
        result = Array(repeating: nil, count: 4)
        
        for (index, component) in components.enumerated() {
            
            result[index] = component
        }
        
        return UIColor(red: CGFloat(((result[0] ?? "") as NSString).floatValue),
                     green: CGFloat(((result[1] ?? "") as NSString).floatValue),
                      blue: CGFloat(((result[2] ?? "") as NSString).floatValue),
                     alpha: CGFloat(((result[3] ?? "") as NSString).floatValue))
    }
    
    convenience init?(hex: String) {
            let r, g, b, a: CGFloat

            if hex.hasPrefix("#") {
                let start = hex.index(hex.startIndex, offsetBy: 1)
                let hexColor = String(hex[start...])

                if hexColor.count == 8 {
                    let scanner = Scanner(string: hexColor)
                    var hexNumber: UInt64 = 0

                    if scanner.scanHexInt64(&hexNumber) {
                        a = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                        r = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                        g = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                        b = CGFloat(hexNumber & 0x000000ff) / 255

                        self.init(red: r, green: g, blue: b, alpha: a)
                        return
                    }
                }
            }

            return nil
        }
}
