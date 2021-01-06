//
//  JinyAuthInternal.swift
//  JinyAuthSDK
//
//  Created by Aravind GS on 19/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class JinyAuthInternal : NSObject{
    
    var apiKey:String?
    var masterManager: MasterManager?
    var authManager: JinyAuthManager?
    var applicationContext: UIApplication
    var appDelegate: UIApplicationDelegate
    
    init(apiKey : String) {
        self.applicationContext = UIApplication.shared
        self.apiKey = apiKey
        self.masterManager = MasterManager(key: apiKey)
        self.appDelegate = UIApplication.shared.delegate!
    }
    
    
    func start() {
        
        self.authManager = JinyAuthManager(key: self.apiKey!, delegate: self)
        self.authManager?.fetchAuthConfig()
    }
    
    private func startSendingBeacons() {
       
        //begin sending beacons
        masterManager?.initialiseComponents()
        masterManager?.start()
    }
}

extension JinyAuthInternal: AuthManagerDelegate {
    func fetchConfigSuccess() {
        
        startSendingBeacons()
    }
    
    func fetchConfigFailure() {
        
        print("Fetch Auth Config Failed")
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
