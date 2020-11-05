//
//  JinyDiscoveryInfoEvent.swift
//  JinySDK
//
//  Created by Aravind GS on 24/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
/*
{
"id":"_discovery_id",     // String
"name":"registeration",   // String
"type":"single_flow/multi_flow"  // String/Enum
"detection_type":"event/context",   // String/Enum
"tagged_discovery":true/false    // boolean
"assist_type":"tooltip",    // any type of assist
"trigger_type": "on_app_open/custom_trigger",
"trigger_delay": 5000   // miliseconds
"trigger_on_anchor_click":true/false,
"opt_in_on_anchor_click":true/false,
}
*/
class JinyDiscoveryInfoEvent:Codable {
    let id:String
    let name:String
    let type:String
    let detection_type:String
    let tagged_discovery:Bool
    let assist_type:String
    let trigger_type:String
    let trigger_delay:Float
    let trigger_on_anchor_click:Bool
    let opt_in_on_anchor_click:Bool
    
    init(withDiscovery dis:JinyDiscovery) {
        id = String(dis.id)
        name = dis.name
        type = (dis.triggerMode == .Multi) ? "multi_flow" : "single_flow"
        detection_type = (dis.taggedEvents != nil) ? "event" : "context"
        tagged_discovery = (dis.taggedEvents != nil)
        if let instruction = dis.instructionInfoDict,
            let assistInfo = instruction["assist_info"] as? Dictionary<String,Any>,
            let assistType = assistInfo["type"] as? String {
            assist_type = assistType
        } else { assist_type = "" }
        trigger_type = dis.trigger?.type ?? ""
        trigger_delay = dis.trigger?.delay ?? 0
        trigger_on_anchor_click = dis.eventIdentifiers?.triggerOnAnchorClick ?? false
        opt_in_on_anchor_click = dis.trigger?.optInOnAnchorClick ?? false
    }
}
