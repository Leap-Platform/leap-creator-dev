//
//  JinyDiscoveryInfoData.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyDiscoveryInfoData {
    var displayText:Array<String> = []
    var optInText:String?
    var optOutText:String?
    
    init(_ dictionary:Dictionary<String,Any>) {
        
        optInText = dictionary["opt_in_text"] as? String
        optOutText = dictionary["opt_out_text"] as? String
    }
}
