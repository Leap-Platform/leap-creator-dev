//
//  JinyAuth.swift
//  JinyAuthSDK
//
//  Created by Aravind GS on 19/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

public class JinyAuth {
    public static let instance: JinyAuth = JinyAuth()
    private var authInternal:JinyAuthInternal?
    private var token:String?
    private var applicationContext: UIApplication?
  
    // JinyAuth.getInstance().initialise(<args>)

    public func initialize(application: UIApplication, withToken apiKey:String) -> Void{
        token = apiKey
        applicationContext = application
        authInternal = JinyAuthInternal(application: application, apiKey: apiKey)
        authInternal?.apiKey = token
        authInternal?.start(application: application, token: apiKey)
    }
}
