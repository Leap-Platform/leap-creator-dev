//
//  LeapCustomEvent.swift
//  LeapCore
//
//  Created by Aravind GS on 23/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import AdSupport

class LeapCustomEvent:Codable {
    var context_info:LeapContextInfo?
    var discovery_info:LeapDiscoveryInfo?
    var assist_info:LeapAssistInfoType?
    var content_action_info:LeapContentActionInfo?
    var event_tag:String?
    var leap_session_id:String
    var client_id:String
    var google_ad_id:String
    var device_info:LeapDeviceInfo
    var languageInfo:LeapLanguageInfo
    
    init(with eventTag:String) {
        
        leap_session_id = LeapSharedInformation.shared.getSessionId()
        client_id = LeapSharedInformation.shared.getAPIKey()
        device_info = LeapDeviceInfo()
        languageInfo = LeapLanguageInfo()
        event_tag = eventTag
        google_ad_id = ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
}
