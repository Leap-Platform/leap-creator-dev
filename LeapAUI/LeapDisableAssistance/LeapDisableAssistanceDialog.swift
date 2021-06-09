//
//  LeapDisableAssistanceDialog.swift
//  LeapAUI
//
//  Created by Ajay S on 01/02/21.
//  Copyright © 2021 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

protocol LeapDisableAssistanceDelegate: AnyObject {
    
    func didPresentDisableAssistance()
    func shouldDisableAssistance()
    func didDismissDisableAssistance()
}

class LeapDisableAssistanceDialog: UIView {
    
    weak var delegate: LeapDisableAssistanceDelegate?
    
    var bottomDialogView = UIView(frame: .zero)
    
    private lazy var leapIcon: LeapIconView = {
        let leapIconView = LeapIconView()
        leapIconView.htmlUrl = LeapSharedAUI.shared.iconSetting?.htmlUrl
        leapIconView.iconBackgroundColor = UIColor(hex: LeapSharedAUI.shared.iconSetting?.bgColor ?? "#00000000") ?? .black
        return leapIconView
    }()
    
    var dialogLabel = UILabel(frame: .zero)
    
    var dialogButton1 = UIButton(type: .system)
    
    var dialogButton2 = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func showBottomDialog(with dialogText: String = "Do you want to permanently disable the assistance?", dialogText1: String = "No", dialogText2: String = "Yes") {
        
        guard UIApplication.shared.keyWindow != nil else { return }
        
        UIApplication.shared.keyWindow?.addSubview(self)
        
        configureOverlay()
        
        configureBottomDialogView()
        
        configureIconView()
        
        configureDialogLabel()
        dialogLabel.text = dialogText
        
        configureDialogButton1()
        dialogButton1.setTitle(dialogText1, for: .normal)
        
        configureDialogButton2()
        dialogButton2.setTitle(dialogText2, for: .normal)
        
        animateEnterBottomDialog()
    }
    
