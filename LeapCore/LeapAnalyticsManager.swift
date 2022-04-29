//
//  LeapAnalyticsManager.swift
//  LeapCore
//
//  Created by Aravind GS on 28/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

protocol LeapAnalyticsManagerDelegate: AnyObject {
    func sendPayload(_ payload:Dictionary<String,Any>)
    func failedToSendEvents(payload:Array<Dictionary<String,Any>>)
    func sendEvents(payload:Array<Dictionary<String,Any>>)
    func isProjectFlowMenu(projectParams: LeapProjectParameters) -> Bool
    func getCurrentFlowMenu() -> LeapProjectParameters?
    func getCurrentSubFlow() -> LeapProjectParameters?
    func getCurrentPageForAnalytics() -> LeapPage?
    func getCurrentStage() -> LeapStage?
    func getCurrentAssist() -> LeapAssist?
}

class LeapAnalyticsManager {
    
    let MAX_COUNT = 5
    weak var delegate: LeapAnalyticsManagerDelegate?
    
    private var lastEventId: String?
    private var lastEventLanguage: String?
    
    init(_ analyticsDelegate: LeapAnalyticsManagerDelegate) {
        delegate = analyticsDelegate
        NotificationCenter.default.addObserver(self, selector: #selector(flushPendingEvents), name: UIApplication.willResignActiveNotification, object: nil)
        flushPendingEvents()
    }
    
    @objc private func flushPendingEvents() {
        let prefs = UserDefaults.standard
        let savedEvents = prefs.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        var eventsToFlush = prefs.object(forKey: "leap_flush_events") as? Array<Dictionary<String, String>> ?? []
        eventsToFlush += savedEvents
        prefs.set(eventsToFlush, forKey: "leap_flush_events")
        prefs.removeObject(forKey: "leap_saved_events")
        flushEvents(eventsToFlush)
    }
    
    private func generatePayload(_ event: LeapAnalyticsEvent) -> Dictionary<String, String>? {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        guard let payloadData = try? jsonEncoder.encode(event) else { return nil }
        guard let payload = try? JSONSerialization.jsonObject(with: payloadData, options: .mutableContainers) as? Dictionary<String, String> else { return nil }
        return payload
    }
    
    private func saveEvent(event: LeapAnalyticsEvent?, deploymentType: String?, isFlowMenu: Bool) {
        guard let event = event, let payload = generatePayload(event) else { return }
        print("SDK - \(payload)")
        let prefs = UserDefaults.standard
        var savedEvents = prefs.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        savedEvents.append(payload)
        prefs.set(savedEvents, forKey: "leap_saved_events")
        prefs.synchronize()
        
        // client callback
        let clientCallbackEvent = event
        
        if deploymentType == constant_LINK {
            if !isFlowMenu {
                clientCallbackEvent.projectId = event.deploymentId
            }
            clientCallbackEvent.sessionId = nil
            clientCallbackEvent.deploymentId = nil
        } else {
            clientCallbackEvent.sessionId = nil
            clientCallbackEvent.projectId = nil
            clientCallbackEvent.deploymentId = nil
        }
        
        clientCallbackEvent.selectedProjectId = nil
        clientCallbackEvent.parentProjectId = nil
        
        guard let clientPayload = generatePayload(clientCallbackEvent) else { return }
        delegate?.sendPayload(clientPayload)
        
        if savedEvents.count >= MAX_COUNT {
            var eventsToFlush = prefs.object(forKey: "leap_flush_events") as? Array<Dictionary<String, String>> ?? []
            eventsToFlush += savedEvents
            prefs.set(eventsToFlush, forKey: "leap_flush_events")
            prefs.removeObject(forKey: "leap_saved_events")
            flushEvents(eventsToFlush)
        }
    }
    
    func flushEvents(_ events: Array<Dictionary<String, String>>) {
        guard events.count > 0 else { return }
        guard var req = createURLRequest(urlString: Constants.Networking.analyticsEndPoint) else {
            delegate?.failedToSendEvents(payload: events)
            return
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: events, options: .prettyPrinted) else {
            delegate?.failedToSendEvents(payload: events)
            return
        }
        req.httpBody = jsonData
        let session = SSLManager.shared.isValidForSSLPinning(urlString: req.url!.absoluteString) ? SSLManager.shared.session : URLSession.shared
        let analyticsTask = session?.dataTask(with: req) { (data, response, error) in
            if error != nil { self.delegate?.failedToSendEvents(payload: events) }
            else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    self.delegate?.sendEvents(payload: events)
                    let prefs = UserDefaults.standard
                    prefs.removeObject(forKey: "leap_flush_events")
                } else { self.delegate?.failedToSendEvents(payload: events) }
            }
        }
        analyticsTask?.resume()
    }
    
    func createURLRequest(urlString: String) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        getHeaders().forEach { (key, value) in
            req.addValue(value, forHTTPHeaderField: key)
        }
        return req
    }
    
    func getHeaders() -> Dictionary<String, String> {
        guard let apiKey = LeapSharedInformation.shared.getAPIKey() else { return [:] }
        return [
            Constants.AnalyticsKeys.xLeapId:UIDevice.current.identifierForVendor?.uuidString ?? "",
            Constants.AnalyticsKeys.xJinyClientId: apiKey,
            Constants.AnalyticsKeys.contentTypeKey:Constants.AnalyticsKeys.contentTypeValue
        ]
    }
}

