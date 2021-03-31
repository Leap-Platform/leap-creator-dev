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
    case triggerEvent = "trigger_event"
    case optInEvent = "opt_in_event"
    case optOutEvent = "opt_out_event"
    case instructionEvent = "instruction_event"
    case flowSuccessEvent = "flow_success_event"
    case flowStopEvent = "flow_stop_event"
    case flowDisableEvent = "flow_disable_event"
    case languageChangeEvent = "language_change_event"
    case actionTrackingEvent = "action_tracking_event"
    case leapSdkDisableEvent = "leap_sdk_disable_event"
}

class LeapAnalyticsEvent: Codable {
    
    var id: String?
    var sessionId: String?
    var projectName: String?
    var projectId: String?
    var deploymentId: String?
    var deploymentName: String?
    var previousLanguage: String?
    var language: String?
    var timestamp: String?
    var eventName: String?
    var pageName: String?
    var instructionName: String?
    var actionEventType: String?
    var actionEventValue: String?
    
    init() {
        self.id = String.generateUUIDString()
        self.sessionId = LeapSharedInformation.shared.getSessionId()
        self.timestamp = LeapAnalyticsEvent.getTimeStamp()
    }
    
    private static func getTimeStamp() -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let date = Date()
        let timeStamp = dateFormatter.string(from: date)
        return timeStamp
    }
}
