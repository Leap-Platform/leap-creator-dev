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
