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
    
    func getAllDiscoveries() -> Array<JinyDiscovery>
    func newDiscoveryIdentified(discovery:JinyDiscovery, view:UIView?, rect:CGRect?, webview:UIView?)
    func sameDiscoveryIdentified(discovery:JinyDiscovery, view:UIView?, rect:CGRect?, webview:UIView?)
    func dismissDiscovery()
    
}

class JinyDiscoveryManager {
    
    private weak var delegate:JinyDiscoveryManagerDelegate?
    private var completedDiscoveriesInSession:Array<Int> = []
    private weak var currentDiscovery:JinyDiscovery?
    private var discoveryTimer:Timer?
    
    init(_ withDelegate:JinyDiscoveryManagerDelegate) { delegate = withDelegate }
        
    func getCurrentDiscovery() -> JinyDiscovery? { return currentDiscovery }
    
    func getDiscoveriesToCheck() -> Array<JinyDiscovery> {
        guard var discoveriesToCheck = delegate?.getAllDiscoveries(), discoveriesToCheck.count > 0 else { return [] }
        let discoveryPresentedCount = JinySharedInformation.shared.getDiscoveriesPresentedInfo()
        let discoveryDismissInfo = JinySharedInformation.shared.getDismissedDiscoveryInfo()
        let discoveryFlowInfo = JinySharedInformation.shared.getDiscoveryFlowCompletedInfo()
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
        return discoveriesToCheck
    }
    
    func triggerDiscovery(_ discovery:JinyDiscovery,_ view:UIView?,_ rect:CGRect?,_ webview:UIView?) {
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
        if type == .delay {
            let delay = currentDiscovery?.trigger?.delay ?? 0
            discoveryTimer = Timer(timeInterval: TimeInterval(delay/1000), repeats: false, block: { (timer) in
                self.discoveryTimer?.invalidate()
                self.discoveryTimer = nil
                self.delegate?.newDiscoveryIdentified(discovery: discovery, view: view, rect: rect, webview: webview)
            })
            RunLoop.main.add(discoveryTimer!, forMode: .default)
        } else  {
            delegate?.newDiscoveryIdentified(discovery: discovery, view: view, rect: rect, webview: webview)
        }
        
    }
    
    func isManualTrigger() -> Bool {
        guard let disc = currentDiscovery else { return false }
        if completedDiscoveriesInSession.contains(disc.id) { return true }
        if let triggerType = disc.triggerFrequency?.type {
            switch triggerType {
            case .everySession:
                 return false
            case .everySessionUntilDismissed:
                return JinySharedInformation.shared.getDismissedDiscoveryInfo().contains(disc.id)
            case .everySessionUntilFlowComplete:
                return (JinySharedInformation.shared.getDiscoveryFlowCompletedInfo()[String(disc.id)] ?? 0) > 0
            case .playOnce:
                return (JinySharedInformation.shared.getDiscoveriesPresentedInfo()[String(disc.id)] ?? 0) > 0
            case .manualTrigger:
                return true
            }
        }
        return false
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
    
    func discoveryDismissed(byUser:Bool, optIn:Bool) {
        guard let discovery = currentDiscovery, byUser || optIn else { return }
        if byUser && !optIn { JinySharedInformation.shared.discoveryDismissedByUser(discoveryId: discovery.id) }
        markCurrentDiscoveryComplete()
    }
    
    func markCurrentDiscoveryComplete() {
        guard let discovery = currentDiscovery else { return }
        if !(completedDiscoveriesInSession.contains(discovery.id)) { completedDiscoveriesInSession.append(discovery.id) }
        JinySharedInformation.shared.discoveryPresent(discoveryId: discovery.id)
        currentDiscovery = nil
    }
    
}

