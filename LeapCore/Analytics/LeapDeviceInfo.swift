//
//  LeapDeviceInfo.swift
//  LeapCore
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

class LeapDeviceInfo:Codable {
    var model:String
    var os_version:String
    var device:String
    var api_level:String
    var product:String
    var screen_height:String
    var screen_width:String
    var first_installed:String
    var last_updated:String
    var version_code:String
    var version_string:String
    
    init() {
        model = UIDevice.current.model
        os_version = UIDevice.current.systemVersion
        device = UIDevice.current.name
        api_level = ""
        product = ""
        screen_width = "\(UIScreen.main.bounds.width)"
        screen_height = "\(UIScreen.main.bounds.height)"
        first_installed = ""
        last_updated = ""
        version_code = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "Empty"
        version_string = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "Empty"
    }
}
