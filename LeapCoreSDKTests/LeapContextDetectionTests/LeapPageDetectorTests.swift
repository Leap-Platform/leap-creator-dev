//
//  LeapPageDetectorTests.swift
//  LeapCoreSDKTests
//
//  Created by Aravind GS on 10/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import XCTest
@testable import LeapCoreSDK

class LeapPageDetectorTests: XCTestCase {
    
    let hierarchy = LeapTestHierarchyGenerator().getModelHierarchy()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func testPageValidationWithOnePassingAndTwoFailing() {
        let config = LeapTestConfigGenerator().getOneDiscoveryPassingConfig()
        let pageValidator = LeapContextsValidator<LeapPage>(withNativeDict: config.nativeIdentifiers, webDict: config.webIdentifiers)
        pageValidator.findValidContextsIn(hierarchy, contexts: config.flows.first!.pages) { validPages in
            XCTAssertTrue(validPages.count == 1)
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

}
