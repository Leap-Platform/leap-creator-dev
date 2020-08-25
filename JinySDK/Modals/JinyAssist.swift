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


class JinyAssist {
    
    var assistId:Int
    var name:String?
    var type:String?
    var weight:Int
    var frequencyPerSession:Int
    var frequencyPerApp:Int
    var nativeIdentifiers:Array<String>
    var webIdentifiers:Array<String>
    var eventIdentifiers:Dictionary<String,Any>
    var instructions:Dictionary<String,Any>
    var isWeb:Bool
    
    init(withDict assistDict:Dictionary<String,Any>) {
        assistId = assistDict["id"] as? Int ?? -1
        name = assistDict["name"] as? String ?? ""
        type = assistDict["type"] as? String
        weight = assistDict["weight"] as? Int ?? 1
        if let frequencyDict = assistDict["frequency"] as? Dictionary<String,Int> {
            frequencyPerSession = frequencyDict["per_session"] ?? -1
            frequencyPerApp = frequencyDict["per_session"] ?? -1
        } else {
            frequencyPerSession = -1
            frequencyPerApp = -1
        }
        nativeIdentifiers = assistDict["native_identifiers"] as? Array<String> ?? []
        webIdentifiers = assistDict["web_identifiers"] as? Array<String> ?? []
        eventIdentifiers = assistDict["event_identifiers"] as? Dictionary<String,Any> ?? [:]
        isWeb = assistDict["is_web"] as? Bool ?? false
        instructions = assistDict["instruction"] as? Dictionary<String,Any> ?? [:]
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
        copy.instructions = self.instructions
        return copy
    }
    
}
