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
    var onboardingFirstText:String?
    var onboardingSecondText:String?
    var moreOptionsText:String?
    var muteText:String
    var repeatText:String
    var changeLanguageText:String
    var jinyHelpText:String?
    var downloadProgressText:String?
    
    init(withLanguageDict dict:Dictionary<String, String>) {
        localeId = dict["locale_id"] ?? ""
        name = dict["locale_name"] ?? ""
        script = dict["locale_script"] ?? ""
        onboardingFirstText = dict["onboarding_first_text"]
        onboardingSecondText = dict["onboarding_second_text"]
        moreOptionsText = dict["more_options_text"]
        muteText = dict["mute_text"] ?? ""
        repeatText = dict["repeat_text"] ?? ""
        changeLanguageText = dict["change_language_text"] ?? ""
        jinyHelpText = dict["jiny_help_text"]
        downloadProgressText = dict["jiny_download_progress_text"]
    }
    
}