// MARK: - CREATE AND SAVE ANALYTICS EVENT
extension LeapAnalyticsManager {
    
    func startScreenEvent(with projectParameter: LeapProjectParameters?, instructionId: String) {
        guard let projectParameter = projectParameter else { return }
        if lastEventId == instructionId && lastEventLanguage == LeapPreferences.shared.getUserLanguage() {
            return
        }
        let event = LeapAnalyticsEvent(withEvent: EventName.startScreenEvent, withParams: projectParameter)
        lastEventId = instructionId
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
        
        saveEvent(event: event, deploymentType: projectParameter.deploymentType, isFlowMenu: delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false)
    }
    
    func optInEvent(with projectParameter: LeapProjectParameters?) {
        guard let projectParameter = projectParameter else { return }
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
        
        saveEvent(event: event, deploymentType: projectParameter.deploymentType, isFlowMenu: delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false)
    }
    
    func optOutEvent(with projectParameter: LeapProjectParameters?) {
        guard let projectParameter = projectParameter else { return }
        let event = LeapAnalyticsEvent(withEvent: EventName.optOutEvent, withParams: projectParameter)
        lastEventId = nil
        print("Opt out")
        
        saveEvent(event: event, deploymentType: projectParameter.deploymentType, isFlowMenu: delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false)
    }
    
    func instructionEvent(with projectParameter: LeapProjectParameters?, instructionId: String) {
        guard let projectParameter = projectParameter else { return }
        if lastEventId == instructionId && lastEventLanguage == LeapPreferences.shared.getUserLanguage() {
            return
        }
        let event = LeapAnalyticsEvent(withEvent: EventName.instructionEvent, withParams: projectParameter)
        lastEventId = instructionId
        lastEventLanguage = event.language
        event.elementName = delegate?.getCurrentStage()?.name
        event.pageName = delegate?.getCurrentPageForAnalytics()?.name
        
        event.parentProjectId = delegate?.getCurrentFlowMenu()?.projectId // flow menu projectId if there is parent
        event.parentProjectName = delegate?.getCurrentFlowMenu()?.projectName
        event.parentDeploymentVersion = delegate?.getCurrentFlowMenu()?.deploymentVersion
        event.selectedFlow = delegate?.getCurrentFlowMenu() != nil ? delegate?.getCurrentSubFlow()?.projectName : nil // subflow's name
        
        print("element seen")
        
        saveEvent(event: event, deploymentType: projectParameter.deploymentType, isFlowMenu: delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false)
    }
    
    func assistInstructionEvent(with projectParameter: LeapProjectParameters?, instructionId: String) {
        guard let projectParameter = projectParameter else { return }
        if lastEventId == instructionId && lastEventLanguage == LeapPreferences.shared.getUserLanguage() {
            return
        }
        let event = LeapAnalyticsEvent(withEvent: EventName.instructionEvent, withParams: projectParameter)
        lastEventId = instructionId
        lastEventLanguage = event.language
        event.elementName = delegate?.getCurrentAssist()?.name
        print("assist element seen")
        
        saveEvent(event: event, deploymentType: projectParameter.deploymentType, isFlowMenu: delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false)
    }
    
    func flowSuccessEvent(with projectParameter: LeapProjectParameters?) {
        guard let projectParameter = projectParameter else { return }
        let event = LeapAnalyticsEvent(withEvent: EventName.flowSuccessEvent, withParams: projectParameter)
        event.parentProjectId = delegate?.getCurrentFlowMenu()?.projectId // flow menu projectId if there is parent
        event.parentProjectName = delegate?.getCurrentFlowMenu()?.projectName
        event.parentDeploymentVersion = delegate?.getCurrentFlowMenu()?.deploymentVersion
        event.selectedFlow = delegate?.getCurrentFlowMenu() != nil ? delegate?.getCurrentSubFlow()?.projectName : nil // subflow's name
        print("flow success")
        
        saveEvent(event: event, deploymentType: projectParameter.deploymentType, isFlowMenu: delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false)
    }
    
