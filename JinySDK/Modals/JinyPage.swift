//
//  JinyPage.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

enum JinyPageType:String {
    case Normal = "Normal"
}


class JinyPage {
    
    let id:Int?
    let name:String?
    let isWeb:Bool
    let weight:Int
    let previousId:Int?
    let mustHavePreviousPage:Bool?
    let nativeIdentifiers:Array<String>
    let webIdentifiers:Array<String>
    var stages:Array<JinyStage> = []
    var checkpoint:Bool
    
    init(withDict pageDict:Dictionary<String,Any>) {
        id = pageDict["id"] as? Int
        name = pageDict["name"] as? String
        isWeb = pageDict["is_web"] as? Bool ?? false
        weight = pageDict["weight"] as? Int ?? 1
        previousId = pageDict["prev_id"] as? Int
        mustHavePreviousPage = pageDict["must_have_prev_page"] as? Bool
        nativeIdentifiers = pageDict["native_identifiers"] as? Array<String> ?? []
        webIdentifiers = pageDict["web_identifiers"] as? Array<String> ?? []
        if let stagesDictsArray = pageDict["stages"] as? Array<Dictionary<String,Any>> {
            for stageDict in stagesDictsArray { stages.append(JinyStage(withDict: stageDict)) }
        }
        checkpoint = pageDict["checkpoint"] as? Bool ?? false
    }
    
}

extension JinyPage:Equatable {
    
    static func == (lhs:JinyPage, rhs:JinyPage) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
}
