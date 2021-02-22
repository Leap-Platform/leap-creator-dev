//
//  Leap+UIView.swift
//  LeapAUI
//
//  Created by mac on 12/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    /// makes the view look like elevated
    /// - Parameters:
    ///   - elevation: elevation value.
    func elevate(with elevation: CGFloat) {
      layer.masksToBounds = false
      layer.shadowColor = UIColor.black.cgColor
      layer.shadowOffset = CGSize(width: 0, height: elevation)
      layer.shadowOpacity = 0.24
      layer.shadowRadius = CGFloat(elevation)
    }
}
