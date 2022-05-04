//
//  LeapAnalyticsManager.swift
//  LeapCore
//
//  Created by Aravind GS on 28/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

@objc protocol LeapEventsDelegate: AnyObject {
    @objc optional func successfullySentEvents(events: Array<Dictionary<String, Any>>)
    func sendPayload(_ payload: Dictionary<String, Any>)
}

protocol LeapAnalyticsDelegate: AnyObject {
    func queue(event name: EventName, for analytics: LeapAnalyticsModel)
}

class LeapAnalyticsManager {
    
    private lazy var analyticsModelHandler: LeapAnalyticsModelHandler = {
        return LeapAnalyticsModelHandler()
    }()
    
    private lazy var analyticsNetworkHandler: LeapAnalyticsNetworkHandler = {
        return LeapAnalyticsNetworkHandler(self)
    }()
    
    private lazy var analyticsDataHandler: LeapAnalyticsDataHandler = {
        return LeapAnalyticsDataHandler(self)
    }()
    
    weak var eventsDelegate: LeapEventsDelegate?
    
    init(_ eventsDelegate: LeapEventsDelegate) {
        self.eventsDelegate = eventsDelegate
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
    
    private func queueEvent(event name: EventName, for analytics: LeapAnalyticsModel) {
        
        switch name {
            
        case .startScreenEvent, .flowMenuStartScreen:
            
            if let event = analyticsModelHandler.startScreenEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .optInEvent:
            
            if let event = analyticsModelHandler.optInEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .optOutEvent:
            
            if let event = analyticsModelHandler.optOutEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .instructionEvent:
            
            if let event = analyticsModelHandler.instructionEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .assistInstructionEvent:
            
            if let event = analyticsModelHandler.assistInstructionEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .flowSuccessEvent:
            
            if let event = analyticsModelHandler.flowSuccessEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .flowStopEvent:
            
            if let event = analyticsModelHandler.flowStopEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .flowDisableEvent:
            
            if let event = analyticsModelHandler.flowDisableEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .languageChangeEvent:
            
            if let event = analyticsModelHandler.languageChangeEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .actionTrackingEvent:
            
            if let event = analyticsModelHandler.auiActionTrackingEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .leapSdkDisableEvent:
            
            if let event = analyticsModelHandler.leapSDKDisableEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .projectTerminationEvent:
            
            if let event = analyticsModelHandler.projectTerminationEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        }
        if let events = analyticsDataHandler.getEventsToFlush() {
            
            analyticsNetworkHandler.flushEvents(events)
        }
    }
}

extension LeapAnalyticsManager: LeapAnalyticsDelegate {
    func queue(event name: EventName, for analytics: LeapAnalyticsModel) {
        queueEvent(event: name, for: analytics)
    }
}

extension LeapAnalyticsManager: LeapEventsDelegate {
    func successfullySentEvents(events: Array<Dictionary<String, Any>>) {
        analyticsDataHandler.deleteFlushedEvents()
    }
    
    func sendPayload(_ payload: Dictionary<String, Any>) {
        eventsDelegate?.sendPayload(payload)
    }
}
