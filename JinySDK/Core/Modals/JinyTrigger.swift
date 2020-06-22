//
//  JinyTrigger.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

enum JinyTriggerMode:String {
    case None   =   "None"
    case Single =   "SINGLE_FLOW_TRIGGER"
    case Multi  =   "MULTI_FLOW_TRIGGER"
}

class JinyTrigger {
    
    var id:Int
    var name:String
    var weight:Int
    var identifiers:JinyTriggerIdentifier?
    var discoveryInfo:JinyDiscoveryInfo?
    var mode:JinyTriggerMode
    var flowIndexes:Array<Int>
    var hideKeyboard:Bool
    var soundName:String?
    
    init(withTriggerDict dict:Dictionary<String,Any>) {
        
        id = dict["id"] as? Int ?? -1
        name = dict["name"] as? String ?? ""
        weight = dict["weight"] as? Int ?? 1
        if let identifiersDict = dict["identifiers"] as? Dictionary<String,Any> {
            identifiers = JinyTriggerIdentifier(dict: identifiersDict)
        }
        if let discoveryInfoDict = dict["discovery_info"] as? Dictionary<String,Any> {
            discoveryInfo = JinyDiscoveryInfo(discoveryInfoDict)
        }
        mode = JinyTriggerMode(rawValue: dict["mode"] as? String ?? "None") ?? .None
        flowIndexes = dict["flow_index"] as? Array<Int> ?? []
        hideKeyboard = dict["hide_keyboard"] as? Bool ?? false
        soundName = dict["sound_name"] as? String
    }
    
}

extension JinyTrigger:Equatable {
    
    static func == (lhs:JinyTrigger, rhs:JinyTrigger) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
}

extension JinyTrigger {
    
    func copy(with zone: NSZone? = nil) -> JinyTrigger {
        let copy = JinyTrigger(withTriggerDict: [:])
        copy.id = self.id
        copy.name = self.name
        copy.identifiers = self.identifiers
        copy.discoveryInfo = self.discoveryInfo
        copy.mode = self.mode
        copy.flowIndexes = self.flowIndexes
        copy.hideKeyboard = self.hideKeyboard
        copy.soundName = self.soundName
        return copy
    }
    
}
