//
//  JinyDiscoveryItemClickInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyDiscoveryItemClickInfo:Codable {
    
    var normal_thought_bubble_click:Bool
    var normal_thought_bubble_clicked_index:Int = -1
    var language_thought_bubble_click:Bool
    var discovery_icon_click:Bool
    var discovery_cross_click:Bool
    var discovery_click_info:Dictionary<String,Dictionary<String,String>>
    
    init() {
        normal_thought_bubble_click = false
        language_thought_bubble_click = false
        discovery_icon_click = false
        discovery_cross_click = false
        discovery_click_info = [:]
    }
    
}
