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
    func sendPayload(_ payload: Dictionary<String, Any>)
    func failedToSendEvents(payload: Array<Dictionary<String, Any>>)
    func successfullySentEvents(payload: Array<Dictionary<String, Any>>)
    func isProjectFlowMenu(projectParams: LeapProjectParameters?) -> Bool
    func getCurrentFlowMenu() -> LeapProjectParameters?
    func getCurrentSubFlow() -> LeapProjectParameters?
    func getCurrentPageForAnalytics() -> LeapPage?
    func getCurrentStage() -> LeapStage?
    func getCurrentAssist() -> LeapAssist?
}

class LeapAnalyticsManager {
        
    private lazy var analyticsModelHandler: LeapAnalyticsModelHandler = {
        return LeapAnalyticsModelHandler(self)
    }()
    
    private lazy var analyticsDataHandler: LeapAnalyticsDataHandler = {
        return LeapAnalyticsDataHandler(self)
    }()
    
    private lazy var analyticsNetworkHandler: LeapAnalyticsNetworkHandler = {
        return LeapAnalyticsNetworkHandler(self)
    }()
    
    weak var delegate: LeapAnalyticsManagerDelegate?
    
    init(_ analyticsDelegate: LeapAnalyticsManagerDelegate) {
        self.delegate = analyticsDelegate
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
        analyticsNetworkHandler.flushEvents(eventsToFlush)
    }
    
    func queue(event name: EventName, for analytics: LeapAnalyticsModel) {
        
        switch name {
            
        case .startScreenEvent, .flowMenuStartScreen:
            if let event = analyticsModelHandler.startScreenEvent(with: analytics) {
                analyticsDataHandler.saveEvent(event: event)
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter)
            }
        case .optInEvent:
            if let event = analyticsModelHandler.optInEvent(with: analytics) {
                analyticsDataHandler.saveEvent(event: event)
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter)
            }
            
        case .optOutEvent:
            if let event = analyticsModelHandler.optOutEvent(with: analytics) {
                analyticsDataHandler.saveEvent(event: event)
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter)
            }
            
        case .instructionEvent:
            if let event = analyticsModelHandler.instructionEvent(with: analytics) {
                analyticsDataHandler.saveEvent(event: event)
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter)
            }
            
        case .assistInstructionEvent:
            if let event = analyticsModelHandler.assistInstructionEvent(with: analytics) {
                analyticsDataHandler.saveEvent(event: event)
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter)
            }
            
        case .flowSuccessEvent:
            if let event = analyticsModelHandler.flowSuccessEvent(with: analytics) {
                analyticsDataHandler.saveEvent(event: event)
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter)
            }
            
        case .flowStopEvent:
            if let event = analyticsModelHandler.flowStopEvent(with: analytics) {
                analyticsDataHandler.saveEvent(event: event)
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter)
            }
            
        case .flowDisableEvent:
            if let event = analyticsModelHandler.flowDisableEvent(with: analytics) {
                analyticsDataHandler.saveEvent(event: event)
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter)
            }
            
        case .languageChangeEvent:
            if let event = analyticsModelHandler.languageChangeEvent(with: analytics) {
                analyticsDataHandler.saveEvent(event: event)
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter)
            }
            
        case .actionTrackingEvent:
            if let event = analyticsModelHandler.auiActionTrackingEvent(with: analytics) {
                analyticsDataHandler.saveEvent(event: event)
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter)
            }
            
        case .leapSdkDisableEvent:
            if let event = analyticsModelHandler.leapSDKDisableEvent(with: analytics) {
                analyticsDataHandler.saveEvent(event: event)
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter)
            }
            
        case .projectTerminationEvent:
            if let event = analyticsModelHandler.projectTerminationEvent(with: analytics) {
                analyticsDataHandler.saveEvent(event: event)
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter)
            }
        }
        
        if let events = analyticsDataHandler.eventsToFlush() {
         
            analyticsNetworkHandler.flushEvents(events)
        }
    }
}

extension LeapAnalyticsManager: LeapAnalyticsManagerDelegate {
    
    func sendPayload(_ payload: Dictionary<String, Any>) {
        delegate?.sendPayload(payload)
    }
    
    func failedToSendEvents(payload: Array<Dictionary<String, Any>>) {
        delegate?.failedToSendEvents(payload: payload)
    }
    
    func successfullySentEvents(payload: Array<Dictionary<String, Any>>) {
        analyticsDataHandler.deleteFlushedEvents()
        delegate?.successfullySentEvents(payload: payload)
    }
    
    func isProjectFlowMenu(projectParams: LeapProjectParameters?) -> Bool {
        return delegate?.isProjectFlowMenu(projectParams: projectParams) ?? false
    }
    
    func getCurrentFlowMenu() -> LeapProjectParameters? {
        return delegate?.getCurrentFlowMenu()
    }
    
    func getCurrentSubFlow() -> LeapProjectParameters? {
        return delegate?.getCurrentSubFlow()
    }
    
    func getCurrentPageForAnalytics() -> LeapPage? {
        return delegate?.getCurrentPageForAnalytics()
    }
    
    func getCurrentStage() -> LeapStage? {
        return delegate?.getCurrentStage()
    }
    
    func getCurrentAssist() -> LeapAssist? {
        return delegate?.getCurrentAssist()
    }
}
