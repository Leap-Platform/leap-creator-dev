//
//  JinyLanguage.swift
//  JinySDK
//
//  Created by Aravind GS on 16/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyLanguage {
    
    var localeId:String
    var name:String
    var script:String
    var muteText:String
    var repeatText:String
    var changeLanguageText:String
    var ttsInfo:JinyTTSInfo?
    
    init(withLanguageDict dict:Dictionary<String, Any>) {
        localeId = dict[constant_localeId] as? String ?? ""
        name = dict[constant_localeName] as? String ?? ""
        script = dict[constant_localeScript] as? String ?? ""
        muteText = dict[constant_muteText] as? String ?? ""
        repeatText = dict[constant_repeatText] as? String ?? ""
        changeLanguageText = dict[constant_changeLanguageText] as? String ?? ""
        if let ttsDict = dict[constant_ttsInfo] as? Dictionary<String,String> { ttsInfo = JinyTTSInfo(ttsDict) }
    }
    
}

extension JinyLanguage:Equatable {
    
    static func == (lhs:JinyLanguage, rhs:JinyLanguage) -> Bool {
        return lhs.localeId == rhs.localeId
    }
    
}
