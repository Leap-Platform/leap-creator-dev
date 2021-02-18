//
//  LeapCoreInfo.swift
//  LeapCore
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class LeapSDKInfo:Codable {
    
    var sdk_version_name:String
    var sdK_version_code:String
    var sdk_build_type:String
    var is_androidx:Bool
    
    init() {
        sdk_version_name = ""
        sdK_version_code = ""
        sdk_build_type = ""
        is_androidx = false
    }
    
}
