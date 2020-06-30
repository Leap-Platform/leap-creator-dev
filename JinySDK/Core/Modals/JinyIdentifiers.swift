//
//  JinyIdentifiers.swift
//  JinySDK
//
//  Created by Aravind GS on 28/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation


class JinyWebIdentifier {
    
    let tagName:String
    let attributes:Dictionary<String,String>?
    let innerHtml:Dictionary<String,String>?
    let innerText:Dictionary<String,String>?
    let value:Dictionary<String,String>?
    let url:String?
    let index:Int
    
    init(withDict webDict:Dictionary<String,Any>) {
        tagName = webDict["tag_name"] as? String ?? ""
        attributes = webDict["attributes"] as? Dictionary<String,String>
        innerHtml = webDict["innerHTML"] as? Dictionary<String,String>
        innerText = webDict["innerText"] as? Dictionary<String,String>
        value = webDict["value"] as? Dictionary<String,String>
        url = webDict["url"] as? String
        index = webDict["index"] as? Int ?? 0
    }
    
}

class JinyNativeIdentifier {
    
    
    init(withDict nativeDict:Dictionary<String,Any>) {
        
    }
    
}
