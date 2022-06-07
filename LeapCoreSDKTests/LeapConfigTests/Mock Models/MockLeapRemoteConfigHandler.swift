//
//  MockLeapConfigRemoteHandler.swift
//  LeapCoreSDKTests
//
//  Created by Ajay S on 08/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
@testable import LeapCoreSDK

class MockLeapRemoteConfigHandler: LeapRemoteHandlerDelegate {
    
    var statusCode: StatusCode = .success
    
    func fetchConfig(projectId: String?, completion: @escaping (Result<ResponseData, RequestError>?) -> Void) {
        
        var data = Data()
        
        if let path = Bundle(for: type(of: self)).path(forResource: "LeapConfig", ofType: "json") {
            do {
                data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                
              } catch {
                  let urlResponse: URLResponse = HTTPURLResponse(url: URL(string: "https://odin-dev-gke.leap.is/odin/api/v1/config/fetch") ?? URL(string: "localhost:8080")!, statusCode: 304, httpVersion: nil, headerFields: nil)!
                  completion(.failure(.clientError(response: urlResponse)))
                  return
              }
        }
        if statusCode == .success {
            let urlResponse: URLResponse = HTTPURLResponse(url: URL(string: "https://odin-dev-gke.leap.is/odin/api/v1/config/fetch") ?? URL(string: "localhost:8080")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            completion(.success(ResponseData(data: data, response: urlResponse)))
        } else if statusCode == .unauthorized {
            let urlResponse: URLResponse = HTTPURLResponse(url: URL(string: "https://odin-dev-gke.leap.is/odin/api/v1/config/fetch") ?? URL(string: "localhost:8080")!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            completion(.failure(.clientError(response: urlResponse)))
        } else if statusCode == .fileNotFound {
            let urlResponse: URLResponse = HTTPURLResponse(url: URL(string: "https://odin-dev-gke.leap.is/odin/api/v1/config/fetch") ?? URL(string: "localhost:8080")!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            completion(.failure(.serverError(response: urlResponse)))
        } else {
            let urlResponse: URLResponse = HTTPURLResponse(url: URL(string: "https://odin-dev-gke.leap.is/odin/api/v1/config/fetch") ?? URL(string: "localhost:8080")!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            completion(.failure(.serverError(response: urlResponse)))
        }
    }
}
