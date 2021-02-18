//
//  JinyStandardEvent.swift
//  JinySDK
//
//  Created by Aravind GS on 23/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyDiscoveryEvent:Codable {
    let trigger_name:String
    let jiny_lang:String
    let prompt_type:String
    let discovery_state:String?
    let jiny_opt_in:Bool?
    
    init(with customEvent:JinyCustomEvent, isVisiblity:Bool, isOptIn:Bool?) {
        jiny_lang = customEvent.languageInfo.jiny_lang
        guard let discoveryEvent = customEvent.discovery_info else {
            trigger_name = ""
            prompt_type = ""
            discovery_state = nil
            jiny_opt_in = nil
            return
        }
        trigger_name = discoveryEvent.name
        prompt_type = discoveryEvent.assist_type
        if let optIn = isOptIn { jiny_opt_in = optIn }
        else { jiny_opt_in = nil }
        if isVisiblity { discovery_state = discoveryEvent.type }
        else { discovery_state = nil }
    }
    
}


class JinyContextInfoEvent:Codable {
    
    let flow_name:String
    let jiny_lang:String
    let jiny_page_name:String?
    let jiny_instruction:String?
    
    init(with customEvent:JinyCustomEvent) {
        flow_name = customEvent.context_info?.flow_info.flow_name ?? ""
        jiny_lang = customEvent.languageInfo.jiny_lang
        jiny_page_name = customEvent.context_info?.page_info?.page_name
        jiny_instruction = customEvent.context_info?.stage_info?.stage_name
    }
}

class JinyStandardEvent:Codable {
    
    var discoveryVisibleEvent:JinyDiscoveryEvent?
    var discoveryOptInEvent:JinyDiscoveryEvent?
    var discoveryOptOutEvent:JinyDiscoveryEvent?
    var jinyFlowOptInEvent:JinyContextInfoEvent?
    var jinyPageEvent:JinyContextInfoEvent?
    var jinyInstructionEvent:JinyContextInfoEvent?
    
    init(withEvent:JinyAnalyticsEvent) {
        guard let customEvent = withEvent.jiny_custom_events,
              let customEventTag = customEvent.event_tag else { return }
        switch customEventTag {
        case "discoveryVisibleEvent":
            discoveryVisibleEvent = JinyDiscoveryEvent(with: customEvent, isVisiblity: true, isOptIn: nil)
            break
        case "discoveryOptInEvent":
            discoveryOptInEvent = JinyDiscoveryEvent(with: customEvent, isVisiblity: false, isOptIn: true)
        case "discoveryOptOutEvent":
            discoveryOptOutEvent = JinyDiscoveryEvent(with: customEvent, isVisiblity: false, isOptIn: false)
        case "jinyFlowOptInEvent":
            jinyFlowOptInEvent = JinyContextInfoEvent(with: customEvent)
        case "jinyPageEvent":
            jinyPageEvent = JinyContextInfoEvent(with: customEvent)
        case "jinyInstructionEvent":
            jinyInstructionEvent = JinyContextInfoEvent(with: customEvent)
        default:
            break
        }
    }
}
