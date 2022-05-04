//
//  LeapNewPage.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 17/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

struct LeapNewPage: Codable {
    
    let nativeIdentifiers: [String]?
    let checkPoint: Bool?
    let stages: [LeapNewStage]?
    let isWeb: Bool?
}

struct LeapNewStage: Codable {
    
    let id: Int?
    let uniqueID: String?
    let name: String?
    let nativeIdentifiers: [String]?
    let checkPoint: Bool?
    let type: String?
    let frequency: LeapNewFrequency?
    let instruction: LeapNewInstruction?
    let transition: LeapNewTransition?
    let isWeb: Bool?
}

struct LeapNewTransition: Codable {
    
    let prev: String?
    let next: String?
}
