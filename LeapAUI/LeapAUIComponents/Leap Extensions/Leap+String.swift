//
//  Leap+String.swift
//  LeapAUISDK
//
//  Created by Ajay S on 07/04/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

extension String {
    
    static func generateUUIDString() -> String {
        return "\(randomString(8))-\(randomString(4))-\(randomString(4))-\(randomString(4))-\(randomString(12))"
    }
    
    static func randomString(_ length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        let randomString = String((0..<length).map{_ in letters.randomElement()!})
        return randomString
    }
}
