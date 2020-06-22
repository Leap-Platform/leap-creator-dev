//
//  JinyMainButton.swift
//  JinySDK
//
//  Created by Aravind GS on 12/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class JinyMainButton: UIButton {
    
    init(withThemeColor:UIColor) {
        super.init(frame: .zero)
        self.setImage(UIImage.getImageFromBundle("jiny_icon"), for: .normal)
        self.imageView?.contentMode = .scaleAspectFit
        self.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        self.backgroundColor = withThemeColor
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer.cornerRadius = 28
        self.layer.masksToBounds = true
        let heightConst = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant:56)
        let aspectConst = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([heightConst, aspectConst])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
