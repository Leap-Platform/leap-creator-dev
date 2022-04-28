//
//  LeapNewDiscoverySounds.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 17/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

struct LeapNewDiscoverySounds: Codable {
    
    let baseUrl: String?
    let jinySounds: [String : [LeapNewSound]]?
}

struct LeapNewSound: Codable {
    
    let url: String?
    let name: String?
    let text: String?
    let version: Int?
    let isTTSEnabled: Bool?
}
