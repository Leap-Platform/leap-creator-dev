//
//  JinyBottomActivityStateInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyBottomActivityStateInfo:Codable {
    
    var option_panel_visible:Bool
    var language_panel_visible:Bool
    var branch_enabled:Bool
    var disable_assistant_panel_visble:Bool
    
    init() {
        option_panel_visible = false
        language_panel_visible = false
        branch_enabled = false
        disable_assistant_panel_visble = false
    }
    
}
