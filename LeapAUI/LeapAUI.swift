//
//  LeapAUI.swift
//  LeapAUI
//
//  Created by Aravind GS on 07/07/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import LeapCoreSDK


@objc public protocol LeapAUIClientCallback:NSObjectProtocol {
    
    @objc func eventNotification(eventInfo:Dictionary<String,Any>)
}

@objc public class LeapAUI:NSObject {
    
    @objc public static let shared = LeapAUI()
    private var token:String?
    private var auiManager:LeapAUIManager
    @objc public weak var clientCallback:LeapAUIClientCallback? {
        didSet{
            if clientCallback != nil { auiManager.delegate = self }
            else { auiManager.delegate = nil }
        }
    }
    
    private override init() {
        auiManager = LeapAUIManager()
        auiManager.addObservers()
        super.init()
    }
    
    @objc public func initialize(withToken apiKey:String) {
        token = apiKey
        LeapPreferences.shared.apiKey = token
        guard token != nil, token != "" else { fatalError("Empty token. Token cannot be empty") }
        auiManager.auiManagerCallBack = LeapCore.shared.initialize(withToken: token!, isTesting: false, uiManager: auiManager)
    }
    
    @objc public func addIdentifier(identifier:String, value:Any) {
        auiManager.addIdentifier(identifier: identifier, value: value)
    }
    
}

extension LeapAUI:LeapAUIManagerDelegate {
    func eventGenerated(event: Dictionary<String, Any>) {
        guard let callback = clientCallback else { return }
        callback.eventNotification(eventInfo: event)
    }
    
    
    func isClientCallbackRequired() -> Bool {
        guard let _ = clientCallback else { return false }
        return true
    }
}
