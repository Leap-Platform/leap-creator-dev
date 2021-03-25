//
//  LeapCreatorManager.swift
//  LeapCreator
//
//  Created by Ajay S on 04/01/21.
//  Copyright © 2021 Leap Inc. All rights reserved.
//

import Foundation
import AdSupport

protocol LeapCreatorManagerDelegate: class {
    func fetchConfigSuccess()
    func fetchConfigFailure()
}

class LeapCreatorManager {
    
    weak var delegate: LeapCreatorManagerDelegate?
    let apiKey: String?
    
    init(key: String, delegate: LeapCreatorManagerDelegate) {
        self.apiKey = key
        self.delegate = delegate
    }

    func fetchCreatorConfig() {
        let url = URL(string: LeapCreatorShared.shared.ALFRED_URL+LeapCreatorShared.shared.CREATOR_CONFIG_ENDPOINT)
        print("config url = \(url!.absoluteString)")
        var req = URLRequest(url: url!)
        req.httpMethod = "GET"
        req.addValue(apiKey!, forHTTPHeaderField: "x-auth-id")
        req.addValue(ASIdentifierManager.shared().advertisingIdentifier.uuidString, forHTTPHeaderField: "x-apple-ad-id")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let configTask = URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard let resultData = data else { return }
            guard let configDict = try?  JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,Any> else { return }
            
            if let httpResponse = response as? HTTPURLResponse {
                let status = httpResponse.statusCode
                switch status {
                case 200: print(configDict)
                    
                    do {
                        let decoder = JSONDecoder()
                        let creatorData = try decoder.decode(LeapCreatorData.self, from: resultData)
                        
                        guard let creatorConfig = creatorData.creatorConfig else {
                            
                            print("WARNING: Creator Config is Empty")
                            
                            return
                        }
                        
                        LeapCreatorShared.shared.creatorConfig = creatorConfig
                        self.delegate?.fetchConfigSuccess()
                        
                    } catch let error {
                        
                        print(error)
                    }
                    
                default: self.delegate?.fetchConfigFailure()
                }
                
            }
        }
        configTask.resume()
    }
}
