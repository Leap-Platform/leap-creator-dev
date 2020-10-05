//
//  JinyDiscoveryInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

enum JinyDiscoveryInfoType:String {
    case None = "None"
    case Bottom = "BOTTOM"
    case Ping = "PING"
}

class JinyDiscoveryInfo {
    
    var type:JinyDiscoveryInfoType
    var triggerText:Dictionary<String,Array<String>> = [:]
    var optInText:Dictionary<String,String> = [:]
    var optOutText:Dictionary<String,String> = [:]
    var outsideDismiss:Bool
    var hideKeyboard:Bool
    var identifier:String?
    
    init(_ dict:Dictionary<String,Any>) {
        type = JinyDiscoveryInfoType(rawValue: dict["type"] as? String ?? "None") ?? .None
        outsideDismiss = dict["outside_dismiss"] as? Bool ?? true
        triggerText = dict["trigger_text"] as? Dictionary<String,Array<String>> ?? [:]
        optInText = dict["opt_in_text"] as? Dictionary<String,String> ?? [:]
        optOutText = dict["opt_out_text"] as? Dictionary<String,String> ?? [:]
        hideKeyboard = dict["hide_keyboard"] as? Bool ?? false
        identifier = dict["identifier"] as? String
    }
}
