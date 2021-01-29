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
    
    func newDiscoveryIdentified(discovery:JinyDiscovery, view:UIView?, rect:CGRect?, webview:UIView?)
    func sameDiscoveryIdentified(discovery:JinyDiscovery, view:UIView?, rect:CGRect?, webview:UIView?)
    func dismissDiscovery()
    
}

class JinyDiscoveryManager {
    
    private weak var delegate:JinyDiscoveryManagerDelegate?
    private var allDiscoveries:Array<JinyDiscovery> = []
    private var completedDiscoveriesInSession:Array<Int> = []
    private weak var currentDiscovery:JinyDiscovery?
    private var discoveryTimer:Timer?
    
    init(_ withDelegate:JinyDiscoveryManagerDelegate) { delegate = withDelegate }
    
    func setAllDiscoveries(_ discoveries:Array<JinyDiscovery>) { allDiscoveries = discoveries }
    
    func getCurrentDiscovery() -> JinyDiscovery? { return currentDiscovery }
    
    func getDiscoveriesToCheck() -> Array<JinyDiscovery> {
        var discoveriesToCheck = allDiscoveries.filter { !completedDiscoveriesInSession.contains($0.id) }
        guard discoveriesToCheck.count > 0 else { return [] }
        let discoveryPresentedCount = JinySharedInformation.shared.getDiscoveriesPresentedInfo()
        let discoveryDismissInfo = JinySharedInformation.shared.getDismissedDiscoveryInfo()
        let discoveryFlowInfo = JinySharedInformation.shared.getDiscoveryFlowCompletedInfo()
        discoveriesToCheck = discoveriesToCheck.filter({ (discovery) -> Bool in
            let presentedCount = discoveryPresentedCount[String(discovery.id)] ?? 0
            let hasBeenDismissed = discoveryDismissInfo.contains(discovery.id)
            let discoveryFlowCompleted = discoveryFlowInfo.contains(discovery.id)
            if let triggerFrequencyType = discovery.triggerFrequency?.type {
                switch triggerFrequencyType {
                case .everySessionUntilDismissed:
                    if hasBeenDismissed { return false }
                case .everySessionUntilFlowComplete:
                    if discoveryFlowCompleted { return false }
                    break
                case .playOnce:
                    if presentedCount > 0 { return false }
                default:
                    break
                }
            }
            if let terminationFreq = discovery.frequency {
                if let nSessionCount = terminationFreq.nSession {
                    if nSessionCount != -1 &&  presentedCount >= nSessionCount { return false }
                }
                if let perAppCount = terminationFreq.perApp {
                    if perAppCount != -1 && presentedCount >= perAppCount { return false }
                }
                if let nDismissedByUser = terminationFreq.nDismissByUser {
                    if nDismissedByUser != -1 && hasBeenDismissed { return false }
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
        
        let type =  currentDiscovery?.trigger?.type ?? "instant"
        if type == "delay" {
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
    
    func resetDiscovery() {
        discoveryTimer?.invalidate()
        discoveryTimer = nil
        currentDiscovery = nil
    }
    
    func resetDiscoveryManager() {
        guard let _ = currentDiscovery else { return }
        if discoveryTimer != nil {
            discoveryTimer?.invalidate()
            discoveryTimer = nil
            currentDiscovery = nil
        } else {
            delegate?.dismissDiscovery()
            markCurrentDiscoveryComplete()
        }
        
    }
    
    func discoveryDismissed(byUser:Bool) {
        guard let discovery = currentDiscovery else { return }
        if byUser { JinySharedInformation.shared.discoveryDismissedByUser(discoveryId: discovery.id) }
        markCurrentDiscoveryComplete()
    }
    
    func markCurrentDiscoveryComplete() {
        guard let discovery = currentDiscovery else { return }
        if !(completedDiscoveriesInSession.contains(discovery.id)) { completedDiscoveriesInSession.append(discovery.id) }
        JinySharedInformation.shared.discoveryPresent(discoveryId: discovery.id)
        currentDiscovery = nil
    }
    
}

