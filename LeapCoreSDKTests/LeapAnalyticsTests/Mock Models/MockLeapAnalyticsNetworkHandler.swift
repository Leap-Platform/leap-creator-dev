//
//  MockLeapAnalyticsNetworkHandler.swift
//  LeapCoreSDKTests
//
//  Created by Ajay S on 06/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
@testable import LeapCoreSDK

class MockLeapAnalyticsNetworkHandler: LeapAnalyticsNetworkHandlerDelegate {
    
    var isFailure = false
    
    weak var delegate: LeapEventsDelegate?
    
    func flushEvents(_ events: Array<Dictionary<String, String>>) {
        
        guard events.count > 0 else { return }
                
        NetworkUtils.makeMockURLRequest(statusCode: !isFailure ? 200 : 400) { [weak self] (result: Result<HTTPURLResponse, Error>) in
            switch result {
            case .success:
                print("\(events.count) events successfully sent")
                self?.delegate?.successfullySentEvents?(events: events)
            case .failure(let error): print(error.localizedDescription)
                print("\(events.count) events failed to send")
            }
        }
    }
}
