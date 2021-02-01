//
//  JinyStageManager.swift
//  JinySDK
//
//  Created by Aravind GS on 12/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

protocol JinyStageManagerDelegate:NSObjectProtocol {
    func newStageFound(_ stage:JinyStage, view:UIView?, rect:CGRect?, webviewForRect:UIView?)
    func sameStageFound(_ stage:JinyStage, newRect:CGRect?, webviewForRect:UIView?)
    func dismissStage()
    func removeStage(_ stage:JinyStage)
    func isSuccessStagePerformed()
}

class JinyStageManager {
    private weak var delegate:JinyStageManagerDelegate?
    private var currentStage:JinyStage?
    private var stageTracker:Dictionary<String,Int> = [:]
    private var stageTimer:Timer?
    
    init(_ stageDelegate:JinyStageManagerDelegate) {
        delegate = stageDelegate
    }
    
    func setCurrentStage(_ stage:JinyStage, view:UIView?, rect:CGRect?, webviewForRect:UIView?) {
        if currentStage == stage {
            if stageTimer == nil { delegate?.sameStageFound(stage, newRect: rect, webviewForRect: webviewForRect) }
            return
        }
        
        if currentStage != nil {
            if stageTimer != nil {
                stageTimer?.invalidate()
                stageTimer = nil
            } else {
                delegate?.dismissStage()
                stagePerformed()
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
    
    func resetStageManager() {
        guard let stage = currentStage else { return }
        if stageTimer != nil {
            stageTimer?.invalidate()
            stageTimer = nil
        } else {
            delegate?.dismissStage()
            stagePerformed()
        }
        
        
    }
    
    // Called in case to reidentify same stage as new stage next time
    func resetCurrentStage() { currentStage = nil }
    
    func sameStage (_ newStage:JinyStage, _ view:UIView?, _ rect:CGRect?, _ webviewForRect:UIView?) {
        delegate?.sameStageFound(newStage, newRect: rect, webviewForRect: webviewForRect)
    }
    
    func getCurrentStage() -> JinyStage? { return currentStage }
    
    func stageDismissed(byUser:Bool, autoDismissed:Bool) {
        guard byUser || autoDismissed else { return }
        guard let stage = currentStage else { return }
        if stage.type == .Sequence || stage.type == .ManualSequence { delegate?.removeStage(stage) }
        stagePerformed()
    }
    
    func stagePerformed() {
        guard let stage = currentStage else { return }
        if stageTracker[stage.name] == nil { stageTracker[stage.name] = 0 }
        stageTracker[stage.name]!  += 1
        if stageTracker[stage.name]! >= stage.frequencyPerFlow { delegate?.removeStage(stage) }
        currentStage = nil
    }

    
}
