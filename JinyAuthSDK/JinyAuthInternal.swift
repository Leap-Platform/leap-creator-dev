//
//  JinyAuthInternal.swift
//  JinyAuthSDK
//
//  Created by Aravind GS on 19/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class JinyAuthInternal {
    
    public var apiKey:String?
    public var masterManager: MasterManager?
    public var applicationContext: UIApplication
   
    init(application: UIApplication, apiKey : String) {
    
        self.applicationContext = application
        self.apiKey = apiKey
        self.masterManager = MasterManager(application: applicationContext, key: apiKey)
    }
    
    func start(application: UIApplication, token : String){
        
        //begin sending beacons
        masterManager?.initialiseComponents()
        masterManager?.start()
    }
    
    private var screenshotTimer:Timer?
    
    
    
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
