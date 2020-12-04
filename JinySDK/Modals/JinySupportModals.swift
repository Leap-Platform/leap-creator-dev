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
        layoutInfo = infoDict["layout_info"] as? Dictionary<String,Any> ?? [:]
        htmlUrl = infoDict["html_url"] as? String
        contentUrls = infoDict["content_urls"] as? Array<String> ?? []
        highlightClickable = infoDict["highlight_clickable"] as? Bool ?? false
        autoScroll = infoDict["auto_scroll"] as? Bool ?? false
        autoFocus = infoDict["auto_focus"] as? Bool ?? false
        type = infoDict["type"] as? String
        identifier = infoDict["identifier"] as? String
    }
}

class JinyFrequency {
    let perSession:Int?
    let perApp:Int?
    let perSessionWoJiny:Int?
    let perAppWoJiny:Int?
    let perFlow:Int?
    
    init(with dict:Dictionary<String,Int>) {
        perSession = dict["perSession"]
        perApp = dict["perApp"]
        perSessionWoJiny = dict["per_session_wo_jiny"]
        perAppWoJiny = dict["per_app_wo_jiny"]
        perFlow = dict["per_flow"]
    }
    
}

class JinyInstruction {
    
    var soundName:String?
    var assistInfo:JinyAssistInfo?
    
    init(withDict instructionDict:Dictionary<String,Any>) {
        soundName = instructionDict["sound_name"] as? String
        if let assistInfoDict = instructionDict["assist_info"] as? Dictionary<String,Any> {
            assistInfo = JinyAssistInfo(withDict: assistInfoDict)
        }
    }
    
}

