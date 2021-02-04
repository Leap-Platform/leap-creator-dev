//
//  JinyDiscovery.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

enum JinyTriggerType:String {
    case instant = "instant"
    case delay = "delay"
    case event = "event"
}

enum JinyTriggerFrequencyType: String {
    /// Triggers every session.
    case everySession = "EVERY_SESSION"
    /// Triggers only once in app's lifetime.
    case playOnce = "PLAY_ONCE"
    /// Triggers on jiny icon click.
    case manualTrigger = "MANUAL_TRIGGER"
    /// Triggers every session until dismissed by user. (Doesn't trigger in the next session if user has dismissed)
    case everySessionUntilDismissed = "EVERY_SESSION_UNTIL_DISMISSED"
    /// Triggers every session until flow is complete. (Doesn't trigger in the next session if flow is completed)
    case everySessionUntilFlowComplete = "EVERY_SESSION_UNTIL_FLOW_COMPLETE"
}

class JinyTrigger {
    /// type could be 'instant' or 'delay'
    let type:JinyTriggerType
    /// delay time (ms) if the type is 'delay'
    let delay:Double?
    /// event type - 'click' and value could be 'optIn' or 'showDiscovery'
    let event:Dictionary<String, String>?
    
    init(with dict:Dictionary<String,Any>) {
        type =  JinyTriggerType(rawValue: (dict[constant_type] as? String ?? constant_instant)) ?? .instant
        delay = dict[constant_delay] as? Double
        event = dict[constant_event] as? Dictionary<String, String>
    }
    
}

class JinyTriggerFrequency {
    /// attribute that explains the type of trigger frequency.
    let type: JinyTriggerFrequencyType?
    
    init(with dict: Dictionary<String, String>) {
        if let triggerFrequencyType = dict[constant_type] {
            self.type = JinyTriggerFrequencyType(rawValue: triggerFrequencyType)
        } else {
            self.type = .everySession
        }
    }
}

class JinyFlowTerminationFrequency: JinyFrequency {
    /// Terminates a discovery after n sessions.
    var nSession: Int?
    /// Terminates a discovery after n dismisses by the user.
    var nDismissByUser: Int?
    
    override init(with dict: Dictionary<String, Int>) {
        super.init(with: dict)
        nSession = dict[constant_nSession]
        nDismissByUser = dict[constant_nDismissByUser]
        
    }
}

class JinyDiscovery:JinyContext {

    var enableIcon:Bool
    var triggerMode:JinyTriggerMode
    var autoStart:Bool
    var terminationfrequency:JinyFlowTerminationFrequency?
    var flowId:Int?
    var triggerFrequency: JinyTriggerFrequency?
    var localeCodes: [String]?
    var languageOption: [String : String]?
    
    init(withDict discoveryDict:Dictionary<String,Any>) {
        triggerMode = JinyTriggerMode(rawValue: (discoveryDict[constant_triggerMode] as? String ?? "SINGLE_FLOW_TRIGGER")) ??  JinyTriggerMode.Single
        enableIcon = discoveryDict[constant_enableIcon] as? Bool ?? false
        autoStart = discoveryDict[constant_autoStart] as? Bool ?? false
        if let freqDict = discoveryDict[constant_flowTerminationFrequency] as? Dictionary<String,Int> {
            terminationfrequency = JinyFlowTerminationFrequency(with: freqDict)
        }
        flowId = discoveryDict[constant_flowId] as? Int
        if let triggerFrequencyDict = discoveryDict[constant_triggerFrequency] as? Dictionary<String,String> {
            triggerFrequency = JinyTriggerFrequency(with: triggerFrequencyDict)
        }
        if let localeCodes = discoveryDict[constant_localeCodes] as? [String] {
            self.localeCodes = localeCodes
        }
        if let languageOption = discoveryDict[constant_languageOption] as? [String : String] {
            self.languageOption = languageOption
        }
        
        super.init(with: discoveryDict)
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
        copy.terminationfrequency = self.terminationfrequency
        copy.flowId = self.flowId
        copy.trigger = self.trigger
        copy.instruction = self.instruction
        copy.instructionInfoDict = self.instructionInfoDict
        return copy
    }
    
}
