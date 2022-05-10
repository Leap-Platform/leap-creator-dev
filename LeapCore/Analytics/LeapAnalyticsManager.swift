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
    
    private var analyticsModelHandler = LeapAnalyticsModelHandler()
    
    private var analyticsNetworkHandler = LeapAnalyticsNetworkHandler()
    
    private lazy var analyticsDataHandler: LeapAnalyticsDataHandler = {
        return LeapAnalyticsDataHandler(self)
    }()
    
    weak var eventsDelegate: LeapEventsDelegate?
    
    private weak var modelHandlerDelegate: LeapAnalyticsModelHandlerDelegate?
    
    private weak var networkHandlerDelegate: LeapAnalyticsNetworkHandlerDelegate?
    
    init(_ eventsDelegate: LeapEventsDelegate? = nil) {
        self.eventsDelegate = eventsDelegate
        self.analyticsNetworkHandler.delegate = self
        self.modelHandlerDelegate = self.analyticsModelHandler
        self.networkHandlerDelegate = self.analyticsNetworkHandler
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
                        
            if let event = modelHandlerDelegate?.startScreenEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .optInEvent:
            
            if let event = modelHandlerDelegate?.optInEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .optOutEvent:
            
            if let event = modelHandlerDelegate?.optOutEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .instructionEvent:
            
            if let event = modelHandlerDelegate?.instructionEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .assistInstructionEvent:
            
            if let event = modelHandlerDelegate?.assistInstructionEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .flowSuccessEvent:
            
            if let event = modelHandlerDelegate?.flowSuccessEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .flowStopEvent:
            
            if let event = modelHandlerDelegate?.flowStopEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .flowDisableEvent:
            
            if let event = modelHandlerDelegate?.flowDisableEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .languageChangeEvent:
            
            if let event = modelHandlerDelegate?.languageChangeEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .actionTrackingEvent:
            
            if let event = modelHandlerDelegate?.auiActionTrackingEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .leapSdkDisableEvent:
            
            if let event = modelHandlerDelegate?.leapSDKDisableEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        case .projectTerminationEvent:
            
            if let event = modelHandlerDelegate?.projectTerminationEvent(with: analytics) {
                
                analyticsDataHandler.saveEvent(event: event)
                
                analyticsDataHandler.sendClientCallbackEvent(event: event, projectParameter: analytics.projectParameter, isProjectFlowMenu: analytics.isProjectFlowMenu)
            }
        }
        if let events = analyticsDataHandler.getEventsToFlush() {
            
            networkHandlerDelegate?.flushEvents(events)
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
