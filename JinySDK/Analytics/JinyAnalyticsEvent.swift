//
//  JinyAnalyticsEvent.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation


class JinyAnalyticsEvent:Codable {
    
    var jiny_id:String
    var jiny_custom_events:JinyCustomEvent?
    var jiny_crash_event:Dictionary<String,String>?
    var jiny_standard_event:JinyStandardEvent?
    var jiny_timestamp:JinyTimeInfo
    
    init() {
        
        jiny_id = String.generateUUIDString()
        jiny_timestamp = JinyTimeInfo()
    }
    
    
}
