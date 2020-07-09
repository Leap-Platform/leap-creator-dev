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
    private var uiManager:JinyAUIManager
    
    
    private override init() {
        uiManager = JinyAUIManager()
        super.init()
    }
    
    @objc public func initialize(withToken apiKey:String) {
        token = apiKey
        guard token != nil, token != "" else { fatalError("Empty token. Token cannot be empty") }
        uiManager.uiManagerCallBack = Jiny.shared.initialize(withToken: token!, isTesting: false, uiManager: uiManager)
    }
    
}
