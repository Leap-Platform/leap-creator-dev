//
//  JinyIconView.swift
//  JinyDemo
//
//  Created by mac on 13/10/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import UIKit

/// JinyIconView which holds a button with Jiny Icon image.
class JinyIconView: UIView {

    /// iconButton of type UIbutton.
    var iconButton = UIButton(frame: .zero)
    
    /// icon's background color.
    var iconBackgroundColor: UIColor = .blue {
        
        didSet {
            
            self.iconButton.backgroundColor = iconBackgroundColor
        }
    }
    
    /// the height and width of the icon.
    let iconSize: CGFloat = 36
    
    /// the gap between icon and it's toView.
    let iconGap: CGFloat = 12
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
        self.configureIconButon()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// sets iconButton's constraints w.r.t self.
    func configureIconButon() {
        
        self.addSubview(iconButton)
        
       // Setting Constraints to iconButton
                
        iconButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraint(NSLayoutConstraint(item: iconButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: iconButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: iconButton, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: iconButton, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0))
        
        // set width and height constraints to JinyIconView
        
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: iconSize))
        
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: iconSize))
        
        self.iconButton.clipsToBounds = true
        self.iconButton.layer.cornerRadius = iconSize/2
        
        self.iconButton.setImage(UIImage.getImageFromBundle("jiny_icon"), for: .normal)
        
        self.iconButton.imageView?.contentMode = .scaleAspectFit
        
        self.iconButton.backgroundColor = iconBackgroundColor
        
        self.iconButton.imageEdgeInsets = UIEdgeInsets(top: 5, left: 7, bottom: 5, right: 7)
    }
}
