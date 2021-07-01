//
//  LeapSupportModals.swift
//  LeapCore
//
//  Created by Aravind GS on 05/11/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

class LeapTTSInfo{
    let ttsLocale:String?
    let ttsRegion:String?
    
    init(_ dict:Dictionary<String,String>) {
        ttsLocale = dict["ttsLocale"]
        ttsRegion = dict["ttsRegion"]
    }
}

enum LeapTriggerMode:String {
    case Single =   "SINGLE_FLOW_TRIGGER"
    case Multi  =   "MULTI_FLOW_TRIGGER"
}

class LeapTaggedEventCondition {
    
    let identifier:String
    let value:String
    let type:String
    let condition:String
    
    init(withDict dict:Dictionary<String,Any>) {
        identifier = dict[constant_identifier] as? String ?? ""
        value = dict[constant_value] as? String ?? ""
        type = dict[constant_type] as? String ?? ""
        condition = dict[constant_condition] as? String ?? ""
    }
    
}

class LeapTaggedEvent {
    
    var orConditions:Array<Array<LeapTaggedEventCondition>> = []
    var action:String?
    
    init(withDict taggedDict:Dictionary<String,Any>) {
        action = taggedDict[constant_action] as? String
        if let eventsDictArray = taggedDict[constant_events] as? Array<Array<Dictionary<String,Any>>>{
            for andConditionsArray in eventsDictArray {
                var andConditions:Array<LeapTaggedEventCondition> = []
                for andCondition in andConditionsArray {
                    andConditions.append(LeapTaggedEventCondition(withDict: andCondition))
                }
                orConditions.append(andConditions)
            }
        }
        
    }
    
}

class LeapAssistInfo {
    var layoutInfo:Dictionary<String,Any>
    var autoDismissDelay:Float?
    var htmlUrl:String?
    var contentUrls:Array<String>
    var highlightClickable:Bool
    var autoScroll:Bool
    var autoFocus:Bool
    var type:String?
    var identifier:String?
    var isWeb:Bool
    var accessibilityText:String?
    
    init(withDict infoDict:Dictionary<String,Any>) {

        layoutInfo = infoDict[constant_layoutInfo] as? Dictionary<String,Any> ?? [:]
        htmlUrl = infoDict[constant_htmlUrl] as? String
        contentUrls = infoDict[constant_contentUrls] as? Array<String> ?? []
        highlightClickable = infoDict[constant_highlightClickable] as? Bool ?? false
        autoScroll = infoDict[constant_autoScroll] as? Bool ?? false
        autoFocus = infoDict[constant_autoFocus] as? Bool ?? false
        type = infoDict[constant_type] as? String
        identifier = infoDict[constant_identifier] as? String
        if let delay = infoDict[constant_autoDismissDelay] as? Float {
            autoDismissDelay = (delay/1000)
        }
        isWeb = infoDict[constant_isWeb] as? Bool ?? false
        accessibilityText = infoDict[constant_accessibilityText] as? String
    }
}

class LeapFrequency {
    /// number of times a discovery is shown in a session until flow complete
    let perApp:Int?
    /// number of times a stage is shown inside a flow
    let perFlow:Int?
    
    init(with dict:Dictionary<String,Int>) {
        perApp = dict[constant_perApp]
        perFlow = dict[constant_perFlow]
    }
    
}

class LeapInstruction {
    
    var soundName:String?
    var assistInfo:LeapAssistInfo?
    var id = String.generateUUIDString()
    
    init(withDict instructionDict:Dictionary<String,Any>) {
        soundName = instructionDict[constant_soundName] as? String
        if let assistInfoDict = instructionDict[constant_assistInfo] as? Dictionary<String,Any> {
            assistInfo = LeapAssistInfo(withDict: assistInfoDict)
        }
    }
    
}

