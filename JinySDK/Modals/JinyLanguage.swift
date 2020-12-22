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
        localeId = dict["locale_id"] as? String ?? ""
        name = dict["locale_name"] as? String ?? ""
        script = dict["locale_script"] as? String ?? ""
        muteText = dict["mute_text"] as? String ?? ""
        repeatText = dict["repeat_text"] as? String ?? ""
        changeLanguageText = dict["change_language_text"] as? String ?? ""
        ttsInfo = dict["tts_info"] as? Dictionary<String,String> ?? [:]
    }
    
}
