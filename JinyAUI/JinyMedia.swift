//
//  JinyMedia.swift
//  JinyAUI
//
//  Created by Aravind GS on 25/09/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation


class JinyMedia {
    
    let url:URL
    var name:String
    
    
    init(baseUrl:String, location:String) {
        url = URL(string:baseUrl + location)!
        name = location.replacingOccurrences(of: "/", with: "$")
    }
}

class JinyAUIContent:JinyMedia {
    override init(baseUrl: String, location: String) {
        super.init(baseUrl: baseUrl, location: location)
    }
}

class JinySound:JinyMedia {
    
    var langCode:String?
    
    init(baseUrl: String, location: String, code:String, info:Dictionary<String,Any>) {
        langCode = code
        super.init(baseUrl: baseUrl, location: location)
        if let newName = info["name"] as? String { name = newName }
    }
}
