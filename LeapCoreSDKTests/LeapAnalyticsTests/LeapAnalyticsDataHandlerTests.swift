//
//  LeapAnalyticsDataHandlerTests.swift
//  LeapCoreSDKTests
//
//  Created by Ajay S on 05/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import XCTest
@testable import LeapCoreSDK

class LeapAnalyticsDataHandlerTests: XCTestCase {
    
    var leapAnalyticsDataHandler: LeapAnalyticsDataHandler?
    var leapAnalyticsManager: LeapAnalyticsManager?
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        leapAnalyticsManager = LeapAnalyticsManager()
        leapAnalyticsDataHandler = LeapAnalyticsDataHandler(leapAnalyticsManager!)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        leapAnalyticsManager = nil
        leapAnalyticsDataHandler = nil
    }
    
    func testSaveEvent() {
        let event = LeapAnalyticsEvent(withEvent: .startScreenEvent, withParams: LeapProjectParameters(withDict: [:]))
        leapAnalyticsDataHandler?.saveEvent(event: event)
        let savedEvents = leapAnalyticsDataHandler?.prefs.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(savedEvents.first?["eventName"] == "flow_start")
    }
    
    func testGetEventsToFlush() {
        let events = [["a":"b"], ["c":"d"], ["e":"f"], ["g":"h"], ["i":"j"]]
        _ = leapAnalyticsDataHandler?.prefs.set(events, forKey: "leap_saved_events")
        let savedEvents = leapAnalyticsDataHandler?.prefs.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        let eventsToFlush = leapAnalyticsDataHandler?.getEventsToFlush()
        XCTAssert(savedEvents.count>=5 ? (eventsToFlush?.count ?? 0) > 0 : eventsToFlush==nil)
    }
    
    func testDeleteFlushedEvents() {
        let events = [["":""]]
        _ = leapAnalyticsDataHandler?.prefs.set(events, forKey: "leap_flush_events")
        leapAnalyticsDataHandler?.prefs.synchronize()
        self.leapAnalyticsDataHandler?.deleteFlushedEvents()
        let pendingEvents = self.leapAnalyticsDataHandler?.prefs.object(forKey: "leap_flush_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(pendingEvents.count <= 0)
    }
    
    func testSendClientCallbackEvent() {
        let deploymentId = "222"
        let projectParameter = LeapProjectParameters(withDict: ["deploymentType": constant_LINK, "deploymentId": deploymentId, "deploymentName": "testDeploymentName", "projectName": "testProjectName", "deploymentVersion": "testDeploymentVersion", "projectId": "testProjectId", "projectType": "testProjectType", "id": "1", "isEmbed": "false", "isEnabled": "false"])
        
        let event = LeapAnalyticsEvent(withEvent: .startScreenEvent, withParams: projectParameter)
        event.parentProjectId = "2"
        event.selectedProjectId = "1"
        
        leapAnalyticsDataHandler?.sendClientCallbackEvent(event: event, projectParameter: projectParameter, isProjectFlowMenu: false)
        
        XCTAssert(event.projectId==deploymentId)
        XCTAssert(event.selectedProjectId==nil)
        XCTAssert(event.parentProjectId==nil)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
