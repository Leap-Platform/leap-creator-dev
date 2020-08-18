//
//  JinyAnalyticsManager.swift
//  JinySDK
//
//  Created by Aravind GS on 28/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

@objc protocol JinyAnalyticsManagerDelegate {
    func failedToSendPayload(_ payload:Dictionary<String,Any> )
    func payloadSend(_ payload:Dictionary<String,Any>)
    func incorrectPayload(_ payload:Dictionary<String,Any>)
    @objc optional func getApiKey() -> String
}

class JinyAnalyticsManager {
    
    var delegate:JinyAnalyticsManagerDelegate
    var session:URLSession
    
    init(_ analyticsDelegate:JinyAnalyticsManagerDelegate) {
        delegate = analyticsDelegate
        session = URLSession.shared
    }
    
    func sendEvent(_ event:JinyAnalyticsEvent) {
        let urlString = Constants.Networking.analyticsEndPoint
        guard let url = URL(string: urlString) else { return }
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue(Constants.AnalyticsTemp.tempApiKey, forHTTPHeaderField: Constants.AnalyticsTemp.xClientId)
        urlRequest.addValue(Constants.AnalyticsTemp.contentTypeValue, forHTTPHeaderField: Constants.AnalyticsTemp.contentTypeKey)
        urlRequest.httpMethod = "POST"
        guard let payload = generatePayload(event) else { return }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) else {
            delegate.incorrectPayload(payload)
            return
        }
        urlRequest.httpBody = jsonData
        let analyticsTask = session.dataTask(with: urlRequest) { (data, urlResponse, error) in
            if error != nil { self.delegate.failedToSendPayload(payload) }
            else {
                if let res = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Dictionary<String,Any> {
                    print(res)
                }
                self.delegate.payloadSend(payload)
                
            }
        }
        analyticsTask.resume()
    }
    
    func generatePayload(_ event:JinyAnalyticsEvent) -> Dictionary<String,Any>? {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        guard let payloadData = try? jsonEncoder.encode(event) else { return nil }
        guard let payload = try? JSONSerialization.jsonObject(with: payloadData, options: .mutableContainers) as? Dictionary<String,Any> else { return nil }
        return payload
    }
    
}



extension Constants {
    struct AnalyticsTemp {
        static let tempApiKey = "pBWmiQ8HCKllVJd2xQ5Cd7d5defd9e1e4f7a8882c34ff75f0d36"
        static let xClientId = "x-client-id"
        static let contentTypeKey = "Content-Type"
        static let contentTypeValue = "application/json"
        static let timestampKey = ""
    }
}
