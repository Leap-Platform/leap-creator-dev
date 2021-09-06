//
//  LeapQRCodeManager.swift
//  LeapCreatorSDK
//
//  Created by Ajay S on 21/06/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

class LeapQRCodeManager {
    
    private let codeUrl: String = {
        #if DEV
        return "https://alfred-dev-gke.leap.is/alfred/api/v1/device/qr"
        #elseif STAGE
        return "https://alfred-stage-gke.leap.is/alfred/api/v1/device/qr"
        #elseif PROD
        return "https://alfred.leap.is/alfred/api/v1/device/qr"
        #else
        return "https://alfred.leap.is/alfred/api/v1/device/qr"
        #endif
    }()
    
    var qrCodeInfo: LeapQRCode?
    
    var qrCodeDict: Dictionary<String, Any>?
    
    func validateCode(with code: String, completion: @escaping SuccessCallBack) {
        guard let codeUrl: URL = URL(string: codeUrl) else { return }
        var urlRequest: URLRequest = URLRequest(url: codeUrl)
        urlRequest.addValue(LeapCreatorShared.shared.apiKey ?? "NA", forHTTPHeaderField: "x-auth-id")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        let info = ["qrSecret": code]
        guard let data = try? JSONSerialization.data(withJSONObject: info, options: .fragmentsAllowed) else { return }
        urlRequest.httpBody = data
        let codeTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            if let resultData = data {
                guard let qrDict = try?  JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,Any>, error == nil else {
                    completion(false)
                    return
                }
                
                self?.qrCodeDict = qrDict
                
                do {
                    let decoder = JSONDecoder()
                    let qrCode = try decoder.decode(LeapQRCode.self, from: resultData)
                    
                    self?.qrCodeInfo = qrCode
                    completion(true)
                    
                } catch let error {
                    
                    print(error.localizedDescription)
                    completion(false)
                }
            }
        }
        codeTask.resume()
    }
}

class LeapQRCode: Codable {
    
    var owner: String?
    var platformType: String?
    var id: String?
    var type: String?
    var webUrl: String?
    var projectName: String?
    
    enum CodingKeys: String, CodingKey {
        case owner = "owner"
        case platformType = "platformType"
        case id = "id"
        case type = "type"
        case webUrl = "webUrl"
        case projectName = "projectName"
    }
    
    init() {
    }
    
    // MARK: - Decodable
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.owner = try container.decodeIfPresent(String.self, forKey: .owner)
        
        self.platformType = try container.decodeIfPresent(String.self, forKey: .platformType)
        
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
     
        self.webUrl = try container.decodeIfPresent(String.self, forKey: .webUrl)
        
        self.projectName = try container.decodeIfPresent(String.self, forKey: .projectName)
    }
    
    // MARK: - Encodable
    func encode(to encoder: Encoder) throws {
    }
}
