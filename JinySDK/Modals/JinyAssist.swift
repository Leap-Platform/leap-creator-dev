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




class JinyAssist:JinyContext {
    
    var type:String
    var frequency:JinyFrequency?
    var instruction:JinyInstruction?
    var instructionInfoDict:Dictionary<String,Any>?
    var trigger: JinyTrigger?
    
    init(withDict assistDict:Dictionary<String,Any>) {
        type = assistDict["type"] as? String ?? "NORMAL"
        if let frequencyDict = assistDict["frequency"] as? Dictionary<String,Int> {
            frequency = JinyFrequency(with: frequencyDict)
        }
        if let trigger = assistDict["trigger"] as? Dictionary<String, String> {
            self.trigger = JinyTrigger(with: trigger)
        }
        if let instructionDict = assistDict["instruction"] as? Dictionary<String,Any>{
            instruction = JinyInstruction(withDict: instructionDict)
            instructionInfoDict = instructionDict
        }
        super.init(with: assistDict)
    }
}


extension JinyAssist:Equatable {
    
    static func == (lhs:JinyAssist, rhs:JinyAssist)-> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
}

extension JinyAssist {
    
    func copy(with zone: NSZone? = nil) -> JinyAssist {
        let copy = JinyAssist(withDict: [:])
        copy.id = self.id
        copy.name = self.name
        copy.webIdentifiers = self.webIdentifiers
        copy.nativeIdentifiers = self.nativeIdentifiers
        copy.weight = self.weight
        copy.type = self.type
        copy.isWeb = self.isWeb
        copy.taggedEvents = self.taggedEvents
        copy.checkpoint = self.checkpoint
        copy.type = self.type
        copy.frequency = self.frequency
        copy.instruction = self.instruction
        copy.instructionInfoDict = self.instructionInfoDict
        return copy
    }
    
}
