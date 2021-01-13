//
//  JinyDiscoveryManager.swift
//  JinySDK
//
//  Created by Aravind GS on 30/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit


protocol JinyDiscoveryManagerDelegate:AnyObject {
    
    func getMutedDiscoveryIds() -> Array<Int>
    func addDiscoveryIdToMutedList(id:Int)
    func getTriggeredEvents() -> Dictionary<String,Any>
    
    func newDiscoveryIdentified(discovery:JinyDiscovery, view:UIView?, rect:CGRect?, webview:UIView?)
    func sameDiscoveryIdentified(discovery:JinyDiscovery, view:UIView?, rect:CGRect?, webview:UIView?)
    func noDiscoveryIdentified()
    func startFlow(id:Int, disId:Int)
    func canTriggerBasedOnTriggerFrequency(discovery: JinyDiscovery) -> Bool
    func showJinyIcon()
    func removeAllViews()
}

class JinyDiscoveryEventTrigger {
    let discovery:JinyDiscovery
    var anchorView:UIView?
    var anchorRect:CGRect?
    var anchorWebView:UIView?
    let timer:Timer?
    let hasTaggedEvent:Bool
    
    init(_ discovery:JinyDiscovery, _ timer:Timer?, view:UIView?, rect:CGRect?, webview:UIView?) {
        self.discovery = discovery
        self.timer = timer
        self.anchorView = view
        self.anchorRect = rect
        self.anchorWebView = webview
        if let _ = discovery.taggedEvents{ hasTaggedEvent = true }
        else { hasTaggedEvent = false }
    }
}

class JinyDiscoveryManager {
    
    private weak var delegate:JinyDiscoveryManagerDelegate?
    private var allDiscoveries:Array<JinyDiscovery> = []
    private var timerArray:Array<Timer> = []
    var toBeTriggered:Array<JinyDiscoveryEventTrigger> = []
    private var completedDiscoveriesInSession:Array<JinyDiscovery> = []
    private var identifiedDiscoveries:Array<JinyDiscovery> = [] //Muted in current session
    private var currentDiscovery:JinyDiscovery?
    var currentDiscoveryObject: (JinyDiscovery, UIView?, CGRect?, UIView?)?
    var currentDiscoveryOptOut = false
    
    init(_ withDelegate:JinyDiscoveryManagerDelegate) { delegate = withDelegate }
    
    func setAllDiscoveries(_ discoveries:Array<JinyDiscovery>) { allDiscoveries = discoveries }
    
    func getDiscoveriesToCheck() -> Array<JinyDiscovery> {
        var discAllowed =  allDiscoveries.filter{ !(getMutedDiscoveries().contains($0) || completedDiscoveriesInSession.contains($0)) }
        let sessionCount = JinySharedInformation.shared.getJinySessionCount()
        let discDismissCount = JinySharedInformation.shared.getDiscoveryDismissCount()
        let flowCompletedCount = JinySharedInformation.shared.getDiscoveryFlowCount()
        let triggeredEvents = delegate?.getTriggeredEvents()
        discAllowed = discAllowed.filter({ (allowedDiscovery) -> Bool in
            
            if let taggedEvents = allowedDiscovery.taggedEvents {
                if taggedEvents.action == constant_disable {
                    let isPassing = checkOrConditions(conditions: taggedEvents.orConditions, events: triggeredEvents!)
                    if isPassing { return false }
                }
            }
            
            guard let freq = allowedDiscovery.frequency else { return true }
            
            if let nSessionCount = freq.nSession, nSessionCount > 0, let counter = sessionCount[String(allowedDiscovery.id)] {
                if counter >= nSessionCount { return false }
            }
            
            if let nUserDismissCount = freq.nDismissByUser, nUserDismissCount > 0, let counter = discDismissCount[String(allowedDiscovery.id)] {
                if counter >= nUserDismissCount { return false }
            }
            
            if let perAppUntilFlowComplete = freq.perApp, perAppUntilFlowComplete > 0, let counter = flowCompletedCount[String(allowedDiscovery.id)] {
                if counter >= perAppUntilFlowComplete { return false }
            }
            
            if let perSessionUntilFlowComplete = freq.perSession, perSessionUntilFlowComplete > 0, let counter = JinySharedInformation.shared.sessionFlowCountDict[String(allowedDiscovery.id)] {
                if counter >= perSessionUntilFlowComplete { return false }
            }

            return true
        })
        return discAllowed
    }
    
