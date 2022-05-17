//
//  LeapInViewNativeAssist.swift
//  LeapSDK
//
//  Created by Ajay S on 17/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

class LeapInViewNativeAssist: LeapNativeAssist {
    
    /// target view to which the aui component is pointed to.
    weak var toView: UIView?    // should always be weak otherwise causes memory leak due to retain cycle.
    
    /// source view of the toView for which the aui component is relatively positioned.
    weak var inView: UIView?
    
    // rect for web page UI components
    var webRect: CGRect?
    
    /// - Parameters:
    ///   - assistDict: A dictionary value for the type LeapAssistInfo.
    ///   - toView: target view to which the tooltip is attached.
    ///   - insideView: an optional view on which overlay is diaplayed or else takes entire window.
    init(withDict assistDict: Dictionary<String, Any>, toView: UIView) {
        super.init(frame: CGRect.zero)
                
        self.assistInfo = LeapAssistInfo(withDict: assistDict)
        
        self.toView = toView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Method to configure constraints for the transparent view
    func configureOverlayView() {
        
        guard let superView = self.superview else {
            
            return
        }
                        
        // Setting Constraints to self
        
        self.translatesAutoresizingMaskIntoConstraints = false

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: superView, attribute: .centerX, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: superView, attribute: .centerY, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: superView, attribute: .width, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: superView, attribute: .height, multiplier: 1, constant: 0))
        
        // Overlay View to be clear by default
        
        self.backgroundColor = .clear
        
        self.isUserInteractionEnabled = false
    }
    
    func getGlobalToViewFrame() -> CGRect {
        guard let view = toView else { return .zero }
        let superview = view.superview ?? UIApplication.shared.windows.first { $0.isKeyWindow }
        guard let parent = superview else { return view.frame }
        return webRect == nil ? parent.convert(view.frame, to: inView) : view.convert(webRect!, to: inView)
    }
}
