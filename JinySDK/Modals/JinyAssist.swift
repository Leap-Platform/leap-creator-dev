//
//  JinyAssist.swift
//  JinySDK
//
//  Created by Aravind GS on 22/08/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

//{
//    "id": 1,
//    "name": "",
//    "type": "",
//    "weight": 1,
//    "frequency": {
//        "per_session": 1,
//        "per_app": 1
//    },
//    "event_identifiers": {
//        "triggerOnAnchorClick": true,
//        "delay": 5000
//    },
//    "is_web": true,
//    "native_identifiers": [
//        "JD1"
//    ],
//    "web_identifiers": [
//        "JD1"
//    ],
//    "instruction": {
//        "sound_name": "",
//        "assist_info": {
//            "layout_info": {
//                "enter_animation": "zoom_in",
//                "exit_animation": "slide_bottom",
//                "style": {
//                    "alpha": 0.7
//                },
//                "dismiss_action": {
//                    "outside_dismiss": true
//                },
//                "auto_dismiss_delay": 4000
//            },
//            "html_url": "testing/tooltip_anim.gz",
//            "content_urls": [
//                "testing/clock.svg"
//            ],
//            "highlight_clickable": true,
//            "auto_scroll": true,
//            "auto_focus": false,
//            "type": "TOOLTIP",
//            "identifier": "JD1"
//        }
//    }
//}


class JinyAssistEventIdentifiers {
    
    var triggerOnAnchorClick:Bool
    var delay:Float?
    
    init(withDict eventDict:Dictionary<String,Any>) {
        triggerOnAnchorClick = eventDict["triggerOnAnchorClick"] as? Bool ?? false
        delay = eventDict["delay"] as? Float
    }
    
}

class JinyAssistInfo {
    var layoutInfo:Dictionary<String,Any>
    var htmlUrl:String?
    var contentUrls:Array<String>
    var highlightClickable:Bool
    var autoScroll:Bool
    var autoFocus:Bool
    var type:JinyPointerStyle?
    var identifier:String?
    
    init(withDict infoDict:Dictionary<String,Any>) {
        layoutInfo = infoDict["layout_info"] as? Dictionary<String,Any> ?? [:]
        htmlUrl = infoDict["html_url"] as? String
        contentUrls = infoDict["content_urls"] as? Array<String> ?? []
        highlightClickable = infoDict["highlight_clickable"] as? Bool ?? false
        autoScroll = infoDict["auto_scroll"] as? Bool ?? false
        autoFocus = infoDict["auto_focus"] as? Bool ?? false
        type = .FingerRipple
        identifier = infoDict["identifier"] as? String
    }
}

class JinyAssistInstruction {
    var soundName:String
    var assistInfo:JinyAssistInfo?
    
    init(withDict instructionDict:Dictionary<String,Any>) {
        soundName = instructionDict["sound_name"] as? String ?? ""
        if let assistInfoDict = instructionDict["assist_info"] as? Dictionary<String,Any> {
            assistInfo = JinyAssistInfo(withDict: assistInfoDict)
        }
    }
    
}

class JinyAssist {
    
    var assistId:Int
    var name:String?
    var type:String?
    var weight:Int
    var checkPoint:Bool
    var frequencyPerSession:Int
    var frequencyPerApp:Int
    var nativeIdentifiers:Array<String>
    var webIdentifiers:Array<String>
    var eventIdentifiers:JinyAssistEventIdentifiers?
    var instruction:JinyAssistInstruction?
    var isWeb:Bool
    var instructionInfoDict:Dictionary<String,Any>?
    
    
    init(withDict assistDict:Dictionary<String,Any>) {
        assistId = assistDict["id"] as? Int ?? -1
        name = assistDict["name"] as? String ?? ""
        type = assistDict["type"] as? String
        weight = assistDict["weight"] as? Int ?? 1
        checkPoint = assistDict["checkpoint"] as? Bool ?? false
        if let frequencyDict = assistDict["frequency"] as? Dictionary<String,Int> {
            frequencyPerSession = frequencyDict["per_session"] ?? -1
            frequencyPerApp = frequencyDict["per_session"] ?? -1
        } else {
            frequencyPerSession = -1
            frequencyPerApp = -1
        }
        nativeIdentifiers = assistDict["native_identifiers"] as? Array<String> ?? []
        webIdentifiers = assistDict["web_identifiers"] as? Array<String> ?? []
        if let eventDict = assistDict["event_identifiers"] as? Dictionary<String,Any> {
            eventIdentifiers = JinyAssistEventIdentifiers(withDict: eventDict)
        }
        isWeb = assistDict["is_web"] as? Bool ?? false
        if let instructionDict = assistDict["instruction"] as? Dictionary<String,Any>{
            instruction = JinyAssistInstruction(withDict: instructionDict)
            instructionInfoDict = instructionDict
        }
    }
}


extension JinyAssist:Equatable {
    
    static func == (lhs:JinyAssist, rhs:JinyAssist)-> Bool {
        return lhs.assistId == rhs.assistId && lhs.name == rhs.name
    }
    
}

extension JinyAssist {
    
    func copy(with zone: NSZone? = nil) -> JinyAssist {
        let copy = JinyAssist(withDict: [:])
        copy.assistId = self.assistId
        copy.name = self.name
        copy.type = self.type
        copy.isWeb = self.isWeb
        copy.weight = self.weight
        copy.frequencyPerApp = self.frequencyPerApp
        copy.frequencyPerSession = self.frequencyPerSession
        copy.eventIdentifiers = self.eventIdentifiers
        copy.webIdentifiers = self.webIdentifiers
        copy.nativeIdentifiers = self.nativeIdentifiers
        copy.instruction = self.instruction
        copy.instructionInfoDict = self.instructionInfoDict
        return copy
    }
    
}
