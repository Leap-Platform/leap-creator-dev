//
//  JinyDiscovery.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyTrigger {
    let type:String
    let delay:Float?
    let autoTrigger:Bool
    let optInOnAnchorClick:Bool
    
    init(with dict:Dictionary<String,Any>) {
        type = dict["type"] as? String ?? "on_app_open"
        delay = dict["delay"] as? Float
        autoTrigger = dict["auto_trigger"] as? Bool ?? true
        optInOnAnchorClick = dict["opt_in_on_anchor_click"] as? Bool ?? false
    }
    
}

class JinySeenFrequency {
    let nSession:Int?
    let nDismissedByUser:Int?
    let nFlowCompleted:Int?
    
    init(with dict:Dictionary<String,Int>) {
        nSession = dict["n_session"]
        nDismissedByUser = dict["n_dismissed_by_user"]
        nFlowCompleted = dict["n_flow_completed"]
    }
}

class JinyDiscovery:JinyContext {

    var enableIcon:Bool
    var triggerMode:JinyTriggerMode
    var autoStart:Bool
    var frequency:JinyFrequency?
    var flowId:Int?
    var instruction:JinyInstruction?
    var trigger:JinyTrigger?
    var seenFrequency:JinySeenFrequency?
    var eventIdentifiers:JinyEventIdentifier?
    var instructionInfoDict:Dictionary<String,Any>?
    
    init(withDict discoveryDict:Dictionary<String,Any>) {
        triggerMode = JinyTriggerMode(rawValue: (discoveryDict["trigger_mode"] as? String ?? "SINGLE_FLOW_TRIGGER")) ??  JinyTriggerMode.Single
        enableIcon = discoveryDict["enable_icon"] as? Bool ?? false
        autoStart = discoveryDict["auto_start"] as? Bool ?? false
        if let freqDict = discoveryDict["frequency"] as? Dictionary<String,Int> {
            frequency = JinyFrequency(with: freqDict)
        }
        flowId = discoveryDict["flow_id"] as? Int
        if let instructionDict = discoveryDict["instruction"] as? Dictionary<String,Any> {
            instructionInfoDict = instructionDict
            instruction = JinyInstruction(withDict: instructionDict)
        }
        if let triggerDict = discoveryDict["trigger"] as? Dictionary<String,Any> {
            trigger = JinyTrigger(with: triggerDict)
        }
        if let seenDict = discoveryDict["seen_frequency"] as? Dictionary<String,Int> {
            seenFrequency = JinySeenFrequency(with: seenDict)
        }
        if let eventIdentifierDict = discoveryDict["event_identifiers"] as? Dictionary<String,Any> {
            eventIdentifiers = JinyEventIdentifier(withDict: eventIdentifierDict)
        }
        super.init(with: discoveryDict)
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
        copy.webIdentifiers = self.webIdentifiers
        copy.nativeIdentifiers = self.nativeIdentifiers
        copy.taggedEvents = self.taggedEvents
        copy.isWeb = self.isWeb
        copy.weight = self.weight
        copy.checkpoint = self.checkpoint
        
        copy.enableIcon = self.enableIcon
        copy.triggerMode = self.triggerMode
        copy.autoStart = self.autoStart
        copy.frequency = self.frequency
        copy.flowId = self.flowId
        copy.trigger = self.trigger
        copy.seenFrequency = self.seenFrequency
        copy.instruction = self.instruction
        copy.instructionInfoDict = self.instructionInfoDict
        copy.eventIdentifiers = self.eventIdentifiers
        return copy
    }
    
}
