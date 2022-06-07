//
//  LeapTestConfigGenerator.swift
//  LeapCoreSDKTests
//
//  Created by Aravind GS on 09/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
@testable import LeapCoreSDK


class LeapTestConfigGenerator {
    
    func getOneAssistAndOneDiscoveryPassingConfig() -> LeapConfig {
        return getConfig(fileName: "OneAssistAndOneDiscoveryPassingConfig")
    }
    
    func getOneContextPassingAndOneContextFailingConfig() -> LeapConfig {
        return getConfig(fileName: "OneContextPassingOneContextFailing")
    }
    
    func getTwoAssistPassingConfig() -> LeapConfig {
        return getConfig(fileName: "TwoAssistsPassingConfig")
    }
    
    func getOneDiscoveryPassingConfig() -> LeapConfig {
        return getConfig(fileName: "OneDiscoveryPassingConfig")
    }
    
    private func getConfig(fileName:String) -> LeapConfig {
        
        guard let filepath = Bundle(for: LeapTestConfigGenerator.self).path(forResource: fileName, ofType: "json"),
              let contents = try? String(contentsOfFile: filepath),
              let data = contents.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? Dictionary<String,Any> else {
            fatalError("Incorrect config")
        }
        return LeapConfig(withDict: dict, isPreview: false)
    }
    
}
