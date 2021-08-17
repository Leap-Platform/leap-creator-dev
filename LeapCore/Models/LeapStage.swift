//
//  LeapStage.swift
//  LeapCore
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

enum LeapStageType:String {
    case Normal = "NORMAL"
    case Sequence = "SEQUENCE"
    case ManualSequence = "MANUAL_SEQUENCE"
}

enum LeapPointerType {
    case None
    case Normal
    case NegativeUI
}

enum LeapSearchType {
    case None
    case AccID
    case AccLabel
    case Tag
}


class LeapStageTransition {
    var prev:String?
    var next:String?
    
    init(with transitionDict:Dictionary<String,Any>) {
        prev = transitionDict[constant_prev] as? String
        next = transitionDict[constant_next] as? String
    }
}

class LeapStage:LeapContext {

    let type:LeapStageType
    let isSuccess:Bool
    let branchInfo:LeapBranchInfo?
    var terminationFrequency:LeapFlowTerminationFrequency?
    var page:Int
    var transition:LeapStageTransition?
    
    init(withDict stageDict:Dictionary<String,Any>, pageId:Int) {
        
        let typeString = (stageDict[constant_type] as? String)?.uppercased() ?? "NORMAL"
        type = LeapStageType(rawValue: typeString) ?? .Normal
        isSuccess = stageDict[constant_isSuccess] as? Bool ?? false
        if let branchDict = stageDict[constant_branchInfo] as? Dictionary<String,Any> {
            branchInfo = LeapBranchInfo(withDict: branchDict)
        } else { branchInfo = nil }
        if let frequencyDict = stageDict[constant_frequency] as? Dictionary<String,Int> {
            terminationFrequency = LeapFlowTerminationFrequency(with: frequencyDict)
        }
        page = pageId
        if let transitionDict = stageDict[constant_transition] as? Dictionary<String,Any> {
            transition = LeapStageTransition(with: transitionDict)
        }
        super.init(with: stageDict)
    }
    
    func copy(with zone: NSZone? = nil) -> LeapStage {
        let copy = LeapStage(withDict: [constant_type:self.type.rawValue, constant_isSuccess:self.isSuccess, constant_branchInfo:self.branchInfo ?? [:], constant_instruction:self.instructionInfoDict ?? [:]], pageId: 0)
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
        copy.page = self.page
        copy.transition = self.transition
        return copy
    }
}

class LeapBranchInfo {
    
    let branchTitle:Dictionary<String,Any>
    let branchFlows:Array<Int>
    
    init(withDict branchInfoDict:Dictionary<String,Any>) {
        branchTitle = branchInfoDict[constant_branchTitle] as? Dictionary<String,String> ?? [:]
        branchFlows = branchInfoDict[constant_branchFlows] as? Array<Int> ?? []
    }
    
}
