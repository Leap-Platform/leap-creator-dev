//
//  LeapLayer.swift
//  LeapAUI
//
//  Created by mac on 05/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

class LeapLayer: CALayer {
    
    /// draws a line based on the start and end points.
    /// - Parameters:
    ///   - start: startPoint of the line.
    ///   - end: endPoint of the line.
    ///   - color: color of the line layer.
    func addSolidLine(fromPoint start: CGPoint, toPoint end: CGPoint, withColor color: CGColor) {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        line.path = linePath.cgPath
        line.strokeColor = color
        line.lineWidth = 1
        self.addSublayer(line)
    }
    
    /// draws a line based on the start and end points with a circle at the end.
    /// - Parameters:
    ///   - start: startPoint of the line.
    ///   - end: endPoint of the line.
    ///   - color: color of the line layer.
    func addSolidLineWithCircle(fromPoint start: CGPoint, toPoint end: CGPoint, withColor color: CGColor, withCircleRadius radius: CGFloat) {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: start)
        
        var lineY: CGFloat = 0

        var circleY: CGFloat = 0
        
        let radius: CGFloat = radius
        
        if start.y > end.y {
            
            lineY = end.y + radius
            
            circleY = end.y
        
        } else {
            
            lineY = end.y - radius
            
            circleY = lineY
        }
        
        linePath.addLine(to: CGPoint(x: end.x, y: lineY))
        line.path = linePath.cgPath
        line.strokeColor = color
        line.lineWidth = 1
        self.addSublayer(line)
        
        // circle layer
        let circle = CAShapeLayer()
        let circlePath = UIBezierPath(ovalIn: CGRect(x: end.x - (radius/2), y: circleY, width: radius, height: radius))
        circle.path = circlePath.cgPath
        circle.fillColor = color
        self.addSublayer(circle)
    }
    
    /// draws a dashed line based on the start and end points.
    /// - Parameters:
    ///   - start: startPoint of the line.
    ///   - end: endPoint of the line.
    ///   - color: color of the line layer.
    func addDashedLine(fromPoint start: CGPoint, toPoint end:CGPoint, withColor color: CGColor) {
        let line = CAShapeLayer()
        line.lineDashPattern = [2, 2]
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        line.path = linePath.cgPath
        line.strokeColor = color
        line.lineWidth = 1
        self.addSublayer(line)
    }
    
    /// draws a dashed line based on the start and end points with a circle at the end.
    /// - Parameters:
    ///   - start: startPoint of the line.
    ///   - end: endPoint of the line.
    ///   - color: color of the line layer.
    func addDashedLineWithCircle(fromPoint start: CGPoint, toPoint end:CGPoint, withColor color: CGColor, withCircleRadius radius: CGFloat) {
        let line = CAShapeLayer()
        line.lineDashPattern = [2, 2]
        let linePath = UIBezierPath()
        linePath.move(to: start)
        
        var lineY: CGFloat = 0

        var circleY: CGFloat = 0
        
        let radius: CGFloat = radius
        
        if start.y > end.y {
            
            lineY = end.y + radius
            
            circleY = end.y
        
        } else {
            
            lineY = end.y - radius
            
            circleY = lineY
        }
        
        linePath.addLine(to: CGPoint(x: end.x, y: lineY))
        line.path = linePath.cgPath
        line.strokeColor = color
        line.lineWidth = 1
        self.addSublayer(line)
        
        // circle layer
        let circle = CAShapeLayer()
        let circlePath = UIBezierPath(ovalIn: CGRect(x: end.x - (radius/2), y: circleY, width: radius, height: radius))
        circle.path = circlePath.cgPath
        circle.fillColor = color
        self.addSublayer(circle)
    }
}
