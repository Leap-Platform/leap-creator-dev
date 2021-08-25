//
//  LeapPreferences.swift
//  LeapCore
//
//  Created by Ajay S on 04/02/21.
//  Copyright © 2021 Leap Inc. All rights reserved.
//

import Foundation

// MARK: - AUDIO LANGUAGE CODE GETTER AND SETTER
class LeapPreferences {
    
    static let shared = LeapPreferences()
    
    let prefs = UserDefaults.standard
    var apiKey: String?
    
    var isPreview = false
    
    var previewUserLanguage = constant_ang
    
    let languageCode = "leap_language_code"
    
    func setUserLanguage(_ language: String) {
        guard !isPreview else {
            previewUserLanguage = language
            return
        }
        prefs.setValue(language, forKey: languageCode)
        prefs.synchronize()
    }
    
    func getUserLanguage() -> String? {
        return isPreview ? previewUserLanguage : prefs.value(forKey: languageCode) as? String
    }
}
