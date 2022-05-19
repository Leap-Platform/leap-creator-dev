//
//  LeapContext.swift
//  LeapCore
//
//  Created by Aravind GS on 05/11/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

class LeapContext {
    
    var id:Int
    var name:String
    var nativeIdentifiers:Array<String> = []
    var webIdentifiers:Array<String> = []
    var weight:Int
    var isWeb:Bool
    var taggedEvents:LeapTaggedEvent?
    var checkpoint:Bool
    var instruction:LeapInstruction?
    var instructionInfoDict:Dictionary<String,Any>?
    var trigger: LeapTrigger?
    
    init(with dict: Dictionary<String, Any>) {
        id = dict[constant_id] as? Int ?? -1
        name = dict[constant_name] as? String ?? ""
        nativeIdentifiers = dict[constant_nativeIdentifiers] as? Array<String> ?? []
        webIdentifiers = dict[constant_webIdentifiers] as? Array<String> ?? []
        weight = dict[constant_weight] as? Int ?? 1
        isWeb = dict[constant_isWeb] as? Bool ?? false
        if let taggedEventsDict = dict[constant_taggedEvents] as? Dictionary<String,Any> {
            taggedEvents = LeapTaggedEvent(withDict: taggedEventsDict)
        }
        if let instructionDict = dict[constant_instruction] as? Dictionary<String,Any>{
            instruction = LeapInstruction(withDict: instructionDict)
            instructionInfoDict = instructionDict
        }
        if let trigger = dict[constant_trigger] as? Dictionary<String, Any> {
            self.trigger = LeapTrigger(with: trigger)
        }
        checkpoint = dict[constant_checkPoint] as? Bool ?? false
    }
}


extension LeapContext:Equatable {
    
    static func == (lhs:LeapContext, rhs:LeapContext) -> Bool {
        if let lstage = lhs as? LeapStage, let rStage = rhs as? LeapStage {
            return lstage.id == rStage.id && lstage.name == rStage.name && lstage.page == rStage.page
        }
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
}
