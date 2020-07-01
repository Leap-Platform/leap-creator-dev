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
    let pageId:Int
    let pageName:String
    let pageType:JinyPageType
    var shouldCheckPreviousId:Bool
    
    
    init(withPageDict pageDict:Dictionary<String,Any>) {
        pageId = pageDict["page_id"] as? Int ?? -1
        pageName = pageDict["page_name"] as? String ?? ""
        pageType = .Normal
        shouldCheckPreviousId = pageDict["should_check_prev_id"] as? Bool ?? false
    }
}

class JinyNativePage : JinyPage {
    
    var pageIdentifers:Array<JinyNativeIdentifer> = []
    var nativeStages:Array<JinyNativeStage> = []
    
    override init(withPageDict pageDict: Dictionary<String, Any>) {
        super.init(withPageDict: pageDict)
        if let pageIdDictsArrays = pageDict["page_identifiers"] as? Array<Array<Dictionary<String,Any>>> {
            for pageIdDictArray in pageIdDictsArrays {
                for pageIdDict in pageIdDictArray {
                    pageIdentifers.append(JinyNativeIdentifer(withDict: pageIdDict))
                }
            }
        }
        if let nativeStagesDictArray = pageDict["jiny_native_stages"] as? Array<Dictionary<String,Any>> {
            for nativeStageDict in nativeStagesDictArray {
                nativeStages.append(JinyNativeStage(withStageDict: nativeStageDict))
            }
        }
    }
}

class JinyWebPage : JinyPage {
    var pageIdentifers:Array<String>?
    var webStages:Array<JinyWebStage> = []
    override init(withPageDict pageDict: Dictionary<String, Any>) {
        pageIdentifers = pageDict["page_identifiers"] as? Array<String>
        super.init(withPageDict: pageDict)
    }
}


class JinyPageObject {
    
    let id:Int?
    let name:String?
    let isWeb:Bool
    let weight:Int
    let previousId:Int?
    let mustHavePreviousPage:Bool?
    let nativeIdentifiers:Array<String>
    let webIdentifiers:Array<String>
    var stages:Array<JinyNewStage> = []
    
    
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
            for stageDict in stagesDictsArray { stages.append(JinyNewStage(withDict: stageDict)) }
        }
        
    }
    
}

extension JinyPageObject:Equatable {
    
    static func == (lhs:JinyPageObject, rhs:JinyPageObject) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
}
