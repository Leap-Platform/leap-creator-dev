//
//  JinyAUI.swift
//  JinyAUI
//
//  Created by Aravind GS on 07/07/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import JinySDK

@objc public class JinyAUI:NSObject {
    
    @objc public static let shared = JinyAUI()
    private var token:String?
    private var auiManager:JinyAUIManager
    
    
    private override init() {
        auiManager = JinyAUIManager()
        super.init()
    }
    
    @objc public func initialize(withToken apiKey:String) {
        token = apiKey
        guard token != nil, token != "" else { fatalError("Empty token. Token cannot be empty") }
        auiManager.auiManagerCallBack = Jiny.shared.initialize(withToken: token!, isTesting: false, uiManager: auiManager)
    }
    
    @objc public func addIdentifier(identifier:String, value:Any) {
        auiManager.addIdentifier(identifier: identifier, value: value)
    }
    
}
