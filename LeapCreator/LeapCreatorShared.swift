//
//  LeapCreatorShared.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 23/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

class LeapCreatorShared {
    
    static let shared = LeapCreatorShared()
    
    /// api key
    var apiKey: String?
    
    /// creator configuration
    var creatorConfig: LeapCreatorConfig?
    
    /// Base Url
    let ALFRED_DEV_BASE_URL: String = "https://alfred-dev-gke.leap.is"
    
    /// End Point
    let CREATOR_CONFIG_ENDPOINT: String = "/alfred/api/v1/apps/creator"
}
