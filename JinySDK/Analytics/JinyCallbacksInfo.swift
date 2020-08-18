//
//  JinyCallbacksInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyCallbacksInfo:Codable {
    var jiny_init:Bool
    var jiny_resume:Bool
    var jiny_pause:Bool
    var jiny_javascript_interface_state:Bool
    var client_activity_name:String
    var jiny_disable:Bool
    var jiny_destroy:Bool
    var jiny_disable_assistant:Bool
    
    init() {
        jiny_init = false
        jiny_resume = false
        jiny_pause = false
        jiny_javascript_interface_state = false
        client_activity_name = ""
        jiny_disable = false
        jiny_destroy = false
        jiny_disable_assistant = false
    }
}