    func getCompletedDiscoveries() -> Array<JinyDiscovery> { return completedDiscoveriesInSession }
    
    func discoveriesForContextCheck() -> Array<JinyDiscovery> { return (getMutedDiscoveries() + completedDiscoveriesInSession + identifiedDiscoveries ).reversed() }
    
    func discoveriesFound(_ discoveryObjects:Array<(JinyDiscovery, UIView?, CGRect?, UIView?)>) {
        JinyEventDetector.shared.delegate = self
        let discoveries = discoveryObjects.map { (discObj) -> JinyDiscovery in
            return discObj.0
        }
        for trig in toBeTriggered {
            if discoveries.contains(trig.discovery) { continue }
            else { toBeTriggered = toBeTriggered.filter { $0.discovery == trig.discovery} }
        }
        
        
        for discoveryObj in discoveryObjects {
            let discoveriesAlreadyPresent = toBeTriggered.map { (eventTrigger) -> JinyDiscovery in
                return eventTrigger.discovery
            }
            if discoveriesAlreadyPresent.contains(discoveryObj.0) {continue}
            else {
                if discoveryObj.0.trigger?.delay != nil && self.currentDiscovery == nil {
                    let delay = discoveryObj.0.trigger!.delay!
                    if #available(iOS 10.0, *) {
                        let timer = Timer(timeInterval: TimeInterval(delay/1000), repeats: false) { (timer) in
                            timer.invalidate()
                            self.currentDiscovery = discoveryObj.0
                            if self.delegate!.canTriggerBasedOnTriggerFrequency(discovery: self.currentDiscovery!) {
                            self.delegate?.newDiscoveryIdentified(discovery: discoveryObj.0, view: discoveryObj.1, rect: discoveryObj.2, webview: discoveryObj.3)
                            }
                            self.cancelAllTimers()
                        }
                        RunLoop.current.add(timer, forMode: .default)
                        toBeTriggered.append(JinyDiscoveryEventTrigger(discoveryObj.0, timer, view: discoveryObj.1, rect: discoveryObj.2, webview: discoveryObj.3))
                    } else {
                        // Fallback on earlier versions
                    }
                } else if let type = discoveryObj.0.trigger?.event?[constant_type], let value = discoveryObj.0.trigger?.event?[constant_value], type == constant_click, value == constant_showDiscovery {
                    toBeTriggered.append(JinyDiscoveryEventTrigger(discoveryObj.0, nil, view: discoveryObj.1, rect: discoveryObj.2, webview: discoveryObj.3))
                } else if let type = discoveryObj.0.trigger?.event?[constant_type], let value = discoveryObj.0.trigger?.event?[constant_value], type == constant_click, value == constant_optIn {
                    toBeTriggered.append(JinyDiscoveryEventTrigger(discoveryObj.0, nil, view: discoveryObj.1, rect: discoveryObj.2, webview: discoveryObj.3))
                } else if discoveryObj.0.taggedEvents != nil && discoveryObj.0.taggedEvents?.action == constant_enable {
                    toBeTriggered.append(JinyDiscoveryEventTrigger(discoveryObj.0, nil, view: discoveryObj.1, rect: discoveryObj.2, webview: discoveryObj.3))
                }
                else {
                    if self.currentDiscovery == nil {
                        self.currentDiscovery = discoveryObj.0
                        if self.delegate!.canTriggerBasedOnTriggerFrequency(discovery: self.currentDiscovery!) {
                        self.delegate?.newDiscoveryIdentified(discovery: discoveryObj.0, view: discoveryObj.1, rect: discoveryObj.2, webview: discoveryObj.3)
                        }
                        self.cancelAllTimers()
                    
                    } else {
                        
                        if currentDiscoveryOptOut && self.delegate!.canTriggerBasedOnTriggerFrequency(discovery: discoveryObj.0)  {
                            self.delegate!.showJinyIcon()
                        }
                    }
                }
                newtriggerEvent(events: delegate!.getTriggeredEvents())
                currentDiscoveryObject = discoveryObj
            }
            
        }
    }
    
    func cancelAllTimers() {
        for evtTrigger in toBeTriggered {
            evtTrigger.timer?.invalidate()
        }
        toBeTriggered.removeAll()
    }
    
    func discoveryNotFound() {
        cancelAllTimers()   
        delegate?.noDiscoveryIdentified()
        currentDiscovery = nil
        toBeTriggered = []
    }
    
    func completedCurrentDiscovery() {
        guard let discovery = currentDiscovery else { return }
        completedDiscoveriesInSession.append(discovery)
        currentDiscovery = nil
    }
    
    func setDiscovery(_ discovery:JinyDiscovery) { currentDiscovery = discovery }
    
    func getCurrentDiscovery() -> JinyDiscovery? { return currentDiscovery }
    
    func resetCurrentDiscovery() {
        currentDiscovery = nil
        cancelAllTimers()
        toBeTriggered = []
    }
    
    func muteCurrentDiscovery() {
        guard let discovery = currentDiscovery else { return }
        identifiedDiscoveries.append(discovery)
        delegate?.addDiscoveryIdToMutedList(id: discovery.id)
        currentDiscovery = nil
    }
    
    func addToIdentifiedList(_ discovery:JinyDiscovery) {
        if identifiedDiscoveries.contains(discovery) { identifiedDiscoveries = identifiedDiscoveries.filter { $0 != discovery } }
        identifiedDiscoveries.append(discovery)
    }
    
    func getMutedDiscoveries() -> Array<JinyDiscovery> {
        guard let mutedIds = delegate?.getMutedDiscoveryIds() else { return [] }
        let mutedDiscoveries = allDiscoveries.filter{ mutedIds.contains($0.id) }
        return mutedDiscoveries
    }
    
    func currentDiscoveryPresented() {
        JinySharedInformation.shared.discoveryPresented(discoveryId: currentDiscovery!.id)
    }
    
    func currentDiscoveryDismissed() {
        JinySharedInformation.shared.discoveryDismissed(discoveryId: currentDiscovery!.id)
    }
    
    func receivedTaggedEvent(taggedEvents:Dictionary<String,Any>) {
        
    }
    
}


