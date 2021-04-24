//
//  LeapDiscoveryManager.swift
//  LeapCore
//
//  Created by Aravind GS on 30/06/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit


protocol LeapDiscoveryManagerDelegate:AnyObject {
    
    func getAllDiscoveries() -> Array<LeapDiscovery>
    func newDiscoveryIdentified(discovery:LeapDiscovery, view:UIView?, rect:CGRect?, webview:UIView?)
    func sameDiscoveryIdentified(discovery:LeapDiscovery, view:UIView?, rect:CGRect?, webview:UIView?)
    func dismissDiscovery()
    
}

class LeapDiscoveryManager {
    
    private weak var delegate:LeapDiscoveryManagerDelegate?
    private var completedDiscoveriesInSession:Array<Int> = []
    private var identifiedDiscoveriesInSession:Array<Int> = []
    private weak var currentDiscovery:LeapDiscovery?
    private var discoveryTimer:Timer?
    
    init(_ withDelegate:LeapDiscoveryManagerDelegate) { delegate = withDelegate }
        
    func getCurrentDiscovery() -> LeapDiscovery? { return currentDiscovery }
    
    func getDiscoveriesToCheck() -> Array<LeapDiscovery> {
        guard var discoveriesToCheck = delegate?.getAllDiscoveries(), discoveriesToCheck.count > 0 else { return [] }
        let discoveryPresentedCount = LeapSharedInformation.shared.getDiscoveriesPresentedInfo()
        let discoveryDismissInfo = LeapSharedInformation.shared.getDismissedDiscoveryInfo()
        let discoveryFlowInfo = LeapSharedInformation.shared.getDiscoveryFlowCompletedInfo()
        let terminatedDiscoveries = LeapSharedInformation.shared.getTerminatedDiscoveries()
        discoveriesToCheck = discoveriesToCheck.filter{ !terminatedDiscoveries.contains($0.id) }
        discoveriesToCheck = discoveriesToCheck.filter({ (discovery) -> Bool in
            let presentedCount = discoveryPresentedCount[String(discovery.id)] ?? 0
            let hasBeenDismissed = discoveryDismissInfo.contains(discovery.id)
            let discoveryFlowCompletedCount = discoveryFlowInfo[String(discovery.id)] ?? 0
            if let terminationFreq = discovery.terminationfrequency {
                if let nSessionCount = terminationFreq.nSession, nSessionCount != -1 {
                    if presentedCount >= nSessionCount { return false }
                }
                if let perAppCount = terminationFreq.perApp, perAppCount != -1 {
                    if discoveryFlowCompletedCount >= perAppCount { return false }
                }
                if let nDismissedByUser = terminationFreq.nDismissByUser, nDismissedByUser != -1 {
                    if hasBeenDismissed { return false }
                }
            }
            return true
        })
        guard let liveDisc = currentDiscovery else { return discoveriesToCheck }
        if !discoveriesToCheck.contains(liveDisc) { discoveriesToCheck.append(liveDisc) }
        return discoveriesToCheck
    }
    
    func triggerDiscovery(_ discovery:LeapDiscovery,_ view:UIView?,_ rect:CGRect?,_ webview:UIView?) {
        if discovery == currentDiscovery {
            if discoveryTimer == nil { delegate?.sameDiscoveryIdentified(discovery: discovery, view: view, rect: rect, webview: webview) }
            return
        }
        
        if currentDiscovery != nil {
            if discoveryTimer != nil {
                discoveryTimer?.invalidate()
                discoveryTimer = nil
            } else {
                delegate?.dismissDiscovery()
                markCurrentDiscoveryComplete()
            }
        }
        
        currentDiscovery = discovery
        
        let type =  currentDiscovery?.trigger?.type ?? .instant
        if type == .delay && !identifiedDiscoveriesInSession.contains(discovery.id) {
            let delay = currentDiscovery?.trigger?.delay ?? 0
            discoveryTimer = Timer(timeInterval: TimeInterval(delay/1000), repeats: false, block: { (timer) in
                self.discoveryTimer?.invalidate()
                self.discoveryTimer = nil
                self.delegate?.newDiscoveryIdentified(discovery: discovery, view: view, rect: rect, webview: webview)
            })
            guard let discoveryTimer = self.discoveryTimer else { return }
            RunLoop.main.add(discoveryTimer, forMode: .default)
        } else  {
            delegate?.newDiscoveryIdentified(discovery: discovery, view: view, rect: rect, webview: webview)
        }
        if !identifiedDiscoveriesInSession.contains(discovery.id) { identifiedDiscoveriesInSession.append(discovery.id) }
        
    }
    
    func isManualTrigger() -> Bool {
        guard let disc = currentDiscovery else { return false }
        if completedDiscoveriesInSession.contains(disc.id) { return true }
        if LeapSharedInformation.shared.getMutedDiscoveries().contains(disc.id) { return true }
        if let triggerType = disc.triggerFrequency?.type {
            switch triggerType {
            case .everySession:
                 return false
            case .everySessionUntilDismissed:
                return LeapSharedInformation.shared.getDismissedDiscoveryInfo().contains(disc.id)
            case .everySessionUntilFlowComplete:
                return (LeapSharedInformation.shared.getDiscoveryFlowCompletedInfo()[String(disc.id)] ?? 0) > 0
            case .playOnce:
                return (LeapSharedInformation.shared.getDiscoveriesPresentedInfo()[String(disc.id)] ?? 0) > 0
            case .manualTrigger:
                return true
            }
        }
        return false
    }
    
    func discoveryPresented() {
        guard let discovery = currentDiscovery else { return }
        LeapSharedInformation.shared.discoveryPresent(discoveryId: discovery.id)
    }
    
    func resetDiscovery() {
        guard let _ = currentDiscovery else { return }
        discoveryTimer?.invalidate()
        discoveryTimer = nil
        currentDiscovery = nil
    }
    
    func resetDiscoveryManager() {
        guard let _ = currentDiscovery else { return }
        if discoveryTimer != nil {
            discoveryTimer?.invalidate()
            discoveryTimer = nil
        } else {
            delegate?.dismissDiscovery()
            markCurrentDiscoveryComplete()
        }
        currentDiscovery = nil
    }
    
    func resetManagerSession() {
        discoveryTimer?.invalidate()
        discoveryTimer = nil
        currentDiscovery = nil
        completedDiscoveriesInSession = []
        identifiedDiscoveriesInSession = []
    }
    
    func discoveryDismissed(byUser:Bool, optIn:Bool) {
        guard let discovery = currentDiscovery, byUser || optIn else { return }
        if byUser && !optIn { LeapSharedInformation.shared.discoveryDismissedByUser(discoveryId: discovery.id) }
        markCurrentDiscoveryComplete()
    }
    
    func markCurrentDiscoveryComplete() {
        guard let discovery = currentDiscovery else { return }
        if !(completedDiscoveriesInSession.contains(discovery.id)) { completedDiscoveriesInSession.append(discovery.id) }
        currentDiscovery = nil
    }
    
}

