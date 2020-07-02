//
//  JinyFlowManager.swift
//  JinySDK
//
//  Created by Aravind GS on 12/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

protocol JinyFlowManagerDelegate {
    
    func noActiveFlows()
    
}

class JinyFlowManager {
    private let delegate:JinyFlowManagerDelegate
    private var flowsArray:Array<JinyFlow> = []
    private var indexFromLast:Int = 0
    
    init(_ flowDelegate:JinyFlowManagerDelegate) {
        delegate = flowDelegate
    }
    
    func getFlowsToCheck() -> Array<JinyFlow> { return flowsArray }
    
    func addNewFlow(_ flow:JinyFlow, _ isBranch:Bool) {
        if !isBranch{ flowsArray.removeAll()}
        flowsArray.append(flow)
    }
    
    func getRelevantFlow(lookForParent:Bool) -> JinyFlow? {
        if lookForParent { indexFromLast += 1 }
        else { indexFromLast = 0 }
        if flowsArray.count <= indexFromLast {
            indexFromLast = 0
            return nil
        }
        return flowsArray[(flowsArray.count - 1) - indexFromLast]
    }
    
    func updateFlowArrayAndResetCounter() {
        if indexFromLast == 0 { return }
        flowsArray.removeLast(indexFromLast)
        indexFromLast = 0
    }
    
    func popLastFlow() {
        guard flowsArray.count > 0 else { return }
        let _ = flowsArray.popLast()
        if flowsArray.count == 0 { delegate.noActiveFlows() }
    }
    
    func resetFlowsArray () { flowsArray = [] }
    
    func removeStage(_ stage:JinyStage) {
        for flow in flowsArray {
            for page in flow.pages {
                page.stages = page.stages.filter { $0 != stage }
            }
        }
    }
}
