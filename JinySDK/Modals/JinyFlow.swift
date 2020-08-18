//
//  JinyFlow.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyFlow {
    
    var id:Int?
    var name:String?
    var flowText:Dictionary<String,String> = [:]
    var pages:Array<JinyPage> = []
    
    init(withDict flowDict:Dictionary<String,Any>) {
        id = flowDict["id"] as? Int
        name = flowDict["name"] as? String
        flowText = flowDict["flow_title"] as? Dictionary<String,String> ?? [:]
        if let pageDictsArray = flowDict["pages"] as? Array<Dictionary<String,Any>> {
            for pageDict in pageDictsArray { pages.append(JinyPage(withDict: pageDict)) }
        }
    }
    
    func copy(with zone: NSZone? = nil) -> JinyFlow {
        let copy = JinyFlow(withDict: [:])
        copy.id = self.id
        copy.name = self.name
        copy.flowText = self.flowText
        copy.pages = self.pages
        return copy
    }
    
}
