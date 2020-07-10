//
//  JinyAppleIdInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import AdSupport


class JinyAppleIdInfo:Codable {
    
    var google_ad_id:String = ASIdentifierManager.shared().advertisingIdentifier.uuidString
    
}
