//
//  JinyAuthConfig.swift
//  JinyAuthSDK
//
//  Created by Ajay S on 04/01/21.
//  Copyright © 2021 Jiny Inc. All rights reserved.
//

import Foundation

class JinyAuthData: Codable {
    
    var authConfig: JinyAuthConfig?
    
    enum CodingKeys: String, CodingKey {
        case authConfig = "data"
    }
    
    init() {
        
    }
    
    // MARK: - Decodable
    required convenience public init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
                
        self.authConfig = try? container.decodeIfPresent(JinyAuthConfig.self, forKey: .authConfig)
    }
    
    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
    }
}

class JinyAuthConfig: Codable {
    
    var beacon: Beacon?
    
    var permission: Permission?
    
    var message: Message?
    
    var streaming: Streaming?
    
    enum CodingKeys: String, CodingKey {
        case beacon = "beacon"
        case permission = "permission"
        case message = "message"
        case streaming = "streaming"
    }
    
    init() {
        
    }
    
    // MARK: - Decodable
    required convenience public init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.beacon = try container.decodeIfPresent(Beacon.self, forKey: .beacon)
        
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
    required convenience public init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
                
        self.interval = try container.decode(Double.self, forKey: .interval)

    }
    
    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
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
    required convenience public init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.dialogTitle = try container.decodeIfPresent(String.self, forKey: .dialogTitle)
        
        self.dialogDescription = try container.decodeIfPresent(String.self, forKey: .dialogDescription)
        
        self.timeOutDuration = try container.decodeIfPresent(Double.self, forKey: .timeOutDuration)
        
        self.positiveFeedbackBtnBackground = try container.decodeIfPresent(String.self, forKey: .positiveFeedbackBtnBackground)
    }
    
    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
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
    required convenience public init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
                
        self.sessionTimeOut = try? container.decodeIfPresent(String.self, forKey: .sessionTimeOut)
    }
    
    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
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
    required convenience public init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.frameRate = try container.decodeIfPresent(Double.self, forKey: .frameRate)
        
        self.quality = try container.decodeIfPresent(Double.self, forKey: .quality)
        
        self.shouldResize = try container.decodeIfPresent(Bool.self, forKey: .shouldResize)
    }
    
    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
    }
}
