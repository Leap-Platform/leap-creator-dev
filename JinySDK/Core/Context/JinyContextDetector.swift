//
//  JinyContextDetector.swift
//  JinySDK
//
//  Created by Aravind GS on 06/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

/// JinyContextDetectorDelegate is a protocol that is to be implemented by the class that needs to communicate with the JinyContextDetector class. This protocol provides callbacks regarding which native/web page is identifed, native/web stage is identified. It also asks the delegate to provide the relevant flow to check from.
protocol JinyContextDetectorDelegate {
    
    func getTriggersToCheck() -> Array<JinyTrigger>
    func triggerIdentified(_ trigger:JinyTrigger)
    func noTriggerIdentified()
    
    func findCurrentFlow() -> JinyFlow?
    func checkForParentFlow()->JinyFlow?
    
    func nativePageFound(_ nativePage:JinyNativePage)
    func webPageFound(_ webPage:JinyWebPage)
    func pageNotFound()
    
    func getRelevantStages() -> Array<JinyStage>
    func nativeStageFound(_ nativeStage:JinyNativeStage,pointerView view:UIView?)
    func webStageFound(_ webStage:JinyWebStage, pointerRect rect:CGRect?)
    func stageNotFound()
}

enum JinyContextDetectionState {
    case Discovery
    case Stage
}

/// JinyContextDetector class fetches the trigger or flow to be detected  using its delegate and identifies the trigger or stege every 1 second. It informs it delegate which trigger/ stage has been identified
class JinyContextDetector {
    
    private let delegate:JinyContextDetectorDelegate
    private var contextTimer:Timer?
    private var state:JinyContextDetectionState = .Discovery
    
    init(withDelegate contextDetectorDelegate:JinyContextDetectorDelegate, andConfig jinyConfig:JinyConfig) {
        delegate = contextDetectorDelegate        
    }
    
    func start() {
        contextTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(fetchViews), userInfo: nil, repeats: true)
    }
    
    func stop() {
        contextTimer?.invalidate()
        contextTimer = nil
    }
    
    func getState() ->JinyContextDetectionState { return state }
    
    func switchState() {
        switch state {
        case .Discovery:
            state = .Stage
        case .Stage:
            state = .Discovery
        }
    }
    
}


// MARK: - HIERARCHY FETCHER
extension JinyContextDetector {
    
    @objc private func fetchViews() {
        let allViews = fetchViewHierarchy()
        switch state {
        case .Discovery:
            let triggersToCheck = delegate.getTriggersToCheck()
            guard triggersToCheck.count > 0 else {
                delegate.noTriggerIdentified()
                return
            }
            guard let triggerFound = getTriggerIdentifedFromList(triggers: triggersToCheck, hierarchy: allViews) else {
                delegate.noTriggerIdentified()
                return
            }
            delegate.triggerIdentified(triggerFound)
        case .Stage:
            guard let currentFlow = delegate.findCurrentFlow() else {
                delegate.pageNotFound()
                return
            }
            findPageForFlow(currentFlow, inHierarchy: allViews)
        }
        
    }
    
    func fetchViewHierarchy() -> [UIView] {
        var views:[UIView] = []
        var allWindows:Array<UIWindow> = []
        allWindows = UIApplication.shared.windows
        let keyWindow = UIApplication.shared.keyWindow
        if keyWindow != nil {
            if !allWindows.contains(keyWindow!) { allWindows.append(keyWindow!)}
        }
        for window in allWindows { views.append(contentsOf: getChildren(window))}
        return views
    }
    
    private func getChildren(_ currentView:UIView) -> [UIView] {
        var subviewArray:[UIView] = []
        subviewArray.append(currentView)
        let childrenToCheck = (currentView.window == UIApplication.shared.keyWindow) ? getVisibleChildren(currentView.subviews) : currentView.subviews
        for subview in childrenToCheck {
            subviewArray.append(contentsOf: getChildren(subview))
        }
        return subviewArray
    }
    
     private func getVisibleChildren(_ views: Array<UIView>) -> Array<UIView> {
           var visibleViews = views
           
           for view in views.reversed() {
               if !visibleViews.contains(view) { continue }
               let indexOfView =  views.firstIndex(of: view)
               if indexOfView == nil  { break }
               if indexOfView == 0 { break }
               let viewsToCheck = visibleViews[0..<indexOfView!]
               let hiddenViews = viewsToCheck.filter { view.frame.contains($0.frame) }
               visibleViews = visibleViews.filter { !hiddenViews.contains($0) }
           }
           return visibleViews
       }
}

// MARK: - TRIGGER IDENTIFICATION
extension JinyContextDetector {
    
    private func getTriggerIdentifedFromList (triggers:Array<JinyTrigger>, hierarchy:[UIView]) -> JinyTrigger? {
        var selectedTrigger:JinyTrigger?
        var maxWeight:Int = 0
        for trigger in triggers {
            if isTriggerLaunchable(trigger, hierarchy: hierarchy) {
                if (selectedTrigger != nil && maxWeight < trigger.weight) || selectedTrigger == nil {
                    selectedTrigger = trigger
                    maxWeight = trigger.weight
                }
            }
        }
        return selectedTrigger
    }
    
    private func isTriggerLaunchable(_ trigger:JinyTrigger, hierarchy:[UIView]) -> Bool {
        guard let identifiers = trigger.identifiers else { return false }
        if identifiers.nativeIdentifiers.count > 0  {
            for identifier in identifiers.nativeIdentifiers {
                if !isNativeStage(identifier, presentIn: hierarchy) { return false }
            }
            return true
        } else if identifiers.webIdentifiers.count > 0 {
            
            
            
        } else { return false }
        return true
        
    }
    
    
    
}


// MARK: - PAGE IDENTIFICATION
extension JinyContextDetector {
    
