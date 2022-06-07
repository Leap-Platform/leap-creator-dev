//
//  LeapNewDiscovery.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 17/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

struct LeapNewDiscovery: Codable {
    
    let id: Int?
    let uniqueID: String?
    let name: String?
    let nativeIdentifiers: [String]
    let checkPoint, enableIcon: Bool?
    let triggerMode: String
    let instruction: LeapNewInstruction?
    let flowID: Int?
    let trigger: LeapNewTrigger?
    let triggerFrequency: LeapNewTriggerFrequency?
    let localeCodes: [String]?
    let languageOption: LeapNewLanguageOption?
    let autoStart, isWeb: Bool?

    enum CodingKeys: String, CodingKey {
        case id, uniqueID, name, nativeIdentifiers, checkPoint, enableIcon, triggerMode, instruction
        case flowID = "flowId"
        case trigger, triggerFrequency, localeCodes, languageOption, autoStart, isWeb
    }
}
