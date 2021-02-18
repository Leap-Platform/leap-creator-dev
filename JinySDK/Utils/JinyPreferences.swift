//
//  JinyPreferences.swift
//  JinySDK
//
//  Created by Ajay S on 04/02/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

// MARK: - AUDIO LANGUAGE CODE GETTER AND SETTER
class JinyPreferences {
    
    static let shared = JinyPreferences()
    
    let prefs = UserDefaults.standard
    var currentLanguage:String?
    var apiKey:String?
    
    let languageCode = "jiny_audio_language_code"
    
    func setUserLanguage(_ language: String) {
        prefs.setValue(language, forKey: languageCode)
        prefs.synchronize()
    }
    
    func getUserLanguage() -> String? {
        return prefs.value(forKey: languageCode) as? String
    }
}
