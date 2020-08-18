//
//  JinyDiscoveryManager.swift
//  JinySDK
//
//  Created by Aravind GS on 30/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

protocol JinyDiscoveryManagerDelegate:AnyObject {
    
    func getMutedDiscoveryIds() -> Array<Int>
    func addDiscoveryIdToMutedList(id:Int)
    
    func newDiscoveryIdentified(discovery:JinyDiscovery)
    func sameDiscoveryIdentified(discovery:JinyDiscovery)
    func noContextualDiscoveryIdentified()
}

class JinyDiscoveryEventTrigger {
    let discovery:JinyDiscovery
    let timer:Timer?
    
    init(_ discovery:JinyDiscovery, _ timer:Timer) {
        self.discovery = discovery
        self.timer = timer
    }
}

class JinyDiscoveryManager {
    
    private weak var delegate:JinyDiscoveryManagerDelegate?
    private var allDiscoveries:Array<JinyDiscovery> = []
    private var timerArray:Array<Timer> = []
    private var toBeTriggered:Array<JinyDiscoveryEventTrigger> = []
    private var completedDiscoveriesInSession:Array<JinyDiscovery> = []
    private var identifiedDiscoveries:Array<JinyDiscovery> = [] //Muted in current session
    private var currentDiscovery:JinyDiscovery?
    
    init(_ withDelegate:JinyDiscoveryManagerDelegate) { delegate = withDelegate }
    
    func setAllDiscoveries(_ discoveries:Array<JinyDiscovery>) { allDiscoveries = discoveries }
    
    func getDiscoveriesToCheck() -> Array<JinyDiscovery> {
        return allDiscoveries.filter{ !(getMutedDiscoveries().contains($0) || completedDiscoveriesInSession.contains($0)) }
    }
    
    func getCompletedDiscoveries() -> Array<JinyDiscovery> { return completedDiscoveriesInSession }
    
    func discoveriesForContextCheck() -> Array<JinyDiscovery> { return (getMutedDiscoveries() + completedDiscoveriesInSession + identifiedDiscoveries ).reversed() }
    
    func discoveriesFound(_ discoveries:Array<JinyDiscovery>) {
        
        for trig in toBeTriggered {
            if discoveries.contains(trig.discovery) { continue }
            else { toBeTriggered = toBeTriggered.filter { $0.discovery == trig.discovery} }
        }
        
        
        for discovery in discoveries {
            let discoveriesAlreadyPresent = toBeTriggered.map { (eventTrigger) -> JinyDiscovery in
                return eventTrigger.discovery
            }
            if discoveriesAlreadyPresent.contains(discovery) {continue}
            else {
                if discovery.trigger["delay"] != nil {
                    let delay = discovery.trigger["delay"] as! Int
                    if #available(iOS 10.0, *) {
                        let timer = Timer(timeInterval: TimeInterval(delay/1000), repeats: false) { (timer) in
                            timer.invalidate()
                            self.currentDiscovery = discovery
                            self.delegate?.newDiscoveryIdentified(discovery: discovery)
                            self.cancelAllTimers()
                        }
                        RunLoop.current.add(timer, forMode: .default)
                        toBeTriggered.append(JinyDiscoveryEventTrigger(discovery, timer))
                    } else {
                        // Fallback on earlier versions
                    }
                }
            }
           
        }
//        let previousDiscovery = currentDiscovery
//        currentDiscovery = discoveries[0]
//        if previousDiscovery == currentDiscovery { delegate?.sameDiscoveryIdentified(discovery: discoveries[0]) }
//        else { delegate?.newDiscoveryIdentified(discovery: discoveries[0]) }
    }
    
    func cancelAllTimers() {
        for evtTrigger in toBeTriggered {
            evtTrigger.timer?.invalidate()
        }
        toBeTriggered.removeAll()
    }
    
    func discoveryNotFound() {
        delegate?.noContextualDiscoveryIdentified()
        currentDiscovery = nil
    }
    
    func completedCurrentDiscovery() {
        guard let discovery = currentDiscovery else { return }
        completedDiscoveriesInSession.append(discovery)
        currentDiscovery = nil
    }
    
    func setDiscovery(_ discovery:JinyDiscovery) { currentDiscovery = discovery }
    
    func getCurrentDiscovery() -> JinyDiscovery? { return currentDiscovery }
    
    func resetCurrentDiscovery() { currentDiscovery = nil }
    
    func muteCurrentDiscovery() {
        guard let discovery = currentDiscovery else { return }
        identifiedDiscoveries.append(discovery)
        delegate?.addDiscoveryIdToMutedList(id: discovery.id!)
        currentDiscovery = nil
    }
    
    func addToIdentifiedList(_ discovery:JinyDiscovery) {
        if identifiedDiscoveries.contains(discovery) { identifiedDiscoveries = identifiedDiscoveries.filter { $0 != discovery } }
        identifiedDiscoveries.append(discovery)
    }
    
    func getMutedDiscoveries() -> Array<JinyDiscovery> {
        guard let mutedIds = delegate?.getMutedDiscoveryIds() else { return [] }
        let mutedDiscoveries = allDiscoveries.filter{ mutedIds.contains($0.id!) }
        return mutedDiscoveries
    }
    
}
