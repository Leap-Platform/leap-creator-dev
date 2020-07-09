//
//  JinyDragRect.swift
//  TestFlowSelector
//
//  Created by Aravind GS on 10/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class JinyDragRect: UIView {

    override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 0.89, green: 0.89, blue: 0.89, alpha: 1.00)
        layer.cornerRadius = 3.0
        layer.masksToBounds = true
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


extension JinyDragRect {
    
    func setupView() {
        self.translatesAutoresizingMaskIntoConstraints = false
        let widthConst = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 36)
        let heightConst = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 6)
        NSLayoutConstraint.activate([widthConst, heightConst])
        
        
    }
    
}
