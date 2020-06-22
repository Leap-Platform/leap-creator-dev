//
//  Jiny.swift
//  JinySDK
//
//  Created by Aravind GS on 16/03/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

@objc public class Jiny:NSObject {
        
    @objc public static let shared = Jiny()
    private var jinyInternal:JinyInternal?
    private var apiKey:String? = nil
    private var isTest:Bool? = false
    private var sdkEnabled:Bool = true
    
    private override init() {
        self.sdkEnabled = true
        super.init()
    }
    
    @objc public func initialize(withToken token:String, isTesting isTest:Bool) {
        assert(token != "", "Incorrect token")
        self.apiKey = token
        self.isTest = isTest
        self.jinyInternal = JinyInternal.init(self.apiKey!)
    }
    
    @objc public func enable(_ enable:Bool) {
        sdkEnabled = enable
    }

    
}

struct Constants {
    
}
