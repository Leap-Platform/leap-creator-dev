//
//  LeapAnalyticsManagerTests.swift
//  LeapCoreSDKTests
//
//  Created by Ajay S on 04/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import XCTest
@testable import LeapCoreSDK

class LeapAnalyticsManagerTests: XCTestCase {
    
    var leapAnalyticsManager: LeapAnalyticsManager?
    var projectParameters: LeapProjectParameters?
    
    weak var analyticsManagerDelegate: LeapAnalyticsDelegate?

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        leapAnalyticsManager = LeapAnalyticsManager()
        analyticsManagerDelegate = leapAnalyticsManager
        projectParameters = LeapProjectParameters(withDict: ["deploymentType": "testDeploymentType", "deploymentId": "testDeploymentId", "deploymentName": "testDeploymentName", "projectName": "testProjectName", "deploymentVersion": "testDeploymentVersion", "projectId": "testProjectId", "projectType": "testProjectType", "id": "1", "isEmbed": "false", "isEnabled": "false"])
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        leapAnalyticsManager = nil
        projectParameters = nil
    }
    
    func testQueueStartScreenEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", isProjectFlowMenu: false)
        analyticsManagerDelegate?.queue(event: .startScreenEvent, for: analyticsModel)
        let savedEvents = UserDefaults.standard.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(savedEvents.first?["eventName"] == "flow_start")
    }
    
    func testQueueOptInEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", isProjectFlowMenu: false)
        analyticsManagerDelegate?.queue(event: .optInEvent, for: analyticsModel)
        let savedEvents = UserDefaults.standard.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(savedEvents.first?["eventName"] == "flow_opt_in")
    }
    
    func testQueueOptOutEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", isProjectFlowMenu: false)
        analyticsManagerDelegate?.queue(event: .optOutEvent, for: analyticsModel)
        let savedEvents = UserDefaults.standard.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(savedEvents.first?["eventName"] == "flow_opt_out")
    }
    
    func testQueueInstructionEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", isProjectFlowMenu: false)
        analyticsManagerDelegate?.queue(event: .instructionEvent, for: analyticsModel)
        let savedEvents = UserDefaults.standard.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(savedEvents.first?["eventName"]  == "element_seen")
    }
    
    func testQueueAssistInstructionEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", isProjectFlowMenu: false)
        analyticsManagerDelegate?.queue(event: .assistInstructionEvent, for: analyticsModel)
        let savedEvents = UserDefaults.standard.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(savedEvents.first?["eventName"]  == "element_seen")
    }
    
    func testQueueFlowSuccessEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", isProjectFlowMenu: false)
        analyticsManagerDelegate?.queue(event: .flowSuccessEvent, for: analyticsModel)
        let savedEvents = UserDefaults.standard.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(savedEvents.first?["eventName"]  == "flow_success")
    }
    
    func testQueueFlowStopEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters)
        analyticsManagerDelegate?.queue(event: .flowStopEvent, for: analyticsModel)
        let savedEvents = UserDefaults.standard.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(savedEvents.first?["eventName"]  == "flow_stop")
    }
    
    func testQueueFlowDisableEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters)
        analyticsManagerDelegate?.queue(event: .flowDisableEvent, for: analyticsModel)
        let savedEvents = UserDefaults.standard.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(savedEvents.first?["eventName"]  == "flow_disable")
    }
    
    func testQueueLanguageChangeEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, previousLanguage: "hin", currentLanguage: "eng")
        analyticsManagerDelegate?.queue(event: .languageChangeEvent, for: analyticsModel)
        let savedEvents = UserDefaults.standard.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(savedEvents.first?["eventName"]  == "flow_language_change")
    }
    
    func testQueueAUIActionTrackingEvent() {
        let action = ["body": ["":""]]
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", action: action)
        analyticsManagerDelegate?.queue(event: .actionTrackingEvent, for: analyticsModel)
        let savedEvents = UserDefaults.standard.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(savedEvents.first?["eventName"]  == "element_action")
    }
    
    func testQueueLeapSDKDisableEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2")
        analyticsManagerDelegate?.queue(event: .leapSdkDisableEvent, for: analyticsModel)
        let savedEvents = UserDefaults.standard.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(savedEvents.first?["eventName"]  == "leap_sdk_disable")
    }
    
    func testQueueProjectTerminationEvent() {
        projectParameters?.deploymentType = "LINK"
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", terminationRule: "")
        analyticsManagerDelegate?.queue(event: .projectTerminationEvent, for: analyticsModel)
        let savedEvents = UserDefaults.standard.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(savedEvents.first?["eventName"] == "project_termination")
    }
    
    func testFlushPendingEvents() {
        leapAnalyticsManager?.flushPendingEvents()
        let savedEvents = UserDefaults.standard.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(savedEvents.isEmpty)
        let eventsToFlush = UserDefaults.standard.object(forKey: "leap_flush_events") as? Array<Dictionary<String, String>> ?? []
        XCTAssert(!eventsToFlush.isEmpty)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
