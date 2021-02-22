//
//  LeapTimeInfo.swift
//  LeapCore
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

class LeapTimeInfo:Codable {
    
    var timezone:String
    var timestamp:String
    
    init() {
        timestamp = Date.getTimeStamp()
        timezone = TimeZone.current.identifier
    }
    
}
