//
//  JinyStageManager.swift
//  JinySDK
//
//  Created by Aravind GS on 12/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

protocol JinyStageManagerDelegate {
    func newWebStageIdentified(_ stage:JinyWebStage,_ rect:CGRect?)
    func newNativeStageIdentified(_ stage:JinyNativeStage, _ view:UIView?)
    func sameWebStageIdentified(_ stage:JinyWebStage, _ rect:CGRect?)
    func sameNativeStageIdentified(_ stage:JinyNativeStage, _ view:UIView?)
    func removeStage(_ stage:JinyStage)
    func noStageIdentified()
    func isSuccessStagePerformed()
}

class JinyStageManager {
    private let delegate:JinyStageManagerDelegate
    private var currentStage:JinyStage?
    private var currentPage:JinyPage?
    private var stagesToCheck:Array<JinyStage> = []
    private var stageTracker:Dictionary<String,Int> = [:]
    
    init(_ stageDelegate:JinyStageManagerDelegate) {
        delegate = stageDelegate
    }
    
    func setCurrentPage(_ page:JinyPage?) { currentPage = page }
    
    func getCurrentPage() -> JinyPage? { return currentPage }
    
    func setArrayOfStagesFromPage(_ stages:Array<JinyStage>) { stagesToCheck = stages }
    
    func getArrayOfStagesToCheck() -> Array<JinyStage> { return stagesToCheck }
    
    func setCurrentStage(_ stage:JinyStage?, view:UIView?, rect:CGRect?) {
        
        let previousStage = currentStage
        currentStage = stage
        
        // If both current and previous stages are not identified do nothing
        if currentStage == nil && previousStage == nil { return }
        
        // If no current stage identified, mark previous stage as performed, if previous stage isSuccess stage pop the flow and wait for new stage info
        if currentStage == nil {
            stagePerformed(previousStage!)
            if previousStage!.isSuccess { delegate.isSuccessStagePerformed() }
            return
        }
        
        // If previous stage is not present and a new stage was identified, inform delegate
        if previousStage == nil {
            if let webstage = currentStage as? JinyWebStage  {
                delegate.newWebStageIdentified(webstage,rect)
            }
            else if let nativeStage = currentStage as? JinyNativeStage {
                delegate.newNativeStageIdentified(nativeStage,view)
            }
            return
        }
        
        // If current stage and previous stage are present, check if it is the same
        // If same inform delegate same stage identifed
        if currentStage == previousStage {
            sameStage(currentStage!, view, rect)
            return
        }
        
        // If current stage and previous stages are not empty but are different, mark previous stage as performed
        // If previous stage is isSuccess stage, then send success stage performed to delegate and reset current stage to nil and wait for new stage info
        stagePerformed(previousStage!)
        if previousStage!.isSuccess {
            delegate.isSuccessStagePerformed()
            currentStage = nil
            return
        }
        
        // If previous stage is not isSuccess, identify current stage as new stage
        
        if let webstage = currentStage as? JinyWebStage  {
            delegate.newWebStageIdentified(webstage,rect)
        }
        else if let nativeStage = currentStage as? JinyNativeStage {
            delegate.newNativeStageIdentified(nativeStage,view)
        }
    }
    
    // Called in case to reidentify same stage as new stage next time
    func resetCurrentStage() { currentStage = nil }
    
    func sameStage (_ newStage:JinyStage, _ view:UIView?, _ rect:CGRect?) {
        if let webstage = newStage as? JinyWebStage  {
            delegate.sameWebStageIdentified(webstage,rect)
        }
        else if let nativeStage = newStage as? JinyNativeStage {
           delegate.sameNativeStageIdentified(nativeStage,view)
        }
    }
    
    func getCurrentStage() -> JinyStage? { return currentStage }
    
    func stagePerformed(_ stage:JinyStage) {
        if stageTracker[stage.stageName] == nil { stageTracker[stage.stageName] = 0 }
        stageTracker[stage.stageName]!  += 1
        if stageTracker[stage.stageName] == stage.frequencyPerFlow { delegate.removeStage(stage) }
    }

    
}