    func flowStopEvent(with projectParameter: LeapProjectParameters?) {
        guard let projectParameter = projectParameter else { return }
        let event = LeapAnalyticsEvent(withEvent: EventName.flowStopEvent, withParams: projectParameter)
        event.elementName = delegate?.getCurrentStage()?.name
        event.pageName = delegate?.getCurrentPageForAnalytics()?.name
        print("flow stop")
       
        saveEvent(event: event, deploymentType: projectParameter.deploymentType, isFlowMenu: delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false)
    }
    
    func flowDisableEvent(with projectParameter: LeapProjectParameters?) {
        guard let projectParameter = projectParameter else { return }
        let event = LeapAnalyticsEvent(withEvent: EventName.flowDisableEvent, withParams: projectParameter)
        print("flow disable")
        
        saveEvent(event: event, deploymentType: projectParameter.deploymentType, isFlowMenu: delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false)
    }
    
    func languageChangeEvent(with projectParameter: LeapProjectParameters?, from previousLanguage: String, to currentLanguage: String) {
        guard let projectParameter = projectParameter else { return }
        let event = LeapAnalyticsEvent(withEvent: EventName.languageChangeEvent, withParams: projectParameter)
        event.language = currentLanguage
        event.previousLanguage = previousLanguage
        print("Language change")
        
        saveEvent(event: event, deploymentType: projectParameter.deploymentType, isFlowMenu: delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false)
    }
    
    func auiActionTrackingEvent(with projectParameter: LeapProjectParameters?, action: Dictionary<String,Any>?) {
        guard let projectParameter = projectParameter else { return }
        let event = LeapAnalyticsEvent(withEvent: EventName.actionTrackingEvent, withParams: projectParameter)
        
        guard let body = action?[constant_body] as? Dictionary<String, Any> else { return }
        
        if let id = body[constant_id] as? String {
            
            if lastEventId == id { return }
            
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
        
        saveEvent(event: event, deploymentType: projectParameter.deploymentType, isFlowMenu: delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false)
    }
    
    func leapSDKDisableEvent(with projectParameter: LeapProjectParameters?) {
        guard let projectParameter = projectParameter else { return }
        let event = LeapAnalyticsEvent(withEvent: EventName.leapSdkDisableEvent, withParams: projectParameter)
        event.language = nil
        print("Leap SDK disable")
        
        saveEvent(event: event, deploymentType: projectParameter.deploymentType, isFlowMenu: delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false)
    }
    
    func projectTerminationEvent(with projectParameter: LeapProjectParameters?, for terminationRule: String) {
        guard let projectParameter = projectParameter, projectParameter.deploymentType == constant_LINK else { return }
        let event = LeapAnalyticsEvent(withEvent: EventName.projectTerminationEvent, withParams: projectParameter)
        event.terminationRule = terminationRule
        print("Project Termination")
        
        saveEvent(event: event, deploymentType: projectParameter.deploymentType, isFlowMenu: delegate?.isProjectFlowMenu(projectParams: projectParameter) ?? false)
    }
}

struct Constants {
    struct Networking {
        static let isExecuting = "isExecuting"
        static let isFinished = "isFinished"
        static let downloadQ = "Leap Download Queue"
        static let dataQ = "Leap Data Queue"
        static let downloadsFolder = "Leap"
        static let analyticsEndPoint: String = {
            #if DEV
                return "https://odin-dev-gke.leap.is/odin/api/v1/analytics"
            #elseif STAGE
                return "https://odin-stage-gke.leap.is/odin/api/v1/analytics"
            #elseif PREPROD
                return "https://odin-preprod.leap.is/odin/api/v1/analytics"
            #elseif PROD
                return "https://odin.leap.is/odin/api/v1/analytics"
            #else
                return "https://odin.leap.is/odin/api/v1/analytics"
            #endif
        }()
    }
}

extension Constants {
    struct AnalyticsKeys {
        static let tempApiKey = "pBWmiQ8HCKllVJd2xQ5Cd7d5defd9e1e4f7a8882c34ff75f0d36"
        static let xClientId = "x-client-id"
        static let contentTypeKey = "Content-Type"
        static let contentTypeValue = "application/json"
        static let xLeapId = "x-leap-id"
        static let xJinyClientId = "x-jiny-client-id"
    }
}
