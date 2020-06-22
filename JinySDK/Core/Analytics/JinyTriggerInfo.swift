//
//  JinyTriggerInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyTriggerInfo:Codable {
    
    var trigger_id:String
    var trigger_name:String
    var discovery_info:JinyDiscoveryExpInfo
    
    init() {
        trigger_id = ""
        trigger_name = ""
        discovery_info = JinyDiscoveryExpInfo()
    }
    
}
