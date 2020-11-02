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
        id = String(assist.assistId)
        name = String(assist.name ?? "")
        detection_type = (assist.eventIdentifiers != nil) ? "event" : "context"
        assist_type = "FINGER_RIPPLE"
        trigger_on_anchor_click = assist.eventIdentifiers?.triggerOnAnchorClick ?? false
        checkpoint = assist.checkPoint
    }
    
}
