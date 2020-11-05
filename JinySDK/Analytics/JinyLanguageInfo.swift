//
//  JinyLanguageInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyLanguageInfo:Codable {
    
    var jiny_lang:String
    var app_lang:String?
    
    init() {
        jiny_lang = JinySharedInformation.shared.getLanguage() ?? ""
        app_lang = Locale.current.languageCode
    }
    
}
