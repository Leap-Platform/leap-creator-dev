//
//  JinyMenuItemClickInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyMenuItemClickInfo:Codable {
    
    var mute_button_click:Bool
    var repeat_button_click:Bool
    var change_language_button_click:Bool
    var cross_button_click:Bool
    var centre_bar_click:Bool
    var option_selected_click:Bool
    var language_selected_click:Bool
    
    init() {
        mute_button_click = false
        repeat_button_click = false
        change_language_button_click = false
        cross_button_click = false
        centre_bar_click = false
        option_selected_click = false
        language_selected_click = false
    }
    
}
