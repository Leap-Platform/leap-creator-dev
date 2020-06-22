//
//  JinyOptionButton.swift
//  TestFlowSelector
//
//  Created by Aravind GS on 06/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

@IBDesignable
class JinyOptionPanelButton: UIButton {
    
    var title:String
    var image:UIImage

    private lazy var icon:UIImageView = {
        let imageView = UIImageView(frame: .zero)
        return imageView
    }()
    
    private lazy var text:UILabel = {
        let label = UILabel()
        return label
    }()
    
    init(_icon:UIImage, _text:String) {
        title = _text
        image = _icon
        super.init(frame: .zero)
        setupOptionButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension JinyOptionPanelButton {
    
    private func setupOptionButton() {
        setupImage()
        setupTitle()
        let maxWidthConst = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 65)
        NSLayoutConstraint.activate([maxWidthConst])
    }
    
    private func setupImage() {
        icon.image = image
        icon.contentMode = .scaleAspectFit
        addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        let xCenterConst = NSLayoutConstraint(item: icon, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: icon, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 2)
        let leadingConst = NSLayoutConstraint(item: icon, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 5)
        let heightConst = NSLayoutConstraint(item: icon, attribute: .height, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 23)
        NSLayoutConstraint.activate([xCenterConst, leadingConst, topConst, heightConst])
    }
    
    private func setupTitle() {
        addSubview(text)
        text.text = title
        text.textColor = UIColor(red: 0.36, green: 0.36, blue: 0.36, alpha: 1.00)
        text.textAlignment = .center
        text.font = UIFont.systemFont(ofSize: 11)
        text.translatesAutoresizingMaskIntoConstraints = false
        
        let xCenterConst = NSLayoutConstraint(item: text, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: text, attribute: .top, relatedBy: .equal, toItem: icon, attribute: .bottom, multiplier: 1, constant: 10)
        let bottomConst = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: text, attribute: .bottom, multiplier: 1, constant: 0)
        let leadingCosnt = NSLayoutConstraint(item: text, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 5)
        NSLayoutConstraint.activate([xCenterConst, topConst, bottomConst, leadingCosnt])
        
    }
    
}
