//
//  JinyPilotInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyPilotInfo:Codable {
    
    var is_stealth_mode:Bool
    var pilot_config_version:String
    
    init() {
        is_stealth_mode = false
        pilot_config_version = ""
    }
    
}
