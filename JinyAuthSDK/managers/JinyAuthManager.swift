//
//  JinyAuthManager.swift
//  JinyAuthSDK
//
//  Created by Ajay S on 04/01/21.
//  Copyright © 2021 Jiny Inc. All rights reserved.
//

import Foundation
import AdSupport

protocol AuthManagerDelegate: class {
    func fetchConfigSuccess()
    func fetchConfigFailure()
}

class JinyAuthManager {
    
    weak var delegate: AuthManagerDelegate?
    let apiKey: String?
    
    init(key: String, delegate: AuthManagerDelegate) {
        self.apiKey = key
        self.delegate = delegate
    }

    func fetchAuthConfig() {
        let url = URL(string: JinyAuthShared.shared.ALFRED_DEV_BASE_URL+JinyAuthShared.shared.AUTH_CONFIG_ENDPOINT)
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
                                                    
                        let serializedData = try JSONSerialization.data(withJSONObject: configDict, options: JSONSerialization.WritingOptions.prettyPrinted)
                            
                        let decoder = JSONDecoder()
                        let authData = try decoder.decode(JinyAuthData.self, from: serializedData)
                        
                        guard let authConfig = authData.authConfig else {
                            
                            print("WARNING: Auth Config is Empty")
                            
                            return
                        }
                        
                        JinyAuthShared.shared.authConfig = authConfig
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
