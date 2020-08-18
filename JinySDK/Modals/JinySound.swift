//
//  JinySound.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation


class JinySound {
    let name:String
    let langCode:String
    var url:URL?
    let version:Int
    let updatedAt:Date
    var text:String?
    
    init(withSoundDict dict:Dictionary<String,Any>, langCode code:String, baseUrl:String?) {
        name = dict["name"] as? String ?? ""
        langCode = code
        let urlFromDict = dict["url"] as? String ?? ""
        let urlString = (baseUrl ?? "") + urlFromDict
        url = URL(string: urlString)
        if let textString = dict["text"] as? String {
            text = textString
        }
        version = dict["version"] as? Int ?? -1
        updatedAt = (dict["updated_at"] as? String)?.toDate() ?? Date()
    }
}
