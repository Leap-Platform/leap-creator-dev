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
    var ttsInfo:Dictionary<String,String>
    
    init(withLanguageDict dict:Dictionary<String, Any>) {
        localeId = dict["localeId"] as? String ?? ""
        name = dict["localeName"] as? String ?? ""
        script = dict["localeScript"] as? String ?? ""
        muteText = dict["muteText"] as? String ?? ""
        repeatText = dict["repeatText"] as? String ?? ""
        changeLanguageText = dict["change_language_text"] as? String ?? ""
        ttsInfo = dict["ttsInfo"] as? Dictionary<String,String> ?? [:]
    }
    
}
