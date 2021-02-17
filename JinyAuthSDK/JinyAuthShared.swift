//
//  Constants.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 23/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyAuthShared {
    
    static let shared = JinyAuthShared()
    
    /// api key
    var apiKey: String?
    
    /// auth configuration
    var authConfig: JinyAuthConfig?
    
    /// Base Url
    let ALFRED_DEV_BASE_URL: String = "https://alfred-dev-gke.leap.is"
    
    /// End Point
    let AUTH_CONFIG_ENDPOINT: String = "/alfred/api/v1/apps/snap"
}
