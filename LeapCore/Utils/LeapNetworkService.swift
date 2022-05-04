//
//  LeapNetworkService.swift
//  LeapSDK
//
//  Created by Ajay S on 28/04/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation

enum RequestError: Error {
    case clientError(response: URLResponse?)
    case serverError(response: URLResponse?)
    case noData
    case dataDecodingError
}

typealias ResponseData = (data: Data, response: URLResponse)

class LeapNetworkService {
    
    func makeUrlRequest(_ request: URLRequest, resultHandler: @escaping (Result<ResponseData, RequestError>) -> Void) {
        
        guard let url = request.url else {
            resultHandler(.failure(.clientError(response: nil)))
            return
        }
        
        let session = SSLManager.shared.isValidForSSLPinning(urlString: url.absoluteString) ? SSLManager.shared.session : URLSession.shared
        
        let urlTask = session?.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                resultHandler(.failure(.clientError(response: response)))
                return
            }
            
            guard let response = response as? HTTPURLResponse, 200...299 ~= response.statusCode else {
                resultHandler(.failure(.serverError(response: response)))
                return
            }
            
            guard let data = data else {
                resultHandler(.failure(.noData))
                return
            }
            
            resultHandler(.success((data, response)))
            
//            let decoder = JSONDecoder()
//
//            guard let decodedData: T = try? decoder.decode(T.self, from: data) else {
//                resultHandler(.failure(.dataDecodingError))
//                return
//            }
//
//            resultHandler(.success(decodedData))
        }
        
        urlTask?.resume()
    }
}
