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


class JinyDiscoveryManager {
    
    private weak var delegate:JinyDiscoveryManagerDelegate?
    private var allDiscoveries:Array<JinyDiscovery> = []
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
    
    func discoveryFound(_ discovery:JinyDiscovery) {
        let previousDiscovery = currentDiscovery
        currentDiscovery = discovery
        if previousDiscovery == currentDiscovery { delegate?.sameDiscoveryIdentified(discovery: discovery) }
        else { delegate?.newDiscoveryIdentified(discovery: discovery) }
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
