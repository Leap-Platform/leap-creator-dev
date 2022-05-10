//
//  MockLeapConfigRepository.swift
//  LeapCoreSDKTests
//
//  Created by Ajay S on 08/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
@testable import LeapCoreSDK

class MockLeapConfigRepository: LeapConfigRepositoryDelegate {
    
    let mockRemoteHandler = MockLeapRemoteConfigHandler()
    
    weak var mockRemoteHandlerDelegate: LeapRemoteHandlerDelegate?
    
    var leapConfigRepository: LeapConfigRepository?
    
    var statusCode: StatusCode = .success {
        didSet {
            mockRemoteHandler.statusCode = statusCode
        }
    }
    
    init() {
        mockRemoteHandlerDelegate = mockRemoteHandler
        leapConfigRepository = LeapConfigRepository(token: "")
    }
    
    func fetchConfig(projectId: String?, completion: ((Dictionary<String, AnyHashable>) -> Void)?) {
        
        mockRemoteHandlerDelegate?.fetchConfig(projectId: projectId, completion: { (result: Result<ResponseData, RequestError>?) in
            
            DispatchQueue.main.async {
                
                switch result {
                    
                case .success(let responseData):
                    
                    let configDict: Dictionary<String, AnyHashable> = {
                        let dict = try? JSONSerialization.jsonObject(with: responseData.data, options: .allowFragments) as? Dictionary<String, AnyHashable>
                        return dict ?? [:]
                    }()
                    
                    guard !configDict.isEmpty else { return }
                    
                    // make sure to set config before get config.
                    self.leapConfigRepository?.setConfig(projectId: projectId, configDict: configDict, response: responseData.response)
                    guard let config = self.leapConfigRepository?.getConfig(projectId: projectId) else {
                        completion?([:])
                        return
                    }
                    completion?(config)
                    
                case .failure(let requestErrorResponse):
                    
                    var failureResponse: URLResponse?
                    
                    switch(requestErrorResponse) {
                        
                    case let .clientError(response): failureResponse = response
                        
                    case let .serverError(response): failureResponse = response
                        
                    case .noData: print("Failure")
                        
                    case .dataDecodingError: print("Failure") }
                    
                    guard let failureResponse = failureResponse else { return }
                    
                    // make sure to set config before get config.
                    self.leapConfigRepository?.setConfig(projectId: projectId, response: failureResponse)
                    guard let config = self.leapConfigRepository?.getConfig(projectId: projectId) else {
                        completion?([:])
                        return
                    }
                    completion?(config)
                    
                    case .none: print("Failure") }
            }
        })
    }
}
