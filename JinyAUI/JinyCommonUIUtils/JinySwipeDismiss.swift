//
//  JinySwipeDismiss.swift
//  TestFlowSelector
//
//  Created by Aravind GS on 10/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class JinySwipeDismiss: UIPanGestureRecognizer {
    
    private let actionableView:UIView
    private let instance:Any
    private let method:Selector
    
    init(target:Any, actionToDismiss:Selector, view:UIView) {
        
        instance = target
        method = actionToDismiss
        actionableView = view
        super.init(target: nil, action:  nil)
        addTarget(self, action: #selector(swipeToClose(recognizer:)))
    }
    
}

extension JinySwipeDismiss{
    
    @objc private func swipeToClose(recognizer:UIPanGestureRecognizer) {
        if recognizer.state == .began {
            
        } else if recognizer.state == .changed {
            let translation = recognizer.translation(in: actionableView)
            if translation.y > 0 { actionableView.transform = CGAffineTransform(translationX: 0, y: translation.y)}
            
        } else if recognizer.state == .ended {
            let translation = recognizer.translation(in: actionableView)
            let velocity = recognizer.velocity(in: actionableView)
            if velocity.y > 100 {
                guard let chosenInstance = instance as? NSObject else {
                    return
                }
                if chosenInstance.responds(to: method) { chosenInstance.perform(method) }
                
            } else if translation.y > actionableView.frame.height * 0.6 {
                guard let chosenInstance = instance as? NSObject else {
                    return
                }
                if chosenInstance.responds(to: method) { chosenInstance.perform(method) }
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.actionableView.transform = .identity
                }
            }
        }
    }
    
}
