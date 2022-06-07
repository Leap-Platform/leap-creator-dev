//
//  LeapNewAUIContent.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 17/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

// MARK: - AuiContent
struct LeapNewAUIContent: Codable {
    
    let baseURL: String?
    let content: [String]?

    enum CodingKeys: String, CodingKey {
        case baseURL = "baseUrl"
        case content
    }
}
