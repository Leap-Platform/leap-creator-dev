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
    var format:String = "mp3"
    let isTTS:Bool
    let text:String?
    
    init(baseUrl: String, location: String, code:String, info:Dictionary<String,Any>) {
        langCode = code
        let nameArray = location.split(separator: ".")
        isTTS = info["isTTSEnabled"] as? Bool ?? false
        text = info["text"] as? String
        if nameArray.count == 2 { format = String(nameArray[1]) }
        super.init(baseUrl: baseUrl, location: location)
        if let newName = info[constant_name] as? String { name = newName }
    }
}