    func configureOverlay() {
        
        guard let superView = self.superview else {
            
            return
        }
                        
        // Setting Constraints to self
        
        self.translatesAutoresizingMaskIntoConstraints = false

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: superView, attribute: .centerX, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: superView, attribute: .centerY, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: superView, attribute: .width, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: superView, attribute: .height, multiplier: 1, constant: 0))
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        
        //self.elevate(with: CGFloat(assistInfo?.layoutInfo?.style.elevation ?? 0))
    }
    
    func configureBottomDialogView() {
        
        self.addSubview(bottomDialogView)
        
        bottomDialogView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraint(NSLayoutConstraint(item: bottomDialogView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: bottomDialogView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: bottomDialogView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
        
        // Support Constraint
        
        self.addConstraint(NSLayoutConstraint(item: bottomDialogView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 0.33, constant: 0))
        
        bottomDialogView.backgroundColor = .white
        
        if #available(iOS 11.0, *) {
            bottomDialogView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            // Fallback on earlier versions
        }
        
        bottomDialogView.clipsToBounds = true
        
        bottomDialogView.layer.cornerRadius = 20
    }
    
    func configureIconView() {
        
        bottomDialogView.addSubview(leapIcon)
        
        leapIcon.translatesAutoresizingMaskIntoConstraints = false
        
        bottomDialogView.addConstraint(NSLayoutConstraint(item: leapIcon, attribute: .centerX, relatedBy: .equal, toItem: bottomDialogView, attribute: .centerX, multiplier: 1, constant: 0))
        
        bottomDialogView.addConstraint(NSLayoutConstraint(item: leapIcon, attribute: .centerY, relatedBy: .equal, toItem: bottomDialogView, attribute: .centerY, multiplier: 0.4, constant: 0))
        
        leapIcon.iconSize = mainIconSize
        leapIcon.configureIconButton()
    }
    
    func configureDialogLabel() {
        
        bottomDialogView.addSubview(dialogLabel)
        
        dialogLabel.translatesAutoresizingMaskIntoConstraints = false
        
        bottomDialogView.addConstraint(NSLayoutConstraint(item: dialogLabel, attribute: .centerX, relatedBy: .equal, toItem: bottomDialogView, attribute: .centerX, multiplier: 1, constant: 0))
        
        bottomDialogView.addConstraint(NSLayoutConstraint(item: dialogLabel, attribute: .trailing, relatedBy: .equal, toItem: bottomDialogView, attribute: .trailing, multiplier: 1, constant: -30))
        
        bottomDialogView.addConstraint(NSLayoutConstraint(item: dialogLabel, attribute: .leading, relatedBy: .equal, toItem: bottomDialogView, attribute: .leading, multiplier: 1, constant: 30))
        
        bottomDialogView.addConstraint(NSLayoutConstraint(item: dialogLabel, attribute: .centerY, relatedBy: .equal, toItem: bottomDialogView, attribute: .centerY, multiplier: 1, constant: 0))
        
        dialogLabel.numberOfLines = 2
        
        dialogLabel.textAlignment = .center
        
        dialogLabel.textColor = .black
    }
    
    func configureDialogButton1() {
        
        bottomDialogView.addSubview(dialogButton1)
        
        dialogButton1.translatesAutoresizingMaskIntoConstraints = false
        
        bottomDialogView.addConstraint(NSLayoutConstraint(item: dialogButton1, attribute: .centerX, relatedBy: .equal, toItem: bottomDialogView, attribute: .centerX, multiplier: 1, constant: -60))
        
        bottomDialogView.addConstraint(NSLayoutConstraint(item: dialogButton1, attribute: .centerY, relatedBy: .equal, toItem: bottomDialogView, attribute: .centerY, multiplier: 1.55, constant: 0))
        
        dialogButton1.addConstraint(NSLayoutConstraint(item: dialogButton1, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100))
        
        dialogButton1.addConstraint(NSLayoutConstraint(item: dialogButton1, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 40))
        
        dialogButton1.layer.borderWidth = 1.0
        dialogButton1.layer.borderColor = UIColor.lightGray.cgColor
        
        dialogButton1.clipsToBounds = true
        dialogButton1.layer.cornerRadius = 20
        
        dialogButton1.setTitleColor(.black, for: .normal)
        
        dialogButton1.addTarget(self, action: #selector(didTapOnDialogButton1(sender:)), for: .touchUpInside)
    }
    
    func configureDialogButton2() {
        
        bottomDialogView.addSubview(dialogButton2)
        
        dialogButton2.translatesAutoresizingMaskIntoConstraints = false
        
        bottomDialogView.addConstraint(NSLayoutConstraint(item: dialogButton2, attribute: .centerX, relatedBy: .equal, toItem: bottomDialogView, attribute: .centerX, multiplier: 1, constant: 60))
        
        bottomDialogView.addConstraint(NSLayoutConstraint(item: dialogButton2, attribute: .centerY, relatedBy: .equal, toItem: bottomDialogView, attribute: .centerY, multiplier: 1.55, constant: 0))
        
        dialogButton2.addConstraint(NSLayoutConstraint(item: dialogButton2, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100))
        
        dialogButton2.addConstraint(NSLayoutConstraint(item: dialogButton2, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 40))
        
        dialogButton2.layer.borderWidth = 1.0
        dialogButton2.layer.borderColor = UIColor.lightGray.cgColor
        
        dialogButton2.clipsToBounds = true
        dialogButton2.layer.cornerRadius = 20
        
        dialogButton2.setTitleColor(.black, for: .normal)
        
        dialogButton2.addTarget(self, action: #selector(didTapOnDialogButton2(sender:)), for: .touchUpInside)
    }
    
    @objc func didTapOnDialogButton1(sender: UIButton) {
        
        animateExitBottomDialog()
        delegate?.didDismissDisableAssistance()
    }
    
    @objc func didTapOnDialogButton2(sender: UIButton) {
        
        delegate?.shouldDisableAssistance()
        
        animateExitBottomDialog()
    }
    
    func animateEnterBottomDialog() {
        
        let yPosition = bottomDialogView.frame.origin.y
        
        bottomDialogView.frame.origin.y = (UIScreen.main.bounds.height) + (UIScreen.main.bounds.height/2)
        
        delegate?.didPresentDisableAssistance()
        
        UIView.animate(withDuration: 0.3, delay: 0, animations: {
            
            self.bottomDialogView.frame.origin.y = yPosition
        })
    }
    
    func animateExitBottomDialog() {
        
        UIView.animate(withDuration: 0.4, delay: 0, animations: {
            
            self.bottomDialogView.frame.origin.y = (UIScreen.main.bounds.height)
            
        }) { (_) in
                            
            self.bottomDialogView.removeFromSuperview()
            self.removeFromSuperview()
        }
    }
}
