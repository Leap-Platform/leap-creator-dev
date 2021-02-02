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
        id = flowDict[constant_id] as? Int
        name = flowDict[constant_name] as? String
        flowText = flowDict[constant_flowTitle] as? Dictionary<String,String> ?? [:]
        if let pageDictsArray = flowDict[constant_pages] as? Array<Dictionary<String,Any>> {
            for pageDict in pageDictsArray { pages.append(JinyPage(withDict: pageDict)) }
        }
    }
    
    func copy(with zone: NSZone? = nil) -> JinyFlow {
        let copy = JinyFlow(withDict: [:])
        copy.id = self.id
        copy.name = self.name
        copy.flowText = self.flowText
        for page in self.pages {
            copy.pages.append(page.copy())
        }
        return copy
    }
    
}

extension JinyFlow:Equatable {
    
    static func == (lhs:JinyFlow, rhs:JinyFlow) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
}
