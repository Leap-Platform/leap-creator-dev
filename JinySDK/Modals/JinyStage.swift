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
    let frequencyPerFlow:Int
    let isSuccess:Bool
    let branchInfo:JinyBranchInfo?
    let instruction:JinyInstruction?
    let instructionInfoDict:Dictionary<String,Any>?
    
    init(withDict stageDict:Dictionary<String,Any>) {
        
        let typeString = (stageDict["type"] as? String)?.uppercased() ?? "NORMAL"
        type = JinyStageType(rawValue: typeString) ?? .Normal
        frequencyPerFlow = stageDict["frequency_per_flow"] as? Int ?? -1
        isSuccess = stageDict["is_success"] as? Bool ?? false
        if let branchDict = stageDict["branch_info"] as? Dictionary<String,Any> {
            branchInfo = JinyBranchInfo(withDict: branchDict)
        } else { branchInfo = nil }
        if let instructionDict = stageDict["instruction"] as? Dictionary<String,Any> {
            instruction = JinyInstruction(withDict: instructionDict)
            instructionInfoDict = instructionDict
        } else {
            instruction = nil
            instructionInfoDict = nil
        }
        super.init(with: stageDict)
    }
    
    func copy(with zone: NSZone? = nil) -> JinyStage {
        let copy = JinyStage(withDict: ["type":self.type.rawValue, "frequency_per_flow":self.frequencyPerFlow, "is_success":self.isSuccess, "branch_info":self.branchInfo ?? [:], "instruction":self.instructionInfoDict ?? [:]])
        copy.id = self.id
        copy.name = self.name
        copy.nativeIdentifiers = self.nativeIdentifiers
        copy.webIdentifiers = self.webIdentifiers
        copy.weight = self.weight
        copy.isWeb = self.isWeb
        copy.taggedEvents = self.taggedEvents
        copy.checkpoint = self.checkpoint
        return copy
    }
}

extension JinyStage:Equatable {
    
    static func == (lhs:JinyStage, rhs:JinyStage) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
}


class JinyBranchInfo {
    
    let branchTitle:Dictionary<String,Any>
    let branchFlows:Array<Int>
    
    init(withDict branchInfoDict:Dictionary<String,Any>) {
        branchTitle = branchInfoDict["branch_title"] as? Dictionary<String,String> ?? [:]
        branchFlows = branchInfoDict["branch_flows"] as? Array<Int> ?? []
    }
    
}
