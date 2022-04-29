//
//  LeapNewFlow.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 16/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

struct LeapNewFlow: Codable {
    
    let id: Int?
    let name: String?
    let pages: [LeapNewPage]?
    let firstStep: String?
}
