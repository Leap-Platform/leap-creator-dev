//
//  JinyAssistInfoType.swift
//  JinySDK
//
//  Created by Aravind GS on 24/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyAssistInfoType:Codable {
    var id:String
    var name:String
    var detection_type:String
    var assist_type:String
    var trigger_on_anchor_click:Bool
    var checkpoint:Bool
    
    init(with assist:JinyAssist) {
        id = String(assist.id)
        name = assist.name
        detection_type = (assist.taggedEvents != nil) ? "event" : "context"
        assist_type = assist.type
        if let type = assist.trigger?.event?["type"], let value = assist.trigger?.event?["value"], type == "click", value == "showDiscovery" {
            trigger_on_anchor_click = true
        } else {
            trigger_on_anchor_click = false
        }
        checkpoint = assist.checkpoint
    }
    
}
