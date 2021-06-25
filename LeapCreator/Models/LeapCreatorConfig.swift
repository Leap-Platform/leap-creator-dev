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
    
    init() {
        
    }
    
    // MARK: - Decodable
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
                
        self.creatorConfig = try? container.decodeIfPresent(LeapCreatorConfig.self, forKey: .creatorConfig)
    }
    
    // MARK: - Encodable
    func encode(to encoder: Encoder) throws {
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
    
    init() {
        
    }
    
    // MARK: - Decodable
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.appName = try container.decodeIfPresent(String.self, forKey: .appName)
        
        self.beacon = try container.decodeIfPresent(Beacon.self, forKey: .beacon)
        
        self.documentation = try container.decodeIfPresent(Documentation.self, forKey: .documentation)
        
        self.permission = try? container.decodeIfPresent(Permission.self, forKey: .permission)
     
        self.message = try container.decodeIfPresent(Message.self, forKey: .message)
        
        self.streaming = try container.decodeIfPresent(Streaming.self, forKey: .streaming)
    }
    
    // MARK: - Encodable
    func encode(to encoder: Encoder) throws {
    }
}

class Beacon: Codable {
    
    var interval: Double = 3000
    
    enum CodingKeys: String, CodingKey {
        case interval = "interval"
    }
    
    init() {
        
    }
    
    // MARK: - Decodable
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
                
        self.interval = try container.decode(Double.self, forKey: .interval)

    }
    
    // MARK: - Encodable
    func encode(to encoder: Encoder) throws {
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
    
    init() {
        
    }
    
    // MARK: - Decodable
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
                
        self.connectSampleApp = try container.decode(String.self, forKey: .connectSampleApp)
        
        self.generateQrHelp = try container.decode(String.self, forKey: .generateQrHelp)
        
        self.mirrorApp = try container.decode(String.self, forKey: .mirrorApp)
        
        self.previewDevice = try container.decode(String.self, forKey: .previewDevice)
    }
    
    // MARK: - Encodable
    func encode(to encoder: Encoder) throws {
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
    
    init() {
        
    }
    
    // MARK: - Decodable
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.dialogTitle = try container.decodeIfPresent(String.self, forKey: .dialogTitle)
        
        self.dialogDescription = try container.decodeIfPresent(String.self, forKey: .dialogDescription)
        
        self.timeOutDuration = try container.decodeIfPresent(Double.self, forKey: .timeOutDuration)
        
        self.positiveFeedbackBtnBackground = try container.decodeIfPresent(String.self, forKey: .positiveFeedbackBtnBackground)
    }
    
    // MARK: - Encodable
    func encode(to encoder: Encoder) throws {
    }
}

class Message: Codable {
    
    var sessionTimeOut: String?
    
    enum CodingKeys: String, CodingKey {
        case sessionTimeOut = "sessionTimeOut"
    }
    
    init() {
        
    }
    
    // MARK: - Decodable
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
                
        self.sessionTimeOut = try? container.decodeIfPresent(String.self, forKey: .sessionTimeOut)
    }
    
    // MARK: - Encodable
    func encode(to encoder: Encoder) throws {
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
    
    init() {
        
    }
    
    // MARK: - Decodable
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.frameRate = try container.decodeIfPresent(Double.self, forKey: .frameRate)
        
        self.quality = try container.decodeIfPresent(Double.self, forKey: .quality)
        
        self.shouldResize = try container.decodeIfPresent(Bool.self, forKey: .shouldResize)
    }
    
    // MARK: - Encodable
    func encode(to encoder: Encoder) throws {
    }
}
