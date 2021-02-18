//
//  LeapStandardEvent.swift
//  LeapCore
//
//  Created by Aravind GS on 23/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class LeapDiscoveryEvent:Codable {
    let trigger_name:String
    let leap_lang:String
    let prompt_type:String
    let discovery_state:String?
    let leap_opt_in:Bool?
    
    init(with customEvent:LeapCustomEvent, isVisiblity:Bool, isOptIn:Bool?) {
        leap_lang = customEvent.languageInfo.leap_lang
        guard let discoveryEvent = customEvent.discovery_info else {
            trigger_name = ""
            prompt_type = ""
            discovery_state = nil
            leap_opt_in = nil
            return
        }
        trigger_name = discoveryEvent.name
        prompt_type = discoveryEvent.assist_type
        if let optIn = isOptIn { leap_opt_in = optIn }
        else { leap_opt_in = nil }
        if isVisiblity { discovery_state = discoveryEvent.type }
        else { discovery_state = nil }
    }
    
}


class LeapContextInfoEvent:Codable {
    
    let flow_name:String
    let leap_lang:String
    let leap_page_name:String?
    let leap_instruction:String?
    
    init(with customEvent:LeapCustomEvent) {
        flow_name = customEvent.context_info?.flow_info.flow_name ?? ""
        leap_lang = customEvent.languageInfo.leap_lang
        leap_page_name = customEvent.context_info?.page_info?.page_name
        leap_instruction = customEvent.context_info?.stage_info?.stage_name
    }
}

class LeapStandardEvent:Codable {
    
    var discoveryVisibleEvent:LeapDiscoveryEvent?
    var discoveryOptInEvent:LeapDiscoveryEvent?
    var discoveryOptOutEvent:LeapDiscoveryEvent?
    var leapFlowOptInEvent:LeapContextInfoEvent?
    var leapPageEvent:LeapContextInfoEvent?
    var leapInstructionEvent:LeapContextInfoEvent?
    
    init(withEvent:LeapAnalyticsEvent) {
        guard let customEvent = withEvent.leap_custom_events,
              let customEventTag = customEvent.event_tag else { return }
        switch customEventTag {
        case "discoveryVisibleEvent":
            discoveryVisibleEvent = LeapDiscoveryEvent(with: customEvent, isVisiblity: true, isOptIn: nil)
            break
        case "discoveryOptInEvent":
            discoveryOptInEvent = LeapDiscoveryEvent(with: customEvent, isVisiblity: false, isOptIn: true)
        case "discoveryOptOutEvent":
            discoveryOptOutEvent = LeapDiscoveryEvent(with: customEvent, isVisiblity: false, isOptIn: false)
        case "leapFlowOptInEvent":
            leapFlowOptInEvent = LeapContextInfoEvent(with: customEvent)
        case "leapPageEvent":
            leapPageEvent = LeapContextInfoEvent(with: customEvent)
        case "leapInstructionEvent":
            leapInstructionEvent = LeapContextInfoEvent(with: customEvent)
        default:
            break
        }
    }
}
