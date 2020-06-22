//
//  JinyAuth.swift
//  JinyAuthSDK
//
//  Created by Aravind GS on 19/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

@objc public class JinyAuth:NSObject {
    @objc public static let shared = JinyAuth()
    private var authInternal:JinyAuthInternal
    private var token:String?
    
    private override init() {
        authInternal = JinyAuthInternal()
        super.init()
    }
    
    @objc public func initialize(withToken apiKey:String) {
        token = apiKey
        authInternal.apiKey = token
        return authInternal.start()
    }
}
