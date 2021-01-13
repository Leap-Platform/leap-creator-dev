//
//  JinyAUI.swift
//  JinyAUI
//
//  Created by Aravind GS on 07/07/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import JinySDK


@objc public protocol JinyAUIClientCallback:NSObjectProtocol {
    
    @objc func eventNotification(eventInfo:Dictionary<String,Any>)
}

@objc public class JinyAUI:NSObject {
    
    @objc public static let shared = JinyAUI()
    private var token:String?
    private var auiManager:JinyAUIManager
    @objc public weak var clientCallback:JinyAUIClientCallback? {
        didSet{
            if clientCallback != nil { auiManager.delegate = self }
            else { auiManager.delegate = nil }
        }
    }
    
    private override init() {
        auiManager = JinyAUIManager()
        auiManager.addKeyboardObservers()
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

extension JinyAUI:JinyAUIManagerDelegate {
    func eventGenerated(event: Dictionary<String, Any>) {
        guard let callback = clientCallback else { return }
        callback.eventNotification(eventInfo: event)
    }
    
    
    func isClientCallbackRequired() -> Bool {
        guard let _ = clientCallback else { return false }
        return true
    }
}
