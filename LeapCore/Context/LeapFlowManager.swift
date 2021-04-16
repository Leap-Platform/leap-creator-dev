//
//  LeapFlowManager.swift
//  LeapCore
//
//  Created by Aravind GS on 12/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

protocol LeapFlowManagerDelegate:NSObjectProtocol {
    func noActiveFlows()
}

class LeapFlowManager {
    private weak var delegate:LeapFlowManagerDelegate?
    private var flowsArray:Array<LeapFlow> = []
    private var indexFromLast:Int = 0
    private var startedFromDiscovery:Int?
    
    init(_ flowDelegate:LeapFlowManagerDelegate) {
        delegate = flowDelegate
    }
    
    func getFlowsToCheck() -> Array<LeapFlow> { return flowsArray }
    
    func addNewFlow(_ flow:LeapFlow, _ isBranch:Bool,_ disId:Int?) {
        if !isBranch{
            startedFromDiscovery = disId
            flowsArray.removeAll()
        }
        flowsArray.append(flow)
    }
    
    func getRelevantFlow(lookForParent:Bool) -> LeapFlow? {
        if lookForParent { indexFromLast += 1 }
        else { indexFromLast = 0 }
        if flowsArray.count <= indexFromLast {
            indexFromLast = 0
            return nil
        }
        return flowsArray[(flowsArray.count - 1) - indexFromLast]
    }
    
    func getArrayOfFlows() -> Array<LeapFlow> { return flowsArray }
    
    func updateFlowArrayAndResetCounter() {
        if indexFromLast == 0 { return }
        flowsArray.removeLast(indexFromLast)
        indexFromLast = 0
    }
    
    func popLastFlow() {
        guard flowsArray.count > 0 else { return }
        let _ = flowsArray.popLast()
        if flowsArray.count == 0, let delegate = self.delegate { delegate.noActiveFlows() }
    }
    
    func getDiscoveryId() -> Int? { return startedFromDiscovery }
    
    func resetFlowsArray () {
        flowsArray = []
        indexFromLast = 0
    }
    
}
