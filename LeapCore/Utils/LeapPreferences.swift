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
    
    let languageCode = "leap_language_code"
    
    func setUserLanguage(_ language: String) {
        prefs.setValue(language, forKey: languageCode)
        prefs.synchronize()
    }
    
    func getUserLanguage() -> String? {
        return prefs.value(forKey: languageCode) as? String
    }
}
