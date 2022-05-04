//
//  LeapAnalyticsEvent.swift
//  LeapCore
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

enum EventName: String {
    case flowMenuStartScreen = "flow_menu_start"
    case startScreenEvent = "flow_start"
    case optInEvent = "flow_opt_in"
    case optOutEvent = "flow_opt_out"
    case instructionEvent = "element_seen"
    case assistInstructionEvent // both instructionEvent and assistInstructionEvent have same values, no need of unique value.
    case flowSuccessEvent = "flow_success"
    case flowStopEvent = "flow_stop"
    case flowDisableEvent = "flow_disable"
    case languageChangeEvent = "flow_language_change"
    case actionTrackingEvent = "element_action"
    case leapSdkDisableEvent = "leap_sdk_disable"
    case projectTerminationEvent = "project_termination"
}

class LeapAnalyticsEvent: Codable {
    
    var id: String?
    var sessionId: String?
    var parentProjectName: String?
    var projectName: String?
    var parentProjectId: String?
    var projectId: String?
    var deploymentId: String?
    var deploymentName: String?
    var parentDeploymentVersion: String?
    var deploymentVersion: String?
    var previousLanguage: String?
    var language: String?
    var timestamp: String?
    var eventName: String?
    var pageName: String?
    var elementName: String?
    var actionEventType: String?
    var actionEventValue: String?
    var terminationRule: String?
    var selectedProjectId: String?
    var selectedFlow: String? // name of the selected flow
    
    init(withEvent eventName: EventName, withParams projectParams: LeapProjectParameters) {
        self.id = String.generateUUIDString()
        self.sessionId = LeapSharedInformation.shared.getSessionId()
        self.timestamp = LeapAnalyticsEvent.getTimeStamp()
        self.deploymentId = projectParams.deploymentId
        self.deploymentVersion = projectParams.deploymentVersion
        self.projectId = projectParams.projectId
        self.projectName = projectParams.projectName
        self.deploymentName = projectParams.deploymentName
        self.eventName = eventName.rawValue
        self.language = LeapPreferences.shared.getUserLanguage()
    }
    
    private static func getTimeStamp() -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let date = Date()
        let timeStamp = dateFormatter.string(from: date)
        return timeStamp
    }
}
