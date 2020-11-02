//
//  JinyContentInfoAction.swift
//  JinySDK
//
//  Created by Aravind GS on 30/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyContentInfoAction:Codable {
    var opt_in: Bool
    var click_type: String
    var close: Bool
    var actionType: String
    
    init(with dict:Dictionary<String,Any>, type:String) {
        opt_in = dict["opt_in"] as? Bool ?? false
        click_type = dict["click_type"] as? String ?? ""
        close = dict["close"] as? Bool ?? false
        actionType = type
    }
}
