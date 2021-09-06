//
//  LeapCreatorInternal.swift
//  LeapCreator
//
//  Created by Aravind GS on 19/06/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import UIKit

class LeapCreatorInternal: NSObject {
    
    var apiKey:String?
    var masterManager: LeapMasterManager?
    var creatorManager: LeapCreatorManager?
    var applicationContext: UIApplication
    var appDelegate: UIApplicationDelegate?
    private var isLeapSDKStarted = false
    
    init(apiKey : String) {
        self.applicationContext = UIApplication.shared
        self.apiKey = apiKey
        self.masterManager = LeapMasterManager(key: apiKey)
        self.appDelegate = UIApplication.shared.delegate
    }
    
    func start() {
        addObservers()
        guard let apiKey = self.apiKey else { return }
        self.creatorManager = LeapCreatorManager(key: apiKey, delegate: self)
        self.creatorManager?.fetchCreatorConfig()
    }
    
    private func startSendingBeacons() {
       
        //begin sending beacons
        masterManager?.initialiseComponents()
        masterManager?.start()
    }
}

extension LeapCreatorInternal: LeapCreatorManagerDelegate {
    func fetchConfigSuccess() {
        if let _: AnyClass = NSClassFromString("\(constant_LeapSDK).\(constant_Leap)") {
            NotificationCenter.default.post(Notification(name: Notification.Name(constant_HasLeapSDKStarted)))
            if isLeapSDKStarted {
                DispatchQueue.main.async {
                    LeapNotificationManager.shared.resetNotification()
                }
            }
        }
        
        startSendingBeacons()
    }
    
    func fetchConfigFailure() {
        
        print("Fetch Creator Config Failed")
    }
    
    @objc func internetConnected() {
       
        if LeapCreatorShared.shared.creatorConfig == nil {
            
            start()
        }
    }
}

extension LeapCreatorInternal {
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(leapSDKStarted), name: Notification.Name(constant_LeapSDKStarted), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(internetConnected), name: NSNotification.Name(rawValue: constant_internetConnected), object: nil)
    }
    
    @objc private func leapSDKStarted() {
        isLeapSDKStarted = true
    }
}
