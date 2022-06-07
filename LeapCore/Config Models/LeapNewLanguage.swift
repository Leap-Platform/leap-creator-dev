//
//  LeapNewLanguage.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 16/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

struct LeapNewLanguage: Codable {
    
    let localeId: String?
    let localeName: String?
    let localeScript: String?
    let muteText: String?
    let repeatText: String?
    let changeLanguageText: String?
    let ttsInfo: LeapNewTTSInfo?
}

struct LeapNewTTSInfo: Codable {
    
    let ttsLocale: String?
    let ttsRegion: String?
}

struct LeapNewLanguageOption: Codable {
    
    let htmlURL, accessibilityText: String?

    enum CodingKeys: String, CodingKey {
        case htmlURL = "htmlUrl"
        case accessibilityText
    }
}
