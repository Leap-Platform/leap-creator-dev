//
//  JinyClientPreference.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyClientPreference:Codable {
    
    var api_key:String
    var user_id:String = ""
    
    init() {
        api_key = JinySharedInformation.shared.getAPIKey()
        user_id = ""
    }
    
}
