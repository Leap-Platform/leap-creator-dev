//
//  LeapAnalyticsNetworkHandlerTests.swift
//  LeapCoreSDKTests
//
//  Created by Ajay S on 06/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import XCTest
@testable import LeapCoreSDK

class LeapAnalyticsNetworkHandlerTests: XCTestCase {
    
    weak var networkHandlerDelegate: LeapAnalyticsNetworkHandlerDelegate?
    
    var mockAnalyticsNetworkHandler: MockLeapAnalyticsNetworkHandler?
    
    let analyticsManager = LeapAnalyticsManager()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        mockAnalyticsNetworkHandler = MockLeapAnalyticsNetworkHandler()
        networkHandlerDelegate = mockAnalyticsNetworkHandler
        mockAnalyticsNetworkHandler?.delegate = analyticsManager
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        mockAnalyticsNetworkHandler = nil
    }
    
    func testFlushEventsSuccess() {
        let events = [["a":"b", "c":"d"]]
        self.networkHandlerDelegate?.flushEvents(events)
        let flushedEvents = UserDefaults.standard.object(forKey: "leap_flush_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(flushedEvents.count<=0)
    }
    
    func testFlushEventsFailure() {
        mockAnalyticsNetworkHandler?.isFailure = true
        let events = [["a":"b", "c":"d"]]
        self.networkHandlerDelegate?.flushEvents(events)
        let flushedEvents = UserDefaults.standard.object(forKey: "leap_flush_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(flushedEvents.count>0)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
