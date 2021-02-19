//
//  LeapAssistInfoType.swift
//  LeapCore
//
//  Created by Aravind GS on 24/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

class LeapAssistInfoType:Codable {
    var id:String
    var name:String
    var detection_type:String
    var assist_type:String
    var trigger_on_anchor_click:Bool
    var checkpoint:Bool
    
    init(with assist:LeapAssist) {
        id = String(assist.id)
        name = assist.name
        detection_type = (assist.taggedEvents != nil) ? constant_event : constant_context
        assist_type = assist.type
        if let type = assist.trigger?.event?[constant_type], let value = assist.trigger?.event?[constant_value], type == constant_click, value == constant_showDiscovery {
            trigger_on_anchor_click = true
        } else {
            trigger_on_anchor_click = false
        }
        checkpoint = assist.checkpoint
    }
    
}
