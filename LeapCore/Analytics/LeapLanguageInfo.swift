//
//  LeapLanguageInfo.swift
//  LeapCore
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

class LeapLanguageInfo:Codable {
    
    var leap_lang:String
    var app_lang:String?
    
    init() {
        leap_lang = LeapPreferences.shared.getUserLanguage() ?? ""
        app_lang = Locale.current.languageCode
    }
    
}
