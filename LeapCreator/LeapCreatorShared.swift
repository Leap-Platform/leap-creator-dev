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
    
    let ALFRED_URL: String = {
        #if DEV
            return "https://alfred-dev-gke.leap.is"
        #elseif STAGE
            return "https://alfred-stage-gke.leap.is"
        #elseif PROD
            return "https://alfred.leap.is"
        #else
            return "https://alfred.leap.is"
        #endif
    }()
    
    /// End Point
    let CREATOR_CONFIG_ENDPOINT: String = "/alfred/api/v1/apps/creator"
    let VALIDATE_ROOMID_ENDPOINT: String = "/alfred/api/v1/apps/device-rooms/"
}
