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
    
}
