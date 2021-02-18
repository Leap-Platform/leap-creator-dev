//
//  JinyStage.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

enum JinyStageType:String {
    case Normal = "NORMAL"
    case Sequence = "SEQUENCE"
    case ManualSequence = "MANUAL_SEQUENCE"
}

enum JinyPointerType {
    case None
    case Normal
    case NegativeUI
}

enum JinySearchType {
    case None
    case AccID
    case AccLabel
    case Tag
}


class JinyStage:JinyContext {

    let type:JinyStageType
    let isSuccess:Bool
    let branchInfo:JinyBranchInfo?
    var terminationFrequency:JinyFlowTerminationFrequency?
    
    init(withDict stageDict:Dictionary<String,Any>) {
        
        let typeString = (stageDict[constant_type] as? String)?.uppercased() ?? "NORMAL"
        type = JinyStageType(rawValue: typeString) ?? .Normal
        isSuccess = stageDict[constant_isSuccess] as? Bool ?? false
        if let branchDict = stageDict[constant_branchInfo] as? Dictionary<String,Any> {
            branchInfo = JinyBranchInfo(withDict: branchDict)
        } else { branchInfo = nil }
        if let frequencyDict = stageDict[constant_frequency] as? Dictionary<String,Int> {
            terminationFrequency = JinyFlowTerminationFrequency(with: frequencyDict)
        }
        super.init(with: stageDict)
    }
    
    func copy(with zone: NSZone? = nil) -> JinyStage {
        let copy = JinyStage(withDict: [constant_type:self.type.rawValue, constant_isSuccess:self.isSuccess, constant_branchInfo:self.branchInfo ?? [:], constant_instruction:self.instructionInfoDict ?? [:]])
        copy.id = self.id
        copy.name = self.name
        copy.nativeIdentifiers = self.nativeIdentifiers
        copy.webIdentifiers = self.webIdentifiers
        copy.weight = self.weight
        copy.isWeb = self.isWeb
        copy.taggedEvents = self.taggedEvents
        copy.checkpoint = self.checkpoint
        copy.instruction = self.instruction
        copy.instructionInfoDict = self.instructionInfoDict
        copy.trigger = self.trigger
        copy.terminationFrequency = self.terminationFrequency
        return copy
    }
}

class JinyBranchInfo {
    
    let branchTitle:Dictionary<String,Any>
    let branchFlows:Array<Int>
    
    init(withDict branchInfoDict:Dictionary<String,Any>) {
        branchTitle = branchInfoDict[constant_branchTitle] as? Dictionary<String,String> ?? [:]
        branchFlows = branchInfoDict[constant_branchFlows] as? Array<Int> ?? []
    }
    
}
