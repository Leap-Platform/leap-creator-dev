//
//  LeapAnalyticsEvent.swift
//  LeapCore
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation


class LeapAnalyticsEvent:Codable {
    
    var leap_id:String
    var leap_custom_events:LeapCustomEvent?
    var leap_crash_event:Dictionary<String,String>?
    var leap_standard_event:LeapStandardEvent?
    var leap_timestamp:LeapTimeInfo
    
    init() {
        
        leap_id = String.generateUUIDString()
        leap_timestamp = LeapTimeInfo()
    }
    
    
}
