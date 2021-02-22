//
//  LeapAssist.swift
//  LeapCore
//
//  Created by Aravind GS on 22/08/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

class LeapAssist:LeapContext {
    
    var type:String
    var terminationFrequency:LeapFlowTerminationFrequency?
    var localeCode:String
    
    init(withDict assistDict:Dictionary<String,Any>) {
        type = assistDict[constant_type] as? String ?? "NORMAL"
        localeCode = assistDict[constant_localeCode]  as? String ?? ""
        if let terminationFrequencyDict = assistDict[constant_terminationFrequency] as? Dictionary<String,Int> {
            terminationFrequency = LeapFlowTerminationFrequency(with: terminationFrequencyDict)
        }
        super.init(with: assistDict)
        
    }
}

extension LeapAssist {
    
    func copy(with zone: NSZone? = nil) -> LeapAssist {
        let copy = LeapAssist(withDict: [:])
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
        copy.trigger = self.trigger
        copy.terminationFrequency = self.terminationFrequency
        copy.instruction = self.instruction
        copy.instructionInfoDict = self.instructionInfoDict
        copy.localeCode = self.localeCode
        return copy
    }
    
}
