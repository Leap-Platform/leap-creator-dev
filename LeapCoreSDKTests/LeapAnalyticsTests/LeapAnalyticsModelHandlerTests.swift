//
//  LeapAnalyticsModelHandlerTests.swift
//  LeapCoreSDKTests
//
//  Created by Ajay S on 05/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import XCTest
@testable import LeapCoreSDK

class LeapAnalyticsModelHandlerTests: XCTestCase {
    
    var leapAnalyticsModelHandler: LeapAnalyticsModelHandler?
    var projectParameters: LeapProjectParameters?
    
    weak var delegate: LeapAnalyticsModelHandlerDelegate?

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        leapAnalyticsModelHandler = LeapAnalyticsModelHandler()
        delegate = leapAnalyticsModelHandler
        projectParameters = LeapProjectParameters(withDict: ["deploymentType": "testDeploymentType", "deploymentId": "testDeploymentId", "deploymentName": "testDeploymentName", "projectName": "testProjectName", "deploymentVersion": "testDeploymentVersion", "projectId": "testProjectId", "projectType": "testProjectType", "id": "1", "isEmbed": "false", "isEnabled": "false"])
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        leapAnalyticsModelHandler = nil
        projectParameters = nil
    }
    
    func testStartScreenEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", isProjectFlowMenu: false)
        let analyticsEvent = delegate?.startScreenEvent(with: analyticsModel)
        if (analyticsModel.isProjectFlowMenu) ?? false {
            XCTAssert(analyticsEvent?.eventName == "flow_menu_start")
        } else {
            XCTAssert(analyticsEvent?.eventName == "flow_start")
        }
    }
    
    func testOptInEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", isProjectFlowMenu: false)
        let analyticsEvent = delegate?.optInEvent(with: analyticsModel)
        XCTAssert(analyticsEvent?.eventName == "flow_opt_in")
    }
    
    func testOptOutEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", isProjectFlowMenu: false)
        let analyticsEvent = delegate?.optOutEvent(with: analyticsModel)
        XCTAssert(analyticsEvent?.eventName == "flow_opt_out")
    }
    
    func testInstructionEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", isProjectFlowMenu: false)
        let analyticsEvent = delegate?.instructionEvent(with: analyticsModel)
        XCTAssert(analyticsEvent?.eventName == "element_seen")
    }
    
    func testAssistInstructionEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", isProjectFlowMenu: false)
        let analyticsEvent = delegate?.assistInstructionEvent(with: analyticsModel)
        XCTAssert(analyticsEvent?.eventName == "element_seen")
    }
    
    func testFlowSuccessEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", isProjectFlowMenu: false)
        let analyticsEvent = delegate?.flowSuccessEvent(with: analyticsModel)
        XCTAssert(analyticsEvent?.eventName == "flow_success")
    }
    
    func testFlowStopEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters)
        let analyticsEvent = delegate?.flowStopEvent(with: analyticsModel)
        XCTAssert(analyticsEvent?.eventName == "flow_stop")
    }
    
    func testFlowDisableEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters)
        let analyticsEvent = delegate?.flowDisableEvent(with: analyticsModel)
        XCTAssert(analyticsEvent?.eventName == "flow_disable")
    }
    
    func testLanguageChangeEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, previousLanguage: "hin", currentLanguage: "eng")
        let analyticsEvent = delegate?.languageChangeEvent(with: analyticsModel)
        XCTAssert(analyticsEvent?.language != analyticsEvent?.previousLanguage)
        XCTAssert(analyticsEvent?.eventName == "flow_language_change")
    }
    
    func testAUIActionTrackingEvent() {
        let action = ["body": ["":""]]
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", action: action)
        let analyticsEvent = delegate?.auiActionTrackingEvent(with: analyticsModel)
        XCTAssert(analyticsEvent?.eventName == "element_action")
    }
    
    func testLeapSDKDisableEvent() {
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2")
        let analyticsEvent = delegate?.leapSDKDisableEvent(with: analyticsModel)
        XCTAssert(analyticsEvent?.eventName == "leap_sdk_disable")
    }
    
    func testProjectTerminationEvent() {
        projectParameters?.deploymentType = "LINK"
        let analyticsModel = LeapAnalyticsModel(projectParameter: projectParameters, instructionId: "2", terminationRule: "")
        let analyticsEvent = delegate?.projectTerminationEvent(with: analyticsModel)
        XCTAssert(analyticsEvent?.eventName == "project_termination")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
