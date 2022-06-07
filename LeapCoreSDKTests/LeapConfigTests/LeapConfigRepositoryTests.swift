//
//  LeapConfigRepositoryTests.swift
//  LeapCoreSDKTests
//
//  Created by Ajay S on 08/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import XCTest
@testable import LeapCoreSDK

class LeapConfigRepositoryTests: XCTestCase {
    
    var mockLeapConfigRepository: MockLeapConfigRepository?
    
    weak var mockLeapConfigRepoDelegate: LeapConfigRepositoryDelegate?

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        mockLeapConfigRepository = MockLeapConfigRepository()
        mockLeapConfigRepoDelegate = mockLeapConfigRepository
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        mockLeapConfigRepository = nil
    }
    
    func testFetchConfigSuccess() {
        
        mockLeapConfigRepoDelegate?.fetchConfig(projectId: nil, completion: { config in
            XCTAssert(!config.isEmpty)
        })
    }
    
    func testFetchConfigUnauthorized() {
        mockLeapConfigRepository?.statusCode = .unauthorized
        mockLeapConfigRepoDelegate?.fetchConfig(projectId: nil, completion: { config in
            XCTAssert(config.isEmpty)
        })
    }
    
    func testFetchConfigFileNotFound() {
        mockLeapConfigRepository?.statusCode = .fileNotFound
        mockLeapConfigRepoDelegate?.fetchConfig(projectId: nil, completion: { config in
            XCTAssert(config.isEmpty)
        })
    }
    
    func testFetchConfigAnyFailure() {
        mockLeapConfigRepository?.statusCode = .badRequest
        guard let configString = UserDefaults.standard.value(forKey: "leap_config") as? String,
              let configData = configString.data(using: .utf8),
              let configDict = try? JSONSerialization.jsonObject(with: configData, options: .allowFragments) as? Dictionary<String,AnyHashable> else { return }
        mockLeapConfigRepoDelegate?.fetchConfig(projectId: nil, completion: { config in
            XCTAssert(config==configDict)
        })
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
