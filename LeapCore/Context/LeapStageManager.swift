//
//  LeapStageManager.swift
//  LeapCore
//
//  Created by Aravind GS on 12/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

protocol LeapStageManagerDelegate:NSObjectProtocol {
    func getCurrentPage() -> LeapPage?
    func newStageFound(_ stage:LeapStage, view:UIView?, rect:CGRect?, webviewForRect:UIView?)
    func sameStageFound(_ stage:LeapStage, view:UIView?, newRect:CGRect?, webviewForRect:UIView?)
    func dismissStage()
    func removeStage(_ stage:LeapStage)
    func isSuccessStagePerformed()
}

class LeapStageManager {
    private weak var delegate:LeapStageManagerDelegate?
    private var currentStage:LeapStage?
    private var stageTracker:Dictionary<String,Int> = [:]
    private var stageTimer:Timer?
    
    init(_ stageDelegate:LeapStageManagerDelegate) {
        delegate = stageDelegate
    }
    
    func getStagesToCheck() -> Array<LeapStage> {
        guard let page = delegate?.getCurrentPage(), page.stages.count > 0 else { return [] }
        let stagesToCheck = page.stages.filter { (tempStage) -> Bool in
            guard let freq = tempStage.terminationFrequency, let perFlow = freq.perFlow, perFlow != -1 else { return true }
            let stagePlayedCount = stageTracker[tempStage.name] ?? 0
            return stagePlayedCount < perFlow
        }
        return stagesToCheck
    }
    
    func setCurrentStage(_ stage:LeapStage, view:UIView?, rect:CGRect?, webviewForRect:UIView?) {
        if currentStage == stage {
            if stageTimer == nil { delegate?.sameStageFound(stage, view:view, newRect: rect, webviewForRect: webviewForRect) }
            return
        }
        
        if currentStage != nil {
            if stageTimer != nil {
                stageTimer?.invalidate()
                stageTimer = nil
            } else {
                delegate?.dismissStage()
                stagePerformed()
                if stage.isSuccess {
                    currentStage = nil
                    stageTracker = [:]
                    return
                }
            }
        }
        
        currentStage = stage
        
        let type =  currentStage?.trigger?.type ?? .instant
        if type == .delay {
            let delay = currentStage?.trigger?.delay ?? 0
            stageTimer = Timer(timeInterval: TimeInterval(delay/1000), repeats: false, block: { (timer) in
                self.stageTimer?.invalidate()
                self.stageTimer = nil
                self.delegate?.newStageFound(stage, view: view, rect: rect, webviewForRect: webviewForRect)
            })
            RunLoop.main.add(stageTimer!, forMode: .default)
        } else  {
            delegate?.newStageFound(stage, view: view, rect: rect, webviewForRect: webviewForRect)
        }
    }
    
    func noStageFound() {
        guard let _ = currentStage else { return }
        if stageTimer != nil {
            stageTimer?.invalidate()
            stageTimer = nil
        } else {
            delegate?.dismissStage()
            stagePerformed()
        }
        currentStage = nil
    }
    
    func resetStageManager() {
        currentStage = nil
        stageTimer = nil
        stageTracker = [:]
    }
    
    // Called in case to reidentify same stage as new stage next time
    func resetCurrentStage() { currentStage = nil }
    
    func sameStage (_ newStage:LeapStage, _ view:UIView?, _ rect:CGRect?, _ webviewForRect:UIView?) {
        delegate?.sameStageFound(newStage,view: view, newRect: rect, webviewForRect: webviewForRect)
    }
    
    func getCurrentStage() -> LeapStage? { return currentStage }
    
    func stageDismissed(byUser:Bool, autoDismissed:Bool) {
        guard byUser || autoDismissed else { return }
        guard let stage = currentStage else { return }
        delegate?.removeStage(stage)
        stagePerformed()
        currentStage = nil
    }
    
    func stagePerformed() {
        guard let stage = currentStage else { return }
        if stageTracker[stage.name] == nil { stageTracker[stage.name] = 0 }
        stageTracker[stage.name]!  += 1
        if let terminationFrequency = stage.terminationFrequency, let perFlow = terminationFrequency.perFlow, perFlow != -1 {
            if stageTracker[stage.name]! >= perFlow { delegate?.removeStage(stage) }
        }
        if stage.isSuccess {
            delegate?.isSuccessStagePerformed()
            stageTracker = [:]
        }
    }

    
}
