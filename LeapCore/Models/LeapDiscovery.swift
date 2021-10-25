//
//  LeapDiscovery.swift
//  LeapCore
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

enum LeapTriggerType:String {
    case instant = "instant"
    case delay = "delay"
    case event = "event"
}

enum LeapTriggerFrequencyType: String {
    /// Triggers every session.
    case everySession = "EVERY_SESSION"
    /// Triggers only once in app's lifetime.
    case playOnce = "PLAY_ONCE"
    /// Triggers on leap icon click.
    case manualTrigger = "MANUAL_TRIGGER"
    /// Triggers every session until dismissed by user. (Doesn't trigger in the next session if user has dismissed)
    case everySessionUntilDismissed = "EVERY_SESSION_UNTIL_DISMISSED"
    /// Triggers every session until flow is complete. (Doesn't trigger in the next session if flow is completed)
    case everySessionUntilFlowComplete = "EVERY_SESSION_UNTIL_FLOW_COMPLETE"
    /// Triggers until all flows in a flow menu are completed
    case everySessionUntilAllFlowsAreCompleted = "EVERY_SESSION_UNTIL_ALL_FLOWS_ARE_COMPLETED"
}

class LeapTrigger {
    /// type could be 'instant' or 'delay'
    let type:LeapTriggerType
    /// delay time (ms) if the type is 'delay'
    let delay:Double?
    /// event type - 'click' and value could be 'optIn' or 'showDiscovery'
    let event:Dictionary<String, String>?
    
    init(with dict:Dictionary<String,Any>) {
        type =  LeapTriggerType(rawValue: (dict[constant_type] as? String ?? constant_instant)) ?? .instant
        delay = dict[constant_delay] as? Double
        event = dict[constant_event] as? Dictionary<String, String>
    }
    
}

class LeapTriggerFrequency {
    /// attribute that explains the type of trigger frequency.
    let type: LeapTriggerFrequencyType?
    
    init(with dict: Dictionary<String, String>) {
        if let triggerFrequencyType = dict[constant_type] {
            self.type = LeapTriggerFrequencyType(rawValue: triggerFrequencyType)
        } else {
            self.type = .everySession
        }
    }
}

class LeapFlowTerminationFrequency: LeapFrequency {
    /// Terminates a discovery after n sessions.
    var nSession: Int?
    /// Terminates a discovery after n dismisses by the user.
    var nDismissByUser: Int?
    /// Terminates flow menu if all flows are completed
    var untilAllFlowsAreCompleted: Bool?
    
    override init(with dict: Dictionary<String, Any>) {
        super.init(with: dict)
        nSession = dict[constant_nSession] as? Int
        nDismissByUser = dict[constant_nDismissedByUser] as? Int
        untilAllFlowsAreCompleted = dict[constant_untilAllFlowsAreCompleted] as? Bool
    }
}

class LeapDiscovery:LeapContext {

    var enableIcon:Bool
    var triggerMode:LeapTriggerMode
    var autoStart:Bool
    var terminationfrequency:LeapFlowTerminationFrequency?
    var flowId:Int?
    var flowProjectIds:Array<String>?
    var triggerFrequency: LeapTriggerFrequency?
    var localeCodes: Array<String>?
    var languageOption: Dictionary<String,String>?
    
    init(withDict discoveryDict:Dictionary<String,Any>, isPreview:Bool, connectedProjectIds:Array<String> = []) {
        triggerMode = LeapTriggerMode(rawValue: (discoveryDict[constant_triggerMode] as? String ?? "SINGLE_FLOW_TRIGGER")) ??  LeapTriggerMode.Single
        enableIcon = discoveryDict[constant_enableIcon] as? Bool ?? false
        autoStart = discoveryDict[constant_autoStart] as? Bool ?? false
        flowId = discoveryDict[constant_flowId] as? Int
        flowProjectIds = connectedProjectIds
        
        if !isPreview {
            if let freqDict = discoveryDict[constant_flowTerminationFrequency] as? Dictionary<String,Any> {
                terminationfrequency = LeapFlowTerminationFrequency(with: freqDict)
            }
            if let triggerFrequencyDict = discoveryDict[constant_triggerFrequency] as? Dictionary<String,String> {
                triggerFrequency = LeapTriggerFrequency(with: triggerFrequencyDict)
            }
        }
        
        if let localeCodes = discoveryDict[constant_localeCodes] as? [String] {
            self.localeCodes = localeCodes
        } else {
            self.localeCodes = ["ang"]
        }
        if let languageOption = discoveryDict[constant_languageOption] as? [String : String] {
            self.languageOption = languageOption
        }
        
        super.init(with: discoveryDict)
        if let locales = self.localeCodes, locales.isEmpty {
            self.localeCodes = ["ang"]
        }
    }
    
}

extension LeapDiscovery {
    
    func copy(with zone: NSZone? = nil) -> LeapDiscovery {
        let copy = LeapDiscovery(withDict: [:],isPreview: false)
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
        copy.localeCodes = self.localeCodes
        copy.languageOption = self.languageOption
        return copy
    }
    
}
