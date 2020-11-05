//
//  JinyPage.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyPage:JinyContext {
    
    let previousId:Int?
    let mustHavePreviousPage:Bool?
    var stages:Array<JinyStage> = []
    
    init(withDict pageDict:Dictionary<String,Any>) {
        previousId = pageDict["prev_id"] as? Int
        mustHavePreviousPage = pageDict["must_have_prev_page"] as? Bool
        if let stagesDictsArray = pageDict["stages"] as? Array<Dictionary<String,Any>> {
            for stageDict in stagesDictsArray { stages.append(JinyStage(withDict: stageDict)) }
        }
        super.init(with: pageDict)
    }
    
}

extension JinyPage:Equatable {
    
    static func == (lhs:JinyPage, rhs:JinyPage) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
}
