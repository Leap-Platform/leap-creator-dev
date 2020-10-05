//
//  JinyDiscovery.swift
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

class JinyTaggedEventCondition {
    
    let identifier:String
    let value:String
    let type:String
    let condition:String
    
    init(withDict dict:Dictionary<String,Any>) {
        identifier = dict["identifier"] as? String ?? ""
        value = dict["value"] as? String ?? ""
        type = dict["type"] as? String ?? ""
        condition = dict["condition"] as? String ?? ""
    }
    
}

class JinyTaggedEvent {
    
    var orConditions:Array<Array<JinyTaggedEventCondition>> = []
    var action:String?
    
    init(withDict taggedDict:Dictionary<String,Any>) {
        action = taggedDict["action"] as? String
        if let eventsDictArray = taggedDict["events"] as? Array<Array<Dictionary<String,Any>>>{
            for andConditionsArray in eventsDictArray {
                var andConditions:Array<JinyTaggedEventCondition> = []
                for andCondition in andConditionsArray {
                    andConditions.append(JinyTaggedEventCondition(withDict: andCondition))
                }
                orConditions.append(andConditions)
            }
        }
        
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
    var flowIds:Array<Int>
    var nativeIdentifiers:Array<String>
    var webIdentifiers:Array<String>
    var instruction:JinyInstruction?
    var trigger:Dictionary<String,Any>
    var taggedEvents:JinyTaggedEvent?
    var seenFrequency:Dictionary<String,Int>?
    var instructionInfoDict:Dictionary<String,Any>?
    
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
        flowIds = discoveryDict["flow_ids"] as? Array<Int> ?? []
        if let discoveyInfoDict = discoveryDict["info"] as? Dictionary<String,Any> {
            discoveryInfo = JinyDiscoveryInfo(discoveyInfoDict)
        }
        nativeIdentifiers = discoveryDict["native_identifiers"] as? Array<String> ?? []
        webIdentifiers = discoveryDict["web_identifiers"] as? Array<String> ?? []
        if let instructionDict = discoveryDict["instruction"] as? Dictionary<String,Any> {
            instructionInfoDict = instructionDict
            instruction = JinyInstruction(withDict: instructionDict)
        }
        trigger = discoveryDict["trigger"] as? Dictionary<String,Any> ?? [:]
        if let taggedEventsDict = discoveryDict["tagged_events"] as? Dictionary<String,Any> {
            taggedEvents = JinyTaggedEvent(withDict: taggedEventsDict)
        }
        seenFrequency = discoveryDict["seen_frequency"] as? Dictionary<String,Int>
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
