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