extension JinyDiscoveryManager:JinyEventDetectorDelegate {
    
    func clickDetected(view: UIView?, point: CGPoint) {
        var discoveriesThatCanFire:Array<JinyDiscoveryEventTrigger> = []
        for discoveryEvent in toBeTriggered {
            var isAnchorClick:Bool = false
            if discoveryEvent.discovery.isWeb {
                if discoveryEvent.anchorRect != nil {
                    if discoveryEvent.anchorWebView != nil {
                        if let newRect = discoveryEvent.anchorWebView?.convert(discoveryEvent.anchorRect!, to: nil) {
                            if newRect.contains(point) { isAnchorClick = true }
                        }
                    } else {
                        if discoveryEvent.anchorRect!.contains(point) { isAnchorClick = true }
                    }
                    
                }
            } else {
                if view == nil || discoveryEvent.anchorView == nil { continue }
                if view == discoveryEvent.anchorView { isAnchorClick = true }
            }
            if isAnchorClick { discoveriesThatCanFire.append(discoveryEvent) }
        }
        var selectedDis:JinyDiscoveryEventTrigger?
        var maxWeight = 0
        for dis in discoveriesThatCanFire {
            if dis.discovery.weight > maxWeight {
                selectedDis = dis
                maxWeight = dis.discovery.weight
            }
        }
        guard let fireDis = selectedDis else { return }
        if let type = fireDis.discovery.trigger?.event?[constant_type], let value = fireDis.discovery.trigger?.event?[constant_value], type == constant_click, value == constant_optIn {
            currentDiscovery = nil
            cancelAllTimers()
            guard let flowId = fireDis.discovery.flowId else { return }
            delegate?.startFlow(id: flowId, disId: fireDis.discovery.id)
        } else if let type = fireDis.discovery.trigger?.event?[constant_type], let value = fireDis.discovery.trigger?.event?[constant_value], type == constant_click, value == constant_showDiscovery {
            currentDiscovery = fireDis.discovery
            if self.delegate!.canTriggerBasedOnTriggerFrequency(discovery: self.currentDiscovery!) {
            self.delegate?.newDiscoveryIdentified(discovery: fireDis.discovery, view: fireDis.anchorView, rect: fireDis.anchorRect, webview: fireDis.anchorWebView)
            }
            cancelAllTimers()
        }
        
    }
    
