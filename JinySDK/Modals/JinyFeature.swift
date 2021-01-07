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
        enabled = ttsDict[constant_enabled] as? Bool ?? false
        if let dataDict = ttsDict[constant_data] as? Dictionary<String,Any> {
            region = dataDict[constant_region] as? String
            languages = dataDict[constant_languages] as? Dictionary<String,String>
        }
    }
}

class JinyFeature {
    var tts:JinyTTS?
    
    init(withDict featureDict:Dictionary<String,Any>) {
        if let ttsDict = featureDict[constant_tts] as? Dictionary<String,Any> {
            tts = JinyTTS(withDict: ttsDict)
        }
    }
}
