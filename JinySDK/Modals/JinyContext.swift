//
//  JinyContext.swift
//  JinySDK
//
//  Created by Aravind GS on 05/11/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyContext {
    
    var id:Int
    var name:String
    var nativeIdentifiers:Array<String> = []
    var webIdentifiers:Array<String> = []
    var weight:Int
    var isWeb:Bool
    var taggedEvents:JinyTaggedEvent?
    var checkpoint:Bool
    
    init(with dict:Dictionary<String,Any>) {
        id = dict["id"] as? Int ?? -1
        name = dict["name"] as? String ?? ""
        nativeIdentifiers = dict["nativeIdentifiers"] as? Array<String> ?? []
        webIdentifiers = dict["webIdentifiers"] as? Array<String> ?? []
        weight = dict["weight"] as? Int ?? 1
        isWeb = dict["isWeb"] as? Bool ?? false
        if let taggedEventsDict = dict["taggedEvents"] as? Dictionary<String,Any> {
            taggedEvents = JinyTaggedEvent(withDict: taggedEventsDict)
        }
        checkpoint = dict["checkpoint"] as? Bool ?? false
    }
}
