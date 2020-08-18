//
//  JinyOptInButton.swift
//  TestFlowSelector
//
//  Created by Aravind GS on 05/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class JinyOptInButton: UIButton {

   override func layoutSubviews() {
        super.layoutSubviews()
        if imageView != nil {
            imageView?.contentMode = .scaleAspectFit
            imageEdgeInsets = UIEdgeInsets(top: 15, left: (bounds.width - 35), bottom: 15, right: 10)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: (imageView?.frame.width)!)
        }
    }

}