    private func findPageForFlow(_ flow:JinyFlow?, inHierarchy hierarchy:Array<UIView> ) {
        guard let currentFlow = flow else {
            delegate.pageNotFound()
            return
        }
        if let currentNativePage = findCurrentNativePage(currentFlow.nativePages, hierarchy) {
            delegate.nativePageFound(currentNativePage)
            findNativeStage(inHierarchy: hierarchy)
            
        } else if let currentWebPage = findCurrentWebPage(currentFlow.webPages, hierarchy) {
            delegate.webPageFound(currentWebPage)
        } else {
            findPageForFlow(delegate.checkForParentFlow(), inHierarchy: hierarchy)
        }
    }
    
    func findCurrentNativePage(_ nativePages:Array<JinyNativePage>?, _ inHierarchy:Array<UIView>) -> JinyNativePage? {
        guard let nativeArray = nativePages else { return nil }
        var maxWeight = 0
        var tempIdentifiedPage:JinyNativePage?
        for nativePage in nativeArray {
            nativePageIdentifiable(nativePage, inHierarchy) { (isPage, currentWeight) in
                if isPage && currentWeight > maxWeight {
                    tempIdentifiedPage = nativePage
                    maxWeight = currentWeight
                }
            }
        }
        return tempIdentifiedPage
    }
    
    private func nativePageIdentifiable(_ page:JinyNativePage, _ allViews:Array<UIView>, checkCompleted:(_ isPage:Bool, _ weight:Int)->Void) {
        var pageWeight = 0
        for stage in page.pageIdentifers {
            if !(isNativeStage(stage, presentIn: allViews))  {
                checkCompleted(false,0)
                return
            }
            pageWeight += stage.matches["weight"] as? Int ?? 1
        }
        checkCompleted(true,pageWeight)
    }
    
    func findCurrentWebPage(_ webPages:Array<JinyWebPage>, _ inHierarchy:Array<UIView>) -> JinyWebPage? {
        return nil
    }
    
}


// MARK: - NATIVE STAGE IDENTIFICATION
extension JinyContextDetector {
    private func isNativeStage(_ stage:JinyNativeIdentifer, presentIn views:Array<UIView>) -> Bool {
        let matchingViews = getViews(forIdentifier: stage, inHierarchy: views)
        return matchingViews.count > 0
    }
    
    private func getViews(forIdentifier identifier: JinyNativeIdentifer, inHierarchy hierarchy:Array<UIView>) -> Array<UIView>{
        let views = hierarchy.filter { (view) -> Bool in
            switch identifier.searchType {
            case .AccID:
                return view.accessibilityIdentifier == identifier.searchString
            case .AccLabel:
                return view.accessibilityLabel == identifier.searchString
            case .Tag:
                return view.tag == Int(identifier.searchString)
            default:
                return false
            }
        }
        guard views.count > 0 else { return views }
        if identifier.childInfo.count > 0 {
            var finalViews:Array<UIView> = []
            for view in views {
                let childView = findChildForView(view, withChildInfo: identifier.childInfo)
                if childView != nil { finalViews.append(childView!) }
            }
            return finalViews
        }
        else if let siblingInfo = identifier.siblingInfo {
            var finalViews:Array<UIView> = []
            for view in views {
                let siblingView = findSiblingForView(view, withSiblingInfo: siblingInfo)
                if siblingView != nil { finalViews.append(siblingView!) }
            }
            return finalViews
        }
        return views
    }
    
    private func findChildForView(_ view:UIView, withChildInfo:Array<String>) -> UIView? {
        var tempView = view
        for stringIndex in withChildInfo {
            guard let index = Int(stringIndex), tempView.subviews.count > index else { return nil }
            tempView = tempView.subviews[index]
        }
        return tempView
    }
    
    private func findSiblingForView(_ view:UIView, withSiblingInfo:String) -> UIView? {
        guard let parentView = view.superview, let index = Int(withSiblingInfo), parentView.subviews.count > index  else { return nil }
        return parentView.subviews[index]
    }
    
    private func findNativeStage (inHierarchy views:Array<UIView>) {
        guard let stages = delegate.getRelevantStages() as? Array<JinyNativeStage> else {
            delegate.stageNotFound()
            return
        }
        if stages.count == 0 { delegate.stageNotFound() }
        guard let stageIdentified = findCurrentNativeStage(stages, views) else {
            delegate.stageNotFound()
            return
        }
        guard let pointerIdentifer = stageIdentified.pointerIdentfier else {
            delegate.nativeStageFound(stageIdentified, pointerView: nil)
            return
        }
        let pointerViews = getViews(forIdentifier: pointerIdentifer, inHierarchy: views)
        delegate.nativeStageFound(stageIdentified, pointerView: pointerViews.first)
    }
    
    private func findCurrentNativeStage(_ stages:Array<JinyNativeStage>, _ inViews:Array<UIView>) -> JinyNativeStage? {
        var maxWeight = 0
        var stageIdentified:JinyNativeStage?
        for stage in stages {
            var currentWeight = 0
            var isStagePresent = true
            for stageIdentifier in stage.stageIdentifiers {
                if isNativeStage(stageIdentifier, presentIn: inViews){
                    currentWeight += stageIdentifier.matches["weight"] as? Int ?? 1
                } else {
                    isStagePresent = false
                    break
                }
            }
            if isStagePresent && currentWeight > maxWeight {
                stageIdentified = stage
                maxWeight = currentWeight
            }
        }
        return stageIdentified
    }
}


// MARK: - WEB STAGE IDENTIFICATION
extension JinyContextDetector {
    
    private func findWebStage () {
        let stages = delegate.getRelevantStages()
        if stages.count == 0 { delegate.stageNotFound() }
    }
    
}
