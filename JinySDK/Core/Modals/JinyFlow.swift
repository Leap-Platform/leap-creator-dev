//
//  JinyFlow.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation


class JinyFlow {
    
    var flowId:Int
    var flowName:String
    var flowOptions:Dictionary<String,Any>
    var nativePages:Array<JinyNativePage> = []
    var webPages:Array<JinyWebPage> = []
    
    init(withFlowDict flowDict:Dictionary<String, Any>) {
        flowId = flowDict["flow_id"] as? Int ?? -1
        flowName = flowDict["flow_name"] as? String ?? ""
        flowOptions = flowDict["flow_options"] as? Dictionary<String, Any> ?? [:]
        if let nativePagesDictArray = flowDict["jiny_native_pages"] as? Array<Dictionary<String,Any>> {
            for nativePagesDict in nativePagesDictArray {
                let nativePage = JinyNativePage(withPageDict: nativePagesDict)
                nativePages.append(nativePage)
            }
        }
        if let webPagesDictArray = flowDict["jiny_web_pages"] as? Array<Dictionary<String,Any>> {
            for webPagesDict in webPagesDictArray {
                let webPage = JinyWebPage(withPageDict: webPagesDict)
                webPages.append(webPage)
            }
        }
        
    }
    
    func copy(with zone: NSZone? = nil) -> JinyFlow {
        let copy = JinyFlow(withFlowDict: [:])
        copy.flowId = self.flowId
        copy.flowName = self.flowName
        copy.flowOptions = self.flowOptions
        copy.nativePages = self.nativePages
        copy.webPages = self.webPages
        return copy
    }
}


class JinyNewFlow {
    
    var id:String?
    var name:String?
    var flowText:Dictionary<String,String> = [:]
    var pages:Array<JinyPageObject> = []
    
    init(withDict flowDict:Dictionary<String,Any>) {
        id = flowDict["id"] as? String
        name = flowDict["name"] as? String
        flowText = flowDict["flow_title"] as? Dictionary<String,String> ?? [:]
        if let pageDictsArray = flowDict["pages"] as? Array<Dictionary<String,Any>> {
            for pageDict in pageDictsArray { pages.append(JinyPageObject(withDict: pageDict)) }
        }
    }
    
    func copy(with zone: NSZone? = nil) -> JinyNewFlow {
        let copy = JinyNewFlow(withDict: [:])
        copy.id = self.id
        copy.name = self.name
        copy.flowText = self.flowText
        copy.pages = self.pages
        return copy
    }
    
}
