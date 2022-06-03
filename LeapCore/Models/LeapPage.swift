//
//  LeapPage.swift
//  LeapCore
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

class LeapPage: LeapContext {
    
    let previousId: Int?
    let mustHavePreviousPage: Bool?
    var stages: Array<LeapStage> = []
    
    init(withDict pageDict:Dictionary<String,Any>) {
        previousId = pageDict[constant_prevId] as? Int
        mustHavePreviousPage = pageDict[constant_mustHavePrevPage] as? Bool
        super.init(with: pageDict)
        if let stagesDictsArray = pageDict[constant_stages] as? Array<Dictionary<String, Any>> {
            for stageDict in stagesDictsArray { stages.append(LeapStage(withDict: stageDict, pageId: id)) }
        }
    }
    
    func copy(with zone: NSZone? = nil) -> LeapPage {
        let copy = LeapPage(withDict: [constant_prevId:self.previousId ?? false, constant_mustHavePrevPage:self.mustHavePreviousPage ?? -1])
        for stage in self.stages {
            copy.stages.append(stage.copy())
        }
        copy.id = self.id
        copy.name = self.name
        copy.nativeIdentifiers = self.nativeIdentifiers
        copy.webIdentifiers = self.webIdentifiers
        copy.weight = self.weight
        copy.isWeb = self.isWeb
        copy.taggedEvents = self.taggedEvents
        copy.checkpoint = self.checkpoint
        copy.trigger = self.trigger
        return copy
    }
}
