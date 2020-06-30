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
    
    let stageId:Int
    let stageName:String
    let stageType:JinyStageType
    let soundName:String?
    let isSuccess:Bool
    var frequencyPerFlow:Int
    var branchInfo:JinyBranchInfo?
    
    init(withStageDict stageDict:Dictionary<String,Any>) {
        stageId = stageDict["stage_id"] as? Int ?? -1
        stageName = stageDict["stage_name"] as? String ?? ""
        switch stageDict["stage_type"] as? String {
        case "NORMAL":
            stageType = .Normal
        case "MANUAL_SEQUENCE":
            stageType = .ManualSequence
        case "BRANCH":
            stageType = .Branch
        case "LINK":
            stageType = .Link
        case "SEQUENCE":
            stageType = .Sequence
        default:
            stageType = .Normal
        }
        soundName = stageDict["sound_name"] as? String
        isSuccess = stageDict["is_success"] as? Bool ?? false
        frequencyPerFlow = stageDict["frequency_per_flow"] as? Int ?? -1
        if let branchInfoDict = stageDict["branch_info"] as? Dictionary<String,Any> {
            branchInfo = JinyBranchInfo(withBranchInfo: branchInfoDict)
        }
    }
    
}

class JinyNativeStage : JinyStage {
    
    var stageIdentifiers:Array<JinyNativeIdentifer> = []
    var pointerIdentfier:JinyNativeIdentifer?
    
    override init(withStageDict stageDict: Dictionary<String, Any>) {
        if let pointerDict = stageDict["pointer_identifier"] as? Dictionary<String,Any> {
            pointerIdentfier = JinyNativeIdentifer(withDict: pointerDict)
        }
        if let stageIdDictsArray = stageDict["stage_identifiers"] as? Array<Dictionary<String,Any>> {
            for stageIdDict in stageIdDictsArray {
                stageIdentifiers.append(JinyNativeIdentifer(withDict: stageIdDict))
            }
        }
        super.init(withStageDict: stageDict)
    }
}

class JinyWebStage : JinyStage {
    
    var pointerIdentifer:JinyIdentifier?
    
    override init(withStageDict stageDict: Dictionary<String, Any>) {
        if let pointerDict = stageDict["pointer_idetifier"] as? Dictionary<String,Any> {
            pointerIdentifer = JinyIdentifier(withDict: pointerDict)
        }
        super.init(withStageDict: stageDict)
    }
}


extension JinyStage:Equatable {
    static func == (lhs:JinyStage, rhs:JinyStage) -> Bool {
        return lhs.stageId == rhs.stageId && lhs.stageName == rhs.stageName
    }
}


class JinyNewStage {
    
    let id:Int?
    let name:String?
    let isWeb:Bool
    let type:JinyStageType
    let frequencyPerFlow:Int
    let weight:Int
    let isSuccess:Bool
    let nativeIdentifiers:Array<String>
    let webIdentifiers:Array<String>
    let branchInfo:JinyBranchInfo?
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
            if let branchDict = stageDict["branch_info"] as? Dictionary<String,Any> { branchInfo = JinyBranchInfo(withBranchInfo: branchDict) }
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

extension JinyNewStage:Equatable {
    
    static func == (lhs:JinyNewStage, rhs:JinyNewStage) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
}


class JinyNewBranchInfo {
    
    let branchTitle:Dictionary<String,Any>
    let branchFlows:Array<String>
    
    init(withDict branchInfoDict:Dictionary<String,Any>) {
        branchTitle = branchInfoDict["branch_title"] as? Dictionary<String,String> ?? [:]
        branchFlows = branchInfoDict["branch_flows"] as? Array<String> ?? []
    }
    
}
