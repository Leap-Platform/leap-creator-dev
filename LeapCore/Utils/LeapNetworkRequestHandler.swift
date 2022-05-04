//
//  LeapNetworkRequestHandler.swift
//  LeapSDK
//
//  Created by Ajay S on 01/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation

protocol LeapNetworkRequestDelegate: AnyObject {
    
    func createNetworkRequest()
}

class LeapNetworkRequestHandler {
    
    weak var delegate: LeapNetworkRequestDelegate?
    
    init(_ requestDelegate: LeapNetworkRequestDelegate) {
        self.delegate = requestDelegate
    }
    
//    func getNetworkRequest() -> URLRequest? {
//        return delegate?.createNetworkRequest()
//    }
}
