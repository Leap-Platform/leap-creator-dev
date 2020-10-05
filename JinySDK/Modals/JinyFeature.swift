//
//  JinyFeature.swift
//  JinySDK
//
//  Created by Aravind GS on 28/08/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation


class JinyTTS {
    let enabled:Bool
    var region:String?
    var languages:Dictionary<String,String>?
    
    init(withDict ttsDict:Dictionary<String,Any>) {
        enabled = ttsDict["enabled"] as? Bool ?? false
        if let dataDict = ttsDict["data"] as? Dictionary<String,Any> {
            region = dataDict["region"] as? String
            languages = dataDict["languages"] as? Dictionary<String,String>
        }
    }
}

class JinyFeature {
    var tts:JinyTTS?
    
    init(withDict featureDict:Dictionary<String,Any>) {
        if let ttsDict = featureDict["tts"] as? Dictionary<String,Any> {
            tts = JinyTTS(withDict: ttsDict)
        }
    }
}
