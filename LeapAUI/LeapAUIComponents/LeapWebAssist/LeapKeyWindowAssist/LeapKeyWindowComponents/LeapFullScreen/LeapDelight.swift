//
//  LeapDelight.swift
//  LeapSDK
//
//  Created by Ajay S on 27/05/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

class LeapDelight: LeapFullScreen {
    
    override func configureWebViewForFullScreen() {
        super.configureWebViewForFullScreen()
        
        self.isUserInteractionEnabled = false
        self.isOpaque = false
    }
}
