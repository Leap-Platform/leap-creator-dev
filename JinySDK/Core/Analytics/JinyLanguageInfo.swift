//
//  JinyLanguageInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyLanguageInfo:Codable {
    
    var current_language:String
    var is_language_set_by_client:Bool
    var app_locale:String?
    
    init(setByUser:Bool) {
        current_language = "hin"
        is_language_set_by_client = setByUser
        app_locale = Locale.current.languageCode
    }
    
}
