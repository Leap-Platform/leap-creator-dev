//
//  LeapNewWebIdentifier.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 17/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

struct LeapNewWebIdentifier: Codable {
    
    let tagName: String?
    let attributes: [String : LeapNewAttributes]?
    let innerText: [String : String]?
    let activeElement: Bool?
    let index: Int?
    let activityName: String?
}

struct LeapNewAttributes: Codable {
    
    let attributeClass: String?
    
    enum CodingKeys: String, CodingKey {
        case attributeClass = "class"
    }
}
