//
//  LeapCreatorInternal.swift
//  LeapCreator
//
//  Created by Aravind GS on 19/06/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import UIKit

class LeapCreatorInternal : NSObject{
    
    var apiKey:String?
    var masterManager: LeapMasterManager?
    var creatorManager: LeapCreatorManager?
    var applicationContext: UIApplication
    var appDelegate: UIApplicationDelegate?
    
    init(apiKey : String) {
        self.applicationContext = UIApplication.shared
        self.apiKey = apiKey
        self.masterManager = LeapMasterManager(key: apiKey)
        self.appDelegate = UIApplication.shared.delegate
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "internetConnected"), object: nil)
    }
    
    
    func start() {
        NotificationCenter.default.addObserver(self, selector: #selector(internetConnected), name: NSNotification.Name(rawValue: "internetConnected"), object: nil)
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
        if  let name = Bundle.main.bundleIdentifier , name != "com.leap.LeapSampleApp" {
            DispatchQueue.main.async {
                LeapNotificationManager.shared.checkForAuthorisation()
            }
        }
        
        startSendingBeacons()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "internetConnected"), object: nil)
    }
    
    func fetchConfigFailure() {
        
        print("Fetch Creator Config Failed")
    }
    
    @objc func internetConnected() {
       
        if LeapCreatorShared.shared.creatorConfig == nil {
            
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "internetConnected"), object: nil)
            
            start()
        }
    }
}
    
extension String {
    subscript (index: Int) -> Character {
        let charIndex = self.index(self.startIndex, offsetBy: index)
        return self[charIndex]
    }

    subscript (range: Range<Int>) -> Substring {
        let startIndex = self.index(self.startIndex, offsetBy: range.startIndex)
        let stopIndex = self.index(self.startIndex, offsetBy: range.startIndex + range.count)
        return self[startIndex..<stopIndex]
    }
}
