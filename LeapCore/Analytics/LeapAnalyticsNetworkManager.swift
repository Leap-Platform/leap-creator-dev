//
//  LeapAnalyticsNetworkManager.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 30/04/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

class LeapAnalyticsNetworkHandler {
    
    private let networkService = LeapNetworkService()
    
    weak var delegate: LeapEventsDelegate?
    
    private let prefs = UserDefaults.standard
    
    init(_ delegate: LeapEventsDelegate) {
        self.delegate = delegate
    }
    
    func flushEvents(_ events: Array<Dictionary<String, String>>) {
        
        guard events.count > 0 else { return }
        
        guard let req = createURLRequest(urlString: Constants.Networking.analyticsEndPoint), let analyticsURLRequest = addRequestBody(analyticsURLRequest: req, events: events) else {
            return
        }
        
        self.networkService.makeUrlRequest(analyticsURLRequest) { [weak self] (result: Result<ResponseData, RequestError>) in
            switch result {
            case .success(let (data, _)): print(data)
                print("\(events.count) events successfully sent")
                self?.delegate?.successfullySentEvents?(events: events)
            case .failure(let error): print(error.localizedDescription)
                print("\(events.count) events failed to send")
            }
        }
    }
    
    private func createURLRequest(urlString: String) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        getHeaders().forEach { (key, value) in
            req.addValue(value, forHTTPHeaderField: key)
        }
        return req
    }
    
    private func getHeaders() -> Dictionary<String, String> {
        guard let apiKey = LeapSharedInformation.shared.getAPIKey() else { return [:] }
        return [
            Constants.AnalyticsKeys.xLeapId: UIDevice.current.identifierForVendor?.uuidString ?? "",
            Constants.AnalyticsKeys.xJinyClientId: apiKey,
            Constants.AnalyticsKeys.contentTypeKey:Constants.AnalyticsKeys.contentTypeValue
        ]
    }
    
    private func addRequestBody(analyticsURLRequest: URLRequest, events: Array<Dictionary<String, String>>) -> URLRequest? {
        var req = analyticsURLRequest
        guard let jsonData = try? JSONSerialization.data(withJSONObject: events, options: .prettyPrinted) else {
            return nil
        }
        req.httpBody = jsonData
        return req
    }
}

struct Constants {
    struct Networking {
        static let isExecuting = "isExecuting"
        static let isFinished = "isFinished"
        static let downloadQ = "Leap Download Queue"
        static let dataQ = "Leap Data Queue"
        static let downloadsFolder = "Leap"
        static let analyticsEndPoint: String = {
            #if DEV
                return "https://odin-dev-gke.leap.is/odin/api/v1/analytics"
            #elseif STAGE
                return "https://odin-stage-gke.leap.is/odin/api/v1/analytics"
            #elseif PREPROD
                return "https://odin-preprod.leap.is/odin/api/v1/analytics"
            #elseif PROD
                return "https://odin.leap.is/odin/api/v1/analytics"
            #else
                return "https://odin.leap.is/odin/api/v1/analytics"
            #endif
        }()
    }
}

extension Constants {
    struct AnalyticsKeys {
        static let tempApiKey = "pBWmiQ8HCKllVJd2xQ5Cd7d5defd9e1e4f7a8882c34ff75f0d36"
        static let xClientId = "x-client-id"
        static let contentTypeKey = "Content-Type"
        static let contentTypeValue = "application/json"
        static let xLeapId = "x-leap-id"
        static let xJinyClientId = "x-jiny-client-id"
    }
}
