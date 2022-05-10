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
    
    weak var delegate: LeapAnalyticsDelegate?

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        leapAnalyticsManager = LeapAnalyticsManager()
        delegate = leapAnalyticsManager
        projectParameters = LeapProjectParameters(withDict: ["deploymentType": "testDeploymentType", "deploymentId": "testDeploymentId", "deploymentName": "testDeploymentName", "projectName": "testProjectName", "deploymentVersion": "testDeploymentVersion", "projectId": "testProjectId", "projectType": "testProjectType", "id": "1", "isEmbed": "false", "isEnabled": "false"])
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        leapAnalyticsManager = nil
        projectParameters = nil
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
