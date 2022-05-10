//
//  NetworkUtils.swift
//  LeapCoreSDKTests
//
//  Created by Ajay S on 08/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation

class NetworkUtils {
    
    static func makeMockURLRequest(statusCode: Int, resultHandler: @escaping (Result<HTTPURLResponse, Error>) -> Void) {
        let stubbedResponse = HTTPURLResponse(url: URL(string: getURL(failure: statusCode==200).url) ?? URL(string: "localhost:8080")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        if statusCode == 200 {
            resultHandler(.success(stubbedResponse))
        }
    }
    
    static func getURL(failure: Bool) -> (url: String, failure: Bool) {
        if failure {
            return (url: "https://www.xgoogle.com", failure: true)
        } else {
            return (url: "https://odin-stage-gke.leap.is/odin/api/v1/analytics", failure: false)
        }
    }
}
