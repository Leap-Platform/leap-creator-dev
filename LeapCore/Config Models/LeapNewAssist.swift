//
//  LeapNewAssist.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 15/12/21.
//  Copyright © 2021 Leap. All rights reserved.
//

import Foundation

struct LeapNewAssist: Codable {
    
    let id: Int?
    let uniqueID : String?
    let name : String?
    let nativeIdentifiers: [String]?
    let checkPoint: Bool?
    let type: String?
    let instruction: LeapNewInstruction?
    let trigger: LeapNewTrigger?
    let localeCode: String?
    let isWeb: Bool?
}


