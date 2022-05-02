//
//  LeapAnalyticsDataManager.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 30/04/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation

struct LeapAnalyticsModel {
    
    var projectParameter: LeapProjectParameters?
    var instructionId: String?
    var previousLanguage: String?
    var currentLanguage: String?
    var action: Dictionary<String, Any>?
    var terminationRule: String?
    
    init(projectParameter: LeapProjectParameters?, instructionId: String? = nil, previousLanguage: String? = nil, currentLanguage: String? = nil, action: Dictionary<String, Any>? = nil, terminationRule: String? = nil) {
        
        self.projectParameter = projectParameter
        self.instructionId = instructionId
        self.previousLanguage = previousLanguage
        self.currentLanguage = currentLanguage
        self.action = action
        self.terminationRule = terminationRule
    }
}

// MARK: - CREATE ANALYTICS EVENTS
class LeapAnalyticsModelHandler {
    
    private var lastEventId: String?
    private var lastEventLanguage: String?
    
    weak var delegate: LeapAnalyticsManagerDelegate?
    
    init(_ delegate: LeapAnalyticsManagerDelegate) {
        self.delegate = delegate
    }
    
    func startScreenEvent(with analytics: LeapAnalyticsModel) -> LeapAnalyticsEvent? {
        guard let projectParameter = analytics.projectParameter else { return nil }
        if lastEventId == analytics.instructionId && lastEventLanguage == LeapPreferences.shared.getUserLanguage() {
            return nil
        }
        let event = LeapAnalyticsEvent(withEvent: EventName.startScreenEvent, withParams: projectParameter)
        lastEventId = analytics.instructionId
        lastEventLanguage = event.language
        if !(delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false) {
            event.parentProjectId = delegate?.getCurrentFlowMenu()?.projectId // flow menu projectId if there is parent
            event.parentProjectName = delegate?.getCurrentFlowMenu()?.projectName
            event.parentDeploymentVersion = delegate?.getCurrentFlowMenu()?.deploymentVersion
            print("Start Screen")
        } else {
            event.eventName = EventName.flowMenuStartScreen.rawValue
            print("FlowMenu Start Screen")
        }
        return event
    }
    
