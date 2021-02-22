//
//  LeapContentInfoAction.swift
//  LeapCore
//
//  Created by Aravind GS on 30/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

class LeapContentActionInfo:Codable {
    var opt_in: Bool
    var click_type: String
    var close: Bool
    var actionType: String
    
    init(with dict:Dictionary<String,Any>, type:String) {
        opt_in = dict[constant_opt_in] as? Bool ?? false
        click_type = dict[constant_click_type] as? String ?? ""
        close = dict[constant_close] as? Bool ?? false
        actionType = type
    }
}
