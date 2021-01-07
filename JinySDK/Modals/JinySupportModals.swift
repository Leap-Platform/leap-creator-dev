//
//  JinySupportModals.swift
//  JinySDK
//
//  Created by Aravind GS on 05/11/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

enum JinyTriggerMode:String {
    case Single =   "SINGLE_FLOW_TRIGGER"
    case Multi  =   "MULTI_FLOW_TRIGGER"
}

class JinyTaggedEventCondition {
    
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

class JinyTaggedEvent {
    
    var orConditions:Array<Array<JinyTaggedEventCondition>> = []
    var action:String?
    
    init(withDict taggedDict:Dictionary<String,Any>) {
        action = taggedDict[constant_action] as? String
        if let eventsDictArray = taggedDict[constant_events] as? Array<Array<Dictionary<String,Any>>>{
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

class JinyAssistInfo {
    var layoutInfo:Dictionary<String,Any>
    var htmlUrl:String?
    var contentUrls:Array<String>
    var highlightClickable:Bool
    var autoScroll:Bool
    var autoFocus:Bool
    var type:String?
    var identifier:String?
    
    init(withDict infoDict:Dictionary<String,Any>) {
        layoutInfo = infoDict[constant_layoutInfo] as? Dictionary<String,Any> ?? [:]
        htmlUrl = infoDict[constant_htmlUrl] as? String
        contentUrls = infoDict[constant_contentUrls] as? Array<String> ?? []
        highlightClickable = infoDict[constant_highlightClickable] as? Bool ?? false
        autoScroll = infoDict[constant_autoScroll] as? Bool ?? false
        autoFocus = infoDict[constant_autoFocus] as? Bool ?? false
        type = infoDict[constant_type] as? String
        identifier = infoDict[constant_identifier] as? String
    }
}

class JinyFrequency {
    /// number of times a discovery is shown in a session until flow complete
    let perSession:Int?
    let perApp:Int?
    let perSessionWoJiny:Int?
    let perAppWoJiny:Int?
    let perFlow:Int?
    
    init(with dict:Dictionary<String,Int>) {
        perSession = dict[constant_perSession]
        perApp = dict[constant_perApp]
        perSessionWoJiny = dict[constant_perSessionWOJiny]
        perAppWoJiny = dict[constant_perSessionWOJiny]
        perFlow = dict[constant_perFlow]
    }
    
}

class JinyInstruction {
    
    var soundName:String?
    var assistInfo:JinyAssistInfo?
    
    init(withDict instructionDict:Dictionary<String,Any>) {
        soundName = instructionDict[constant_soundName] as? String
        if let assistInfoDict = instructionDict[constant_assistInfo] as? Dictionary<String,Any> {
            assistInfo = JinyAssistInfo(withDict: assistInfoDict)
        }
    }
    
}

