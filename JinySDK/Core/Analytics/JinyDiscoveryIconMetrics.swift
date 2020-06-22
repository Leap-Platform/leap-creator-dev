//
//  JinyDiscoveryIconMetrics.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyDiscoveryIconMetrics:Codable {
    
    var initial_trigger_type:String
    var trigger_info:JinyTriggerInfo
    var is_first_onboarding:Bool
    var discovery_icon_state:String
    var independent_trigger_closed:Bool
    var is_in_hibernate:Bool
    
    init() {
        initial_trigger_type = ""
        trigger_info = JinyTriggerInfo()
        is_first_onboarding = true
        discovery_icon_state = ""
        independent_trigger_closed = false
        is_in_hibernate = false
    }
    
}
