//
//  LeapContextDetectorTests.swift
//  LeapCoreSDKTests
//
//  Created by Aravind GS on 08/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import XCTest
@testable import LeapCoreSDK

class LeapContextDetectorTests: XCTestCase {
    let hierarchy:[String:LeapViewProperties] = LeapTestHierarchyGenerator().getModelHierarchy()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }
    
    func testAssistOrDiscoveryBothPassing() {
        let config = LeapTestConfigGenerator().getOneAssistAndOneDiscoveryPassingConfig()
        let allContexts = config.assists + config.discoveries
        let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: config.nativeIdentifiers, webDict: config.webIdentifiers)
        contextValidator.findValidContextsIn(hierarchy, contexts: allContexts) { validContexts in
            XCTAssertEqual(allContexts, validContexts)
        }
    }
    
    func testTriggerableContextForChoosingAssist() {
        let config = LeapTestConfigGenerator().getOneAssistAndOneDiscoveryPassingConfig()
        let allContexts = config.assists + config.discoveries
        let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: config.nativeIdentifiers, webDict: config.webIdentifiers)
        contextValidator.findValidContextsIn(hierarchy, contexts: allContexts) { validContexts in
            contextValidator.getTriggerableContext(nil, validContexts: validContexts, hierarchy: self.hierarchy) { contextToTrigger, anchorViewId, anchorRect, anchorWebview in
                XCTAssertEqual(config.assists.first!, contextToTrigger!)
            }
        }
    }
    
    func testNoContextToCheck() {
        let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: [:], webDict: [:])
        contextValidator.findValidContextsIn(hierarchy, contexts: []) { validContexts in
            XCTAssertEqual(validContexts, [])
        }
    }
    
    func testLiveContextPresentInValidContexts() {
        let config = LeapTestConfigGenerator().getOneAssistAndOneDiscoveryPassingConfig()
        let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: config.nativeIdentifiers, webDict: config.webIdentifiers)
        let liveContext = config.assists.first!
        let contextToCheck = config.assists + config.discoveries
        contextValidator.findValidContextsIn(hierarchy, contexts: contextToCheck) {[weak self] validContexts in
            contextValidator.getTriggerableContext(liveContext, validContexts: validContexts, hierarchy: self?.hierarchy ?? [:]) { contextToTrigger, anchorViewId, anchorRect, anchorWebview in
                XCTAssertNotNil(contextToTrigger)
                XCTAssertEqual(liveContext, contextToTrigger)
            }
        }
    }
    
    func testLiveContextNotInValidContexts() {
        let config = LeapTestConfigGenerator().getOneAssistAndOneDiscoveryPassingConfig()
        let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: config.nativeIdentifiers, webDict: config.webIdentifiers)
        let liveContext = config.assists.first!
        let contextsToCheck = config.discoveries
        contextValidator.findValidContextsIn(hierarchy, contexts: contextsToCheck) {[weak self] validContexts in
            contextValidator.getTriggerableContext(liveContext, validContexts: validContexts, hierarchy: self?.hierarchy ?? [:]) { contextToTrigger, anchorViewId, anchorRect, anchorWebview in
                XCTAssertNotEqual(contextToTrigger, liveContext)
            }
        }
    }
    
    func testNoValidContextsGettingTriggerableContext() {
        let config = LeapTestConfigGenerator().getOneAssistAndOneDiscoveryPassingConfig()
        let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: config.nativeIdentifiers, webDict: config.webIdentifiers)
        contextValidator.getTriggerableContext(nil, validContexts: [], hierarchy: hierarchy) { contextToTrigger, anchorViewId, anchorRect, anchorWebview in
            XCTAssertNil(contextToTrigger)
        }
    }
    
    func testValidLiveContextWithMissingIdentifier() {
        let config = LeapTestConfigGenerator().getOneAssistAndOneDiscoveryPassingConfig()
        let allContexts = config.discoveries + config.assists
        let liveContext = config.assists.first!
        liveContext.instruction?.assistInfo?.identifier = "Incorrect Identifier"
        let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: config.nativeIdentifiers, webDict: config.webIdentifiers)
        contextValidator.getTriggerableContext(liveContext, validContexts: allContexts, hierarchy: hierarchy) { contextToTrigger, anchorViewId, anchorRect, anchorWebview in
            XCTAssertNotEqual(liveContext, contextToTrigger)
        }
        
    }
    
    func testNoLiveContextWithValidContexts () {
        let config = LeapTestConfigGenerator().getOneAssistAndOneDiscoveryPassingConfig()
        let allContexts = config.discoveries + config.assists
        let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: config.nativeIdentifiers, webDict: config.webIdentifiers)
        contextValidator.findValidContextsIn(hierarchy, contexts: allContexts) {[weak self] validContexts in
            contextValidator.getTriggerableContext(nil, validContexts: validContexts, hierarchy: self?.hierarchy ?? [:]) { contextToTrigger, anchorViewId, anchorRect, anchorWebview in
                XCTAssertNotNil(contextToTrigger)
                XCTAssertEqual(contextToTrigger, config.assists.first)
            }
        }
    }
    
    func testOneContextPassingAndOneContextFailing() {
        let config = LeapTestConfigGenerator().getOneContextPassingAndOneContextFailingConfig()
        let allContexts = config.discoveries + config.assists
        let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: config.nativeIdentifiers, webDict: config.webIdentifiers)
        contextValidator.findValidContextsIn(hierarchy, contexts: allContexts) { validContexts in
            XCTAssertTrue(allContexts.count > 1)
            XCTAssertTrue(validContexts.count == 1)
        }
    }
    
    func testValidLiveContextButFailingIdentifier() {
        let config = LeapTestConfigGenerator().getOneContextPassingAndOneContextFailingConfig()
        let allContexts = config.discoveries + config.assists
        let liveContext = config.assists.first!
        liveContext.instruction?.assistInfo?.identifier = "Incorrect identifier"
        let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: config.nativeIdentifiers, webDict: config.webIdentifiers)
        contextValidator.getTriggerableContext(liveContext, validContexts: allContexts, hierarchy: hierarchy) { contextToTrigger, anchorViewId, anchorRect, anchorWebview in
            XCTAssertNotEqual(contextToTrigger, liveContext)
        }
    }
    
    func testLiveContextValidNotTriggerable() {
        let config = LeapTestConfigGenerator().getTwoAssistPassingConfig()
        let allContexts = config.assists + config.discoveries
        let liveContext = config.assists.first!
        liveContext.instruction!.assistInfo!.identifier = "Incorrect identifier"
        let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: config.nativeIdentifiers, webDict: config.webIdentifiers)
        contextValidator.getTriggerableContext(liveContext, validContexts: allContexts, hierarchy: hierarchy) { contextToTrigger, anchorViewId, anchorRect, anchorWebview in
            XCTAssertNotNil(contextToTrigger)
            XCTAssertNotEqual(contextToTrigger, liveContext)
        }
    }
    
    func testHighestPreferenceByWeight() {
        let config = LeapTestConfigGenerator().getTwoAssistPassingConfig()
        let allContexts = config.assists + config.discoveries
        let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: config.nativeIdentifiers, webDict: config.webIdentifiers)
        contextValidator.findValidContextsIn(hierarchy, contexts: allContexts) {[weak self] validContexts in
            XCTAssertEqual(allContexts, validContexts)
            contextValidator.getTriggerableContext(nil, validContexts: validContexts, hierarchy: self?.hierarchy ?? [:]) { contextToTrigger, anchorViewId, anchorRect, anchorWebview in
                XCTAssertEqual(contextToTrigger!.weight, 2)
            }
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

}
