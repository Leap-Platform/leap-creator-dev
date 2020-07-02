//
//  JinyStage.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

enum JinyStageType:String {
    case Normal = "Normal"
    case Sequence = "Sequence"
    case ManualSequence = "Manual Sequence"
    case Branch = "Branch"
    case Link = "Link"
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


class JinyStage {
    
    let id:Int?
    let name:String?
    let isWeb:Bool
    let type:JinyStageType
    let frequencyPerFlow:Int
    let weight:Int
    let isSuccess:Bool
    let nativeIdentifiers:Array<String>
    let webIdentifiers:Array<String>
    let branchInfo:JinyNewBranchInfo?
    let instruction:JinyInstruction?
    
    init(withDict stageDict:Dictionary<String,Any>) {
        
        id = stageDict["id"] as? Int
        name = stageDict["name"] as? String
        isWeb = stageDict["is_web"] as? Bool ?? false
        if let typeString = stageDict["type"] as? String { type = JinyStageType(rawValue: typeString) ?? .Normal }
        else { type = .Normal }
        frequencyPerFlow = stageDict["frequency_per_flow"] as? Int ?? -1
        weight = stageDict["weight"] as? Int ?? 1
        isSuccess = stageDict["is_success"] as? Bool ?? false
        nativeIdentifiers = stageDict["native_identifiers"] as? Array<String> ?? []
        webIdentifiers = stageDict["web_identifiers"] as? Array<String> ?? []
        
        if type == .Branch {
            if let branchDict = stageDict["branch_info"] as? Dictionary<String,Any> { branchInfo = JinyNewBranchInfo(withDict: branchDict) }
            else { branchInfo = nil }
        }
        else { branchInfo = nil }
        if let instructionDict = stageDict["instruction"] as? Dictionary<String,Any> {
            instruction = JinyInstruction(withDict: instructionDict)
        } else {
            instruction = nil
        }
    }
    
}

extension JinyStage:Equatable {
    
    static func == (lhs:JinyStage, rhs:JinyStage) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
}


class JinyNewBranchInfo {
    
    let branchTitle:Dictionary<String,Any>
    let branchFlows:Array<Int>
    
    init(withDict branchInfoDict:Dictionary<String,Any>) {
        branchTitle = branchInfoDict["branch_title"] as? Dictionary<String,String> ?? [:]
        branchFlows = branchInfoDict["branch_flows"] as? Array<Int> ?? []
    }
    
}
