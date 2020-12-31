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
  
    public func initialize(withToken apiKey:String) -> Void{
        token = apiKey
        authInternal = JinyAuthInternal(apiKey: apiKey)
        authInternal?.apiKey = token
        JinyAuthShared.shared.apiKey = token
        authInternal?.start(token: apiKey)
    }
}
