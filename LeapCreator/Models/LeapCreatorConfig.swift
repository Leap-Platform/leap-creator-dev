//
//  LeapCreatorConfig.swift
//  LeapCreator
//
//  Created by Ajay S on 04/01/21.
//  Copyright © 2021 Leap Inc. All rights reserved.
//

import Foundation

class LeapCreatorData: Codable {
    
    var creatorConfig: LeapCreatorConfig?
    
    enum CodingKeys: String, CodingKey {
        case creatorConfig = "data"
    }
}

class LeapCreatorConfig: Codable {
    
    var appName: String?
    
    var beacon: Beacon?
    
    var documentation: Documentation?
    
    var permission: Permission?
    
    var message: Message?
    
    var streaming: Streaming?
    
    enum CodingKeys: String, CodingKey {
        case appName = "appName"
        case beacon = "beacon"
        case documentation = "documentation"
        case permission = "permission"
        case message = "message"
        case streaming = "streaming"
    }
}

class Beacon: Codable {
    
    var interval: Double = 3000
    
    enum CodingKeys: String, CodingKey {
        case interval = "interval"
    }
}

class Documentation: Codable {
    
    var connectSampleApp: String?
    
    var generateQrHelp: String?
    
    var mirrorApp: String?
    
    var previewDevice: String?
    
    enum CodingKeys: String, CodingKey {
        case connectSampleApp = "connectSampleApp"
        case generateQrHelp = "generateQrHelp"
        case mirrorApp = "mirrorApp"
        case previewDevice = "previewDevice"
    }
}

class Permission: Codable {
    
    var dialogTitle: String?
    
    var dialogDescription: String?
    
    var timeOutDuration: Double?
               
    var positiveFeedbackBtnBackground: String? // in hex
    
    enum CodingKeys: String, CodingKey {
        case dialogTitle = "dialogTitle"
        case dialogDescription = "dialogDescription"
        case timeOutDuration = "timeOutDuration"
        case positiveFeedbackBtnBackground = "positiveFeedbackBtnBackground"
    }
}

class Message: Codable {
    
    var sessionTimeOut: String?
    
    enum CodingKeys: String, CodingKey {
        case sessionTimeOut = "sessionTimeOut"
    }
}

class Streaming: Codable {
    
    var frameRate: Double?
        
    var quality: Double?
               
    var shouldResize: Bool?
    
    enum CodingKeys: String, CodingKey {
        case frameRate = "frameRate"
        case quality = "quality"
        case shouldResize = "shouldResize"
    }
}
