//
//  LeapMedia.swift
//  LeapAUI
//
//  Created by Aravind GS on 25/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation


class LeapMedia {
    
    let url:URL?
    var filename:String
    
    
    init(baseUrl:String, location:String?) {
        if location != nil { url = URL(string:baseUrl + location!)!  }
        else { url = nil }
        filename = location?.replacingOccurrences(of: "/", with: "$") ?? ""
    }
}

class LeapAUIContent:LeapMedia {
    override init(baseUrl: String, location: String?) {
        super.init(baseUrl: baseUrl, location: location)
    }
}

class LeapSound:LeapMedia {
    let name:String?
    var langCode:String?
    let isTTS:Bool
    let text:String?
    
    init(baseUrl: String, location: String?, code:String, info:Dictionary<String,Any>) {
        langCode = code
        isTTS = info[constant_isTTSEnabled] as? Bool ?? false
        text = info[constant_text] as? String
        name = info[constant_name] as? String
        super.init(baseUrl: baseUrl, location: location)
    }
}
