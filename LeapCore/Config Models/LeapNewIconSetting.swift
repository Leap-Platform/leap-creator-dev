//
//  LeapNewIconSetting.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 17/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

struct LeapNewIconSetting: Codable {
    
    let dismissible, leftAlign: Bool?
    let bgColor, htmlURL: String?
    let isCustomised: Bool?

    enum CodingKeys: String, CodingKey {
        case dismissible, leftAlign, bgColor
        case htmlURL = "htmlUrl"
        case isCustomised
    }
}