    func optInEvent(with analytics: LeapAnalyticsModel) -> LeapAnalyticsEvent? {
        guard let projectParameter = analytics.projectParameter else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.optInEvent, withParams: projectParameter)
        if delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false {
            event.selectedProjectId = delegate?.getCurrentSubFlow()?.projectId // subflow projectId
            event.selectedFlow = delegate?.getCurrentSubFlow()?.projectName // subflow's name
            print("FlowMenu Opt In")
        } else {
            event.parentProjectId = delegate?.getCurrentFlowMenu()?.projectId // flow menu projectId if there is parent
            event.parentProjectName = delegate?.getCurrentFlowMenu()?.projectName
            event.parentDeploymentVersion = delegate?.getCurrentFlowMenu()?.deploymentVersion
            print("Opt In")
        }
        return event
    }
    
    func optOutEvent(with analytics: LeapAnalyticsModel) -> LeapAnalyticsEvent? {
        guard let projectParameter = analytics.projectParameter else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.optOutEvent, withParams: projectParameter)
        lastEventId = nil
        print("Opt out")
        return event
    }
    
    func instructionEvent(with analytics: LeapAnalyticsModel) -> LeapAnalyticsEvent? {
        guard let projectParameter = analytics.projectParameter else { return nil }
        if lastEventId == analytics.instructionId && lastEventLanguage == LeapPreferences.shared.getUserLanguage() {
            return nil
        }
        let event = LeapAnalyticsEvent(withEvent: EventName.instructionEvent, withParams: projectParameter)
        lastEventId = analytics.instructionId
        lastEventLanguage = event.language
        event.elementName = delegate?.getCurrentStage()?.name
        event.pageName = delegate?.getCurrentPageForAnalytics()?.name
        
        event.parentProjectId = delegate?.getCurrentFlowMenu()?.projectId // flow menu projectId if there is parent
        event.parentProjectName = delegate?.getCurrentFlowMenu()?.projectName
        event.parentDeploymentVersion = delegate?.getCurrentFlowMenu()?.deploymentVersion
        event.selectedFlow = delegate?.getCurrentFlowMenu() != nil ? delegate?.getCurrentSubFlow()?.projectName : nil // subflow's name
        print("element seen")
        return event
    }
    
    func assistInstructionEvent(with analytics: LeapAnalyticsModel) -> LeapAnalyticsEvent? {
        guard let projectParameter = analytics.projectParameter else { return nil }
        if lastEventId == analytics.instructionId && lastEventLanguage == LeapPreferences.shared.getUserLanguage() {
            return nil
        }
        // Use EventName.instructionEvent. Do not use EventName.assistInstructionEvent as it doesn't have a different raw value.
        let event = LeapAnalyticsEvent(withEvent: EventName.instructionEvent, withParams: projectParameter)
        lastEventId = analytics.instructionId
        lastEventLanguage = event.language
        event.elementName = delegate?.getCurrentAssist()?.name
        print("assist element seen")
        return event
    }
    
    func flowSuccessEvent(with analytics: LeapAnalyticsModel) -> LeapAnalyticsEvent? {
        guard let projectParameter = analytics.projectParameter else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.flowSuccessEvent, withParams: projectParameter)
        event.parentProjectId = delegate?.getCurrentFlowMenu()?.projectId // flow menu projectId if there is parent
        event.parentProjectName = delegate?.getCurrentFlowMenu()?.projectName
        event.parentDeploymentVersion = delegate?.getCurrentFlowMenu()?.deploymentVersion
        event.selectedFlow = delegate?.getCurrentFlowMenu() != nil ? delegate?.getCurrentSubFlow()?.projectName : nil // subflow's name
        print("flow success")
        return event
    }
    
    func flowStopEvent(with analytics: LeapAnalyticsModel) -> LeapAnalyticsEvent? {
        guard let projectParameter = analytics.projectParameter else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.flowStopEvent, withParams: projectParameter)
        event.elementName = delegate?.getCurrentStage()?.name
        event.pageName = delegate?.getCurrentPageForAnalytics()?.name
        print("flow stop")
        return event
    }
    
    func flowDisableEvent(with analytics: LeapAnalyticsModel) -> LeapAnalyticsEvent? {
        guard let projectParameter = analytics.projectParameter else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.flowDisableEvent, withParams: projectParameter)
        print("flow disable")
        return event
    }
    
    func languageChangeEvent(with analytics: LeapAnalyticsModel) -> LeapAnalyticsEvent? {
        guard let projectParameter = analytics.projectParameter else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.languageChangeEvent, withParams: projectParameter)
        event.language = analytics.currentLanguage
        event.previousLanguage = analytics.previousLanguage
        print("Language change")
        return event
    }
    
    func auiActionTrackingEvent(with analytics: LeapAnalyticsModel) -> LeapAnalyticsEvent? {
        guard let projectParameter = analytics.projectParameter else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.actionTrackingEvent, withParams: projectParameter)
        
        guard let body = analytics.action?[constant_body] as? Dictionary<String, Any> else { return nil }
        
        if let id = body[constant_id] as? String {
            
            if lastEventId == id { return nil }
            
            lastEventId = id
        }
        
        if let labelValue = body[constant_buttonLabel] as? String {
            event.actionEventValue = labelValue
        }
        // cases for actionEventType
        if let _ = body[constant_externalLink] as? Bool {
            event.actionEventType = constant_externalLink
        } else if let _ = body[constant_deepLink] as? Bool {
            event.actionEventType = constant_deepLink
        } else if let _ = body[constant_endFlow] as? Bool {
            event.actionEventType = constant_endFlow
        } else if let _ = body[constant_close] as? Bool {
            event.actionEventType = constant_close
        } else if let _ = body[constant_anchorClick] as? Bool {
            event.actionEventType = constant_anchorClick
            event.actionEventValue = nil
        }
        
        event.elementName = delegate?.getCurrentStage()?.name ?? delegate?.getCurrentAssist()?.name
        event.pageName = delegate?.getCurrentPageForAnalytics()?.name
        
        event.parentProjectId = delegate?.getCurrentFlowMenu()?.projectId // flow menu projectId if there is parent
        event.parentProjectName = delegate?.getCurrentFlowMenu()?.projectName
        event.parentDeploymentVersion = delegate?.getCurrentFlowMenu()?.deploymentVersion
        event.selectedFlow = delegate?.getCurrentFlowMenu() != nil ? delegate?.getCurrentSubFlow()?.projectName : nil // subflow's name
        print("AUI action tracking")
        return event
    }
    
    func leapSDKDisableEvent(with analytics: LeapAnalyticsModel) -> LeapAnalyticsEvent? {
        guard let projectParameter = analytics.projectParameter else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.leapSdkDisableEvent, withParams: projectParameter)
        event.language = nil
        print("Leap SDK disable")
        return event
    }
    
    func projectTerminationEvent(with analytics: LeapAnalyticsModel) -> LeapAnalyticsEvent? {
        guard let projectParameter = analytics.projectParameter, projectParameter.deploymentType == constant_LINK else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.projectTerminationEvent, withParams: projectParameter)
        event.terminationRule = analytics.terminationRule
        print("Project Termination")
        return event
    }
}

