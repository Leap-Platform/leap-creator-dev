//
//  JinyContext.swift
//  JinySDK
//
//  Created by Aravind GS on 05/11/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyContext {
    
    var id:Int
    var name:String
    var nativeIdentifiers:Array<String> = []
    var webIdentifiers:Array<String> = []
    var weight:Int
    var isWeb:Bool
    var taggedEvents:JinyTaggedEvent?
    var checkpoint:Bool
    var instruction:JinyInstruction?
    var instructionInfoDict:Dictionary<String,Any>?
    var trigger: JinyTrigger?
    
    init(with dict:Dictionary<String,Any>) {
        id = dict[constant_id] as? Int ?? -1
        name = dict[constant_name] as? String ?? ""
        nativeIdentifiers = dict[constant_nativeIdentifiers] as? Array<String> ?? []
        webIdentifiers = dict[constant_webIdentifiers] as? Array<String> ?? []
        weight = dict[constant_weight] as? Int ?? 1
        isWeb = dict[constant_isWeb] as? Bool ?? false
        if let taggedEventsDict = dict[constant_taggedEvents] as? Dictionary<String,Any> {
            taggedEvents = JinyTaggedEvent(withDict: taggedEventsDict)
        }
        if let instructionDict = dict[constant_instruction] as? Dictionary<String,Any>{
            instruction = JinyInstruction(withDict: instructionDict)
            instructionInfoDict = instructionDict
        }
        if let trigger = dict[constant_trigger] as? Dictionary<String, Any> {
            self.trigger = JinyTrigger(with: trigger)
        }
        checkpoint = dict[constant_checkPoint] as? Bool ?? false
    }
}


extension JinyContext:Equatable {
    
    static func == (lhs:JinyContext, rhs:JinyContext) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
}
