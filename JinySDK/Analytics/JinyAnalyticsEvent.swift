//
//  JinyAnalyticsEvent.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation


class JinyAnalyticsEvent:Codable {
    
    var id:String
    var jiny_session_id:String
    var client_id:String
    var jiny_menu_item_click_info:JinyMenuItemClickInfo?
    var jiny_bottom_activity_stateInfo:JinyBottomActivityStateInfo?
    var jiny_callbacks_info:JinyCallbacksInfo?
    var sound_info:JinySoundInfo?
    var language_info:JinyLanguageInfo?
    var discovery_icon_metrics:JinyDiscoveryIconMetrics?
    var jiny_discovery_item_click_info:JinyDiscoveryItemClickInfo?
    var client_preference:JinyClientPreference
    var device_info:JinyDeviceInfo
    var google_user_info:JinyAppleIdInfo
    var output_type_info:JinyOutputTypeInfo?
    var time_info:JinyTimeInfo
    var timestamp:String
    var jiny_lambda_info:JinyLambdaInfo?
    var context_type_info:JinyContextTypeInfo?
    var pilot_info:JinyPilotInfo
    var experiment_info:JinyExperimentInfo?
    var click_info:JinyClickInfo?
    var env_info:String?
    var sdk_info:JinySDKInfo?
    var client_callback:Dictionary<String,Dictionary<String,String>>?
    
    init() {
        
        id = String.generateUUIDString()
        jiny_session_id = JinySharedInformation.shared.getSessionId()
        client_id = JinySharedInformation.shared.getAPIKey()
        client_preference = JinyClientPreference()
        google_user_info = JinyAppleIdInfo()
        device_info = JinyDeviceInfo()
        pilot_info = JinyPilotInfo()
        timestamp = Date.getTimeStamp()
        time_info = JinyTimeInfo(ts: timestamp)
    }
    
    
}
