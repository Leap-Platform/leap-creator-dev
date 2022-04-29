//
//  LeapNewNativeIdentifier.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 16/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

struct LeapNewNativeIdentifier: Codable {
    
    let controller: String?
    let idParams: LeapNewIDParams?
    let relationToTarget: [String]?
    let isAnchorSameAsTarget: Bool?
}

struct LeapNewIDParams: Codable {
    
    let className: String?
    let ACC_LABEL: String?
    let text: [String : String]?
}