class LeapAnalyticsDataHandler {
    
    private let MAX_COUNT = 5
    
    weak var delegate: LeapAnalyticsManagerDelegate?
    
    let prefs = UserDefaults.standard
    
    init(_ delegate: LeapAnalyticsManagerDelegate) {
        self.delegate = delegate
    }
    
    private func generatePayload(_ event: LeapAnalyticsEvent) -> Dictionary<String, String>? {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        guard let payloadData = try? jsonEncoder.encode(event) else { return nil }
        guard let payload = try? JSONSerialization.jsonObject(with: payloadData, options: .mutableContainers) as? Dictionary<String, String> else { return nil }
        return payload
    }
    
    func saveEvent(event: LeapAnalyticsEvent?) {
        guard let event = event, let payload = generatePayload(event) else { return }
        print("SDK - \(payload)")
        
        var savedEvents = prefs.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        savedEvents.append(payload)
        prefs.set(savedEvents, forKey: "leap_saved_events")
        prefs.synchronize()
    }
    
    func sendClientCallbackEvent(event: LeapAnalyticsEvent?, projectParameter: LeapProjectParameters?) {
                
        if projectParameter?.deploymentType == constant_LINK {
            
            if !(delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false) {
                event?.projectId = event?.deploymentId
            }
            event?.sessionId = nil
            event?.deploymentId = nil
        } else {
            event?.sessionId = nil
            event?.projectId = nil
            event?.deploymentId = nil
        }
        
        event?.selectedProjectId = nil
        event?.parentProjectId = nil
        
        guard let clientCallbackEvent = event, let clientPayload = generatePayload(clientCallbackEvent) else { return }
        delegate?.sendPayload(clientPayload)
    }
    
    func eventsToFlush() -> Array<Dictionary<String, String>>? {
        
        let savedEvents = prefs.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        
        if savedEvents.count >= MAX_COUNT {
            var eventsToFlush = prefs.object(forKey: "leap_flush_events") as? Array<Dictionary<String, String>> ?? []
            eventsToFlush += savedEvents
            prefs.set(eventsToFlush, forKey: "leap_flush_events")
            prefs.removeObject(forKey: "leap_saved_events")
            return eventsToFlush
        }
        return nil
    }
    
    func deleteFlushedEvents() {
        self.prefs.removeObject(forKey: "leap_flush_events")
    }
}
