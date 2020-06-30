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


class JinyDiscovery {
    
    var id:Int?
    var name:String?
    var triggerMode:JinyTriggerMode
    var autoStart:Bool
    var weight:Int
    var frequencyPerApp:Int?
    var frequencyPerAppWithoutJiny:Int?
    var frequencyPerSession:Int?
    var frequencyPerSessionWithoutJiny:Int?
    var isWeb:Bool
    var discoveryInfo:JinyDiscoveryInfo?
    var flowIds:Array<String>
    var nativeIdentifiers:Array<String>
    var webIdentifiers:Array<String>
    var instruction:JinyInstruction?
    
    init(withDict discoveryDict:Dictionary<String,Any>) {
        id = discoveryDict["id"] as? Int
        name = discoveryDict["name"] as? String
        triggerMode = JinyTriggerMode(rawValue: (discoveryDict["trigger_mode"] as? String ?? "None") ) ?? .None
        autoStart = discoveryDict["auto_start"] as? Bool ?? false
        weight = discoveryDict["weight"] as? Int ?? 1
        frequencyPerApp = discoveryDict["frequency_per_app"] as? Int
        frequencyPerAppWithoutJiny = discoveryDict["frequency_per_app_wo_jiny"] as? Int
        frequencyPerSession = discoveryDict["frequency_per_session"] as? Int
        frequencyPerSessionWithoutJiny = discoveryDict["frequency_per_session_wo_jiny"] as? Int
        isWeb = discoveryDict["is_web"] as? Bool ?? false
        flowIds = discoveryDict["flow_ids"] as? Array<String> ?? []
        if let discoveyInfoDict = discoveryDict["info"] as? Dictionary<String,Any> {
            discoveryInfo = JinyDiscoveryInfo(discoveyInfoDict)
        }
        nativeIdentifiers = discoveryDict["native_identifiers"] as? Array<String> ?? []
        webIdentifiers = discoveryDict["web_identifiers"] as? Array<String> ?? []
        if let instructionDict = discoveryDict["instruction"] as? Dictionary<String,Any> {
            instruction = JinyInstruction(withDict: instructionDict)
        }
    }
    
}

extension JinyDiscovery:Equatable {
    
    static func == (lhs:JinyDiscovery, rhs:JinyDiscovery) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
}

extension JinyDiscovery {
    
    func copy(with zone: NSZone? = nil) -> JinyDiscovery {
        let copy = JinyDiscovery(withDict: [:])
        copy.id = self.id
        copy.name = self.name
        copy.triggerMode = self.triggerMode
        copy.autoStart = self.autoStart
        copy.isWeb = self.isWeb
        copy.weight = self.weight
        copy.frequencyPerApp = self.frequencyPerApp
        copy.frequencyPerAppWithoutJiny = self.frequencyPerAppWithoutJiny
        copy.frequencyPerSession = self.frequencyPerSession
        copy.frequencyPerSessionWithoutJiny = self.frequencyPerSessionWithoutJiny
        copy.discoveryInfo = self.discoveryInfo
        copy.webIdentifiers = self.webIdentifiers
        copy.nativeIdentifiers = self.nativeIdentifiers
        copy.instruction = self.instruction
        return copy
    }
    
}
