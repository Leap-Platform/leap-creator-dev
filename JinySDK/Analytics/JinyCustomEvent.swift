//
//  JinyCustomEvent.swift
//  JinySDK
//
//  Created by Aravind GS on 23/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import AdSupport

class JinyCustomEvent:Codable {
    var context_info:JinyContextInfo?
    var discovery_info:JinyDiscoveryInfo?
    var assist_info:JinyAssistInfoType?
    var content_action_info:JinyContentActionInfo?
    var event_tag:String?
    var jiny_session_id:String
    var client_id:String
    var google_ad_id:String
    var device_info:JinyDeviceInfo
    var languageInfo:JinyLanguageInfo
    
    init(with eventTag:String) {
        
        jiny_session_id = JinySharedInformation.shared.getSessionId()
        client_id = JinySharedInformation.shared.getAPIKey()
        device_info = JinyDeviceInfo()
        languageInfo = JinyLanguageInfo()
        event_tag = eventTag
        google_ad_id = ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
}
