//
//  LeapNewData.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 17/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

struct LeapNewBase64Data: Codable {
    
    var config: [String]?
    var params: LeapParams?
    
    enum CodingKeys: String, CodingKey {
        case config = "data"
        case params
    }
    
    func getLeapNewData() -> LeapNewData? {
        
        guard let config = config else { return nil }
        
        var leapNewData = LeapNewData()
        leapNewData.config = []
        leapNewData.params = self.params
        
        let decoder = JSONDecoder()
        
        for base64String in config {
            let base64DecodedData = Data(base64Encoded: base64String)
            if let decompressedData = try? base64DecodedData?.gunzipped(), let leapNewConfig = try? decoder.decode(LeapNewConfig.self, from: decompressedData) {
                leapNewData.config?.append(leapNewConfig)
            }
        }
        return leapNewData
    }
}

struct LeapNewData: Codable {
    
    var config: [LeapNewConfig]?
    var params: LeapParams?
    
    enum CodingKeys: String, CodingKey {
        case config = "data"
        case params
    }
}

// MARK: - Params
struct LeapParams: Codable {
    
    let viewAlphaIgnoreLimit: Int?
}
