//
//  JinyTriggerManager.swift
//  JinySDK
//
//  Created by Aravind GS on 03/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

protocol JinyTriggerManagerDelegate {
    
    func getMutedTriggerIds() -> Array<Int>
    func addNewTriggerToMute(_ id:Int)
    func newTriggerIdentified(_ trigger:JinyTrigger)
    func sameTriggerIdentified(_ trigger:JinyTrigger)
    func noContextualTrigger()
}

class JinyTriggerManager {
    
    private let delegate:JinyTriggerManagerDelegate
    private var allTriggers:Array<JinyTrigger> = []
    private var currentTrigger:JinyTrigger?
    private var completedTriggers:Array<JinyTrigger> = []
    private var identifiedTriggers:Array<JinyTrigger> = []
    
    init(_ triggerDelegate:JinyTriggerManagerDelegate) { delegate = triggerDelegate }
    
    func setAllTriggers(_ triggers:Array<JinyTrigger>) {
        for trigger in triggers { allTriggers.append(trigger.copy()) }
    }
    
    func getTriggersToCheck() -> Array<JinyTrigger> { return allTriggers.filter{ !getMutedTriggers().contains($0)}.filter{ !completedTriggers.contains($0)} }
    
    func getAllTriggers() -> Array<JinyTrigger> { return allTriggers }
    
    func addTriggerToIdentifiedList(_ trigger:JinyTrigger) {
        if identifiedTriggers.contains(trigger) { identifiedTriggers = identifiedTriggers.filter{ $0 != trigger }}
        identifiedTriggers.append(trigger)
        currentTrigger = trigger
    }
    
    func getTriggersToCheckForContextualTriggering() -> Array<JinyTrigger> { return getMutedTriggers() + completedTriggers + identifiedTriggers }
    
    func getCurrentTrigger() -> JinyTrigger? { return currentTrigger }
    
    func resetCurrentTrigger() { currentTrigger = nil }
    
    func triggerFound(_ trigger:JinyTrigger) {
        let previousTrigger = currentTrigger
        currentTrigger = trigger
        if previousTrigger == currentTrigger { delegate.sameTriggerIdentified(trigger) }
        else { delegate.newTriggerIdentified(trigger) }
    }
    
    func noTriggerFound() {
        delegate.noContextualTrigger()
        currentTrigger = nil
    }
    
    func currentTriggerCompleted() {
        guard let completedTrigger = currentTrigger else { return }
        completedTriggers.append(completedTrigger)
        currentTrigger  = nil
    }
    
    func muteCurrentTrigger() {
        guard let triggerToMute = currentTrigger else { return }
        delegate.addNewTriggerToMute(triggerToMute.id)
        addTriggerToIdentifiedList(triggerToMute)
        currentTrigger = nil
    }
    
    func getMutedTriggers() -> Array<JinyTrigger> {
        let mutedTriggerIds = delegate.getMutedTriggerIds()
        return allTriggers.filter{ mutedTriggerIds.contains($0.id) }
    }
    
    func getCompletedTriggers() -> Array<JinyTrigger> { return completedTriggers }
    
}
