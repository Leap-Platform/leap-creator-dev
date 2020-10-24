//
//  JinyCustomEvent.swift
//  JinySDK
//
//  Created by Aravind GS on 23/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyCustomEvent:Codable {
    var context_info:JinyContextTypeInfo?
    var discovery_info:JinyDiscoveryInfoEvent?
    var assist_info:JinyAssistInfoType?
    
}
