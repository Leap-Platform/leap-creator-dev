//
//  LeapAUIConstants.swift
//  LeapAUI
//
//  Created by Ajay S on 06/01/21.
//  Copyright © 2021 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

let FINGER_RIPPLE = "FINGER_RIPPLE"
let TOOLTIP = "TOOLTIP"
let HIGHLIGHT_WITH_DESC = "HIGHLIGHT_WITH_DESC"
let BEACON = "BEACON"
let SPOT = "SPOT"
let LABEL = "LABEL"
let SWIPE_LEFT = "SWIPE_LEFT"
let SWIPE_RIGHT = "SWIPE_RIGHT"
let SWIPE_UP = "SWIPE_UP"
let SWIPE_DOWN = "SWIPE_DOWN"

let POPUP = "POPUP"
let DRAWER = "DRAWER"
let FULLSCREEN = "FULLSCREEN"
let DELIGHT = "DELIGHT"
let BOTTOMUP = "BOTTOMUP"
let NOTIFICATION = "NOTIFICATION"
let SLIDEIN = "SLIDEIN"
let CAROUSEL = "CAROUSEL"
let PING = "PING"

// Value Constants
let mainIconSize: CGFloat = 56
var mainIconCornerConstant: CGFloat {
    return UIApplication.shared.statusBarOrientation.isLandscape ? 48 : 24
}
let mainIconBottomConstant: CGFloat = 45
let webAssistPreloadTime = 0.25

let maxWidthSupported: CGFloat = 450 // Specifically to support ipad where the width has to be restricted to 450 for better UI/UX.
