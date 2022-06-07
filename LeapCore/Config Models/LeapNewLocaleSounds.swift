//
//  LeapNewLocaleSounds.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 17/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

struct LeapNewLocaleSounds: Codable {
    
    let baseUrl: String?
    let sounds: [String : [LeapNewSound]]?
}
