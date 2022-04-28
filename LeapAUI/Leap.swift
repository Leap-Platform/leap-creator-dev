//
//  LeapAUI.swift
//  LeapAUI
//
//  Created by Aravind GS on 07/07/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import LeapCoreSDK


@objc public protocol LeapCallback:NSObjectProtocol {
    
    @objc func eventNotification(eventInfo:Dictionary<String,Any>)
}

@objc public class Leap:NSObject {
    
    @objc public static let shared = Leap()
    private var token:String?
    private var auiManager:LeapAUIManager
    private var isStarted:Bool
    @objc public weak var callback:LeapCallback? {
        didSet{
            if callback != nil { auiManager.delegate = self }
            else { auiManager.delegate = nil }
        }
    }
    
    private override init() {
        auiManager = LeapAUIManager()
        isStarted = false
        super.init()
        addObservers()
    }
    
    @discardableResult
    @objc public func withBuilder(_ apiKey: String) -> Leap? {
        let floatVersion = (UIDevice.current.systemVersion as NSString).floatValue
        guard UIDevice.current.userInterfaceIdiom == .phone, floatVersion >= 11 else { return nil}
        token = apiKey
        guard !(token!.isEmpty) else { fatalError("Empty token. Token cannot be empty") }
        LeapPreferences.shared.apiKey = apiKey
        LeapPropertiesHandler.shared.start()
        return self
    }
    
    @discardableResult
    @objc public func addProperty(_ key: String, stringValue: String) -> Leap {
        LeapPropertiesHandler.shared.saveCustomStringProperty(key, stringValue)
        return self
    }
    
    @discardableResult
    @objc public func addProperty(_ key: String, intValue: Int) -> Leap {
        LeapPropertiesHandler.shared.saveCustomIntProperty(key, intValue)
        return self
    }
    
    @discardableResult
    @objc public func addProperty(_ key: String, dateValue: Date) -> Leap {
        let dateSince1970 = Int64(dateValue.timeIntervalSince1970)
        LeapPropertiesHandler.shared.saveCustomLongProperty(key, dateSince1970)
        return self
    }
    
    @objc public func start() {
        let floatVersion = (UIDevice.current.systemVersion as NSString).floatValue
        guard UIDevice.current.userInterfaceIdiom == .phone, floatVersion >= 11 else { return }
        guard let apiKey = token, !apiKey.isEmpty else { fatalError("Api Key missing") }
        auiManager.auiManagerCallBack = LeapCore.shared.initialize(withToken: token!, isTesting: false, uiManager: auiManager)
        isStarted = true
        print("[Leap]SDK is initialised")
    }
    
    @objc public func flush() {
        let floatVersion = (UIDevice.current.systemVersion as NSString).floatValue
        guard UIDevice.current.userInterfaceIdiom == .phone, floatVersion >= 11 else { return }
        guard isStarted else { return }
        auiManager.auiManagerCallBack?.flush()
    }
    
    @objc public func start(_ apiKey:String) {
        let floatVersion = (UIDevice.current.systemVersion as NSString).floatValue
        guard UIDevice.current.userInterfaceIdiom == .phone, floatVersion >= 11 else { return }
        token = apiKey
        LeapPreferences.shared.apiKey = token
        LeapPropertiesHandler.shared.start()
        start()
    }
    
    @objc public func startProject(_ projectId:String, resetProject:Bool = false) {
        let floatVersion = (UIDevice.current.systemVersion as NSString).floatValue
        guard UIDevice.current.userInterfaceIdiom == .phone, floatVersion >= 11 else { return }
        guard isStarted else { return }
        LeapCore.shared.startProject(projectId: projectId, resetProject: resetProject)
    }
    
    @objc public func embedProject(_ projectId:String) {
        let floatVersion = (UIDevice.current.systemVersion as NSString).floatValue
        guard UIDevice.current.userInterfaceIdiom == .phone, floatVersion >= 11 else { return }
        guard  isStarted else { return }
        LeapCore.shared.embedProject(projectId)
    }
    
    @objc public func disable() {
        // Send Leap SDK Disable Event
        auiManager.auiManagerCallBack?.disableLeapSDK()
        auiManager.removeAllViews()
    }
    
}

extension Leap:LeapAUIManagerDelegate {
    func eventGenerated(event: Dictionary<String, Any>) {
        guard let callback = callback else { return }
        callback.eventNotification(eventInfo: event)
    }
    
    
    func isClientCallbackRequired() -> Bool {
        guard let _ = callback else { return false }
        return true
    }
}

extension Leap {
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(postLeapSDKStarted), name: Notification.Name(constant_HasLeapSDKStarted), object: nil)
    }
    
    @objc private func postLeapSDKStarted() {
        if isStarted {
            NotificationCenter.default.post(Notification(name: Notification.Name(constant_LeapSDKStarted)))
        }
    }
}
