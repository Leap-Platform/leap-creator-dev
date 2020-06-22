//
//  JinyPoweredBy.swift
//  TestFlowSelector
//
//  Created by Aravind GS on 10/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class JinyPoweredBy: UIView {
    
    private lazy var poweredBy:UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleAspectFit
        view.image = UIImage.getImageFromBundle("jiny_powered_by")
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.00)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension JinyPoweredBy {
    
    
    private func setupView() {
        
        let prefHeightConst = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50)
        let minHeightConst = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 36)
        NSLayoutConstraint.activate([prefHeightConst, minHeightConst])
        
        addSubview(poweredBy)
        poweredBy.translatesAutoresizingMaskIntoConstraints = false
        
        let centerXConst = NSLayoutConstraint(item: poweredBy, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 5)
        let centerYConst = NSLayoutConstraint(item: poweredBy, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: -5)
        let height = NSLayoutConstraint(item: poweredBy, attribute: .height, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 18)
        NSLayoutConstraint.activate([centerXConst, centerYConst, height])
        
    }
}
