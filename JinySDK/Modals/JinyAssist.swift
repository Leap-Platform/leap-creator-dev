//
//  JinyAssist.swift
//  JinySDK
//
//  Created by Aravind GS on 22/08/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyAssist:JinyContext {
    
    var type:String
    var terminationFrequency:JinyFlowTerminationFrequency?
    
    init(withDict assistDict:Dictionary<String,Any>) {
        type = assistDict[constant_type] as? String ?? "NORMAL"
        if let terminationFrequencyDict = assistDict[constant_terminationFrequency] as? Dictionary<String,Int> {
            terminationFrequency = JinyFlowTerminationFrequency(with: terminationFrequencyDict)
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
        copy.trigger = self.trigger
        copy.terminationFrequency = self.terminationFrequency
        copy.instruction = self.instruction
        copy.instructionInfoDict = self.instructionInfoDict
        return copy
    }
    
}