    func newtriggerEvent(events:Dictionary<String,Any>) {
        let tagDiscoveries = toBeTriggered.filter { (disObj) -> Bool in
            return disObj.hasTaggedEvent
        }
        var discoveriesPassingCheck:Array<JinyDiscoveryEventTrigger> = []
        for discoveryObj in tagDiscoveries {
            let discovery = discoveryObj.discovery
            if discovery.taggedEvents == nil { return }
            if discovery.taggedEvents!.action != constant_enable { return }
            let isPassing:Bool = checkOrConditions(conditions: discovery.taggedEvents!.orConditions, events: events)
            if isPassing { discoveriesPassingCheck.append(discoveryObj) }
        }
        var selectedDiscovery:JinyDiscoveryEventTrigger? = nil
        var maxWeight = 0
        for discoveryObj in discoveriesPassingCheck {
            if discoveryObj.discovery.weight > maxWeight {
                selectedDiscovery = discoveryObj
                maxWeight = discoveryObj.discovery.weight
            }
        }
        guard let launchDiscovery = selectedDiscovery else { return }
        if self.delegate!.canTriggerBasedOnTriggerFrequency(discovery: launchDiscovery.discovery) {
        self.delegate?.newDiscoveryIdentified(discovery: launchDiscovery.discovery, view: launchDiscovery.anchorView, rect: launchDiscovery.anchorRect, webview: launchDiscovery.anchorWebView)
        }
    }
    
    func checkOrConditions(conditions:Array<Array<JinyTaggedEventCondition>>, events:Dictionary<String,Any>) -> Bool {
        var isPassing:Bool = false
        for orCondition in conditions {
            var andPassing = true
            for andCondition in orCondition {
                if events[andCondition.identifier] == nil {
                    andPassing = false
                    break
                }
                
                switch andCondition.type {
                case "int":
                    if let currentValue = events[andCondition.identifier] as? Int, let checkValue = Int(andCondition.value) {
                        if andCondition.condition == "less_than" {
                            andPassing = currentValue < checkValue
                        } else if andCondition.condition == "more_than" {
                            andPassing  = currentValue > checkValue
                        } else if andCondition.condition == "equals" {
                            andPassing = currentValue == checkValue
                        }
                    }
                case "float":
                    if let currentValue = events[andCondition.identifier] as? Int, let checkValue = Int(andCondition.value) {
                        if andCondition.condition == "less_than" {
                            andPassing = currentValue < checkValue
                        } else if andCondition.condition == "more_than" {
                            andPassing  = currentValue > checkValue
                        } else if andCondition.condition == "equals" {
                            andPassing = currentValue == checkValue
                        }
                    }
                case "string":
                    if let currentValue = events[andCondition.identifier] as? String {
                        if andCondition.condition == "equals" {
                            andPassing = currentValue == andCondition.value
                        }
                    }
                default:
                    break
                }
            }
            isPassing = isPassing || andPassing
        }
        return isPassing
    }
    
}
