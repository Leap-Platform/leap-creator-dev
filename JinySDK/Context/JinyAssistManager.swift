//
//  JinyAssistManager.swift
//  JinySDK
//
//  Created by Aravind GS on 26/08/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

enum JinyAssistStatus {
    case NoAssist
    case ToBeTriggered
    case IsPresenting
    case Presented
    case IsDismissing
    case ToRepeat
}

protocol JinyAssistManagerDelegate:NSObjectProtocol {
    
    func getTriggeredEvents() -> Dictionary<String,Any>
    func newAssistIdentified(_ assist:JinyAssist, view:UIView?, rect:CGRect?, inWebview:UIView?)
    func sameAssistIdentified(view:UIView?, rect:CGRect?, inWebview:UIView?)
    func dismissAssist()
    
}

class JinyContextTriggerObject {
    
    let context:JinyContext
    var contextTriggerTimer:Timer?
    weak var view:UIView?
    let rect:CGRect?
    weak var webview:UIView?
    
    init(with contextObj:(JinyContext,UIView?, CGRect?, UIView?), timer:Timer?) {
        context = contextObj.0
        view = contextObj.1
        rect = contextObj.2
        webview = contextObj.3
        contextTriggerTimer = timer
    }
    
    func cancelTimer() {
        contextTriggerTimer?.invalidate()
        contextTriggerTimer = nil
    }
    
}

class JinyAssistManager {
    
    private weak var delegate:JinyAssistManagerDelegate?
    private var triggerableAssistObjs:Array<JinyContextTriggerObject> = []
    private var assistsToCheck:Array<JinyAssist> = []
    private var currentAssist:JinyAssist?
    private var assistStatus:JinyAssistStatus = .NoAssist
    private var assistTimer:Timer?
    private weak var anchorView:UIView?
    private var anchorRect:CGRect?
    private weak var anchorWebview:UIView?
    
    
    
    init(_ assistDelegate:JinyAssistManagerDelegate) { delegate = assistDelegate }
    
    func setAssistsToCheck(assists:Array<JinyAssist>) { assistsToCheck = assists }
    
    func getAssistsToCheck() -> Array<JinyAssist> { return assistsToCheck }
    
    func assistsIdentified(assistObjs:Array<(JinyAssist,UIView?,CGRect?,UIView?)>) {
        
        JinyEventDetector.shared.delegate = self
        
        // Remove assists from list which are not currently identified
        let newAssists = assistObjs.map { $0.0 }
        triggerableAssistObjs = triggerableAssistObjs.filter({ (contextObj) -> Bool in
            if newAssists.contains(contextObj.context as! JinyAssist) { return true }
            contextObj.cancelTimer()
            return false
        })
        
        // Add new assists not already in list
        let assistsAlreadyBeingTracked = triggerableAssistObjs.map{ $0.context }
        let newAssistsToBeTracked = assistObjs.filter { (contextTuple) -> Bool in
            let (tempAssist, _, _, _) = contextTuple
            return !((assistsAlreadyBeingTracked as! Array<JinyAssist>).contains(tempAssist))
        }
        for newAssistObj in newAssistsToBeTracked {
            let newAssist = newAssistObj.0
            var timer:Timer?
            if let delayInMilli = newAssist.trigger?.delay, delayInMilli > 0 {
                timer = Timer(timeInterval: TimeInterval(delayInMilli/1000), repeats: false, block: { (delayTimer) in
                    delayTimer.invalidate()
                    guard self.currentAssist == nil else {
                        return
                    }
                    self.currentAssist = newAssist
                    self.delegate?.newAssistIdentified(self.currentAssist!, view: newAssistObj.1, rect: newAssistObj.2, inWebview: newAssistObj.3)
                })
            }
            triggerableAssistObjs.append(JinyContextTriggerObject(with: newAssistObj, timer: timer))
            if timer != nil { RunLoop.main.add(timer!, forMode: .default) }
        }
        guard currentAssist == nil else { return }
        //If no assist is currently live, check if any of the assist can be triggered
        checkForAssistToTrigger()
    }
    
    func noAssistsIdentified() {
        if currentAssist != nil { delegate?.dismissAssist() }
        currentAssist = nil
        JinyEventDetector.shared.delegate = nil
        removeAllTriggerableAssists()
    }
    
    func checkForAssistToTrigger() {
       
    }
    
    func removeAllTriggerableAssists() {
        cancelTimer()
        triggerableAssistObjs.removeAll()
    }
    
    func cancelAllTimers() { for contextObj in triggerableAssistObjs { contextObj.cancelTimer() } }
    
    func assistIdentified(assist:JinyAssist, view:UIView?, rect:CGRect?, webview:UIView?) {
        
        
        if currentAssist == nil {
            // If no active assist, set values and assign as current trigger
            setAssistValues(assist, view: view, rect: rect, webview: webview)
            assistStatus = .ToBeTriggered
            newAssistIdentified(assist, view, rect, webview)
        } else if currentAssist == assist {
            // If new assist are current assist are same, then update the values
            setAssistValues(assist, view: view, rect: rect, webview: webview)
            sameAssistIdentified()
        } else {
            // New assist has come when present assist is active, dismiss current assist and wait for context detection to reidentify the assist if it is already triggered, else reassign the new assist as current assist
            switch assistStatus {
            case .ToBeTriggered:
                currentAssist = nil
                newAssistIdentified(assist,view,rect,webview)
            default:
                delegate!.dismissAssist()
                assistStatus = .IsDismissing
            }
        }
        
        
        //                anchorView = view
        //                anchorRect = rect
        //                anchorWebview = webview
        //                if assistToBeTriggered == assist { return }
        //                if currentAssist == assist {
        //                    self.delegate.sameAssistIdentified(view: view, rect: rect, inWebview: webview)
        //                    return
        //                }
        //                JinyEventDetector.shared.delegate = self
        //                cancelTimer()
        //                assistToBeTriggered = assist
        //                if let delay = assistToBeTriggered?.eventIdentifiers?.delay {
        //                    assistTimer = Timer.init(timeInterval: TimeInterval(delay/1000), target: self, selector: #selector(triggerAssist), userInfo: nil, repeats: false)
        //                    RunLoop.current.add(assistTimer!, forMode: .default)
        //                } else if let waitForAnchorClick = assistToBeTriggered?.eventIdentifiers?.triggerOnAnchorClick {
        //                    if waitForAnchorClick {return}
        //                } else {
        //                    self.delegate.newAssistIdentified(assist, view: anchorView, rect: anchorRect, inWebview: anchorWebview)
        //                }
    }
    
    private func setAssistValues(_ assist:JinyAssist?, view:UIView?, rect:CGRect?, webview:UIView?) {
        currentAssist = assist
        anchorView = view
        anchorRect = rect
        anchorWebview = webview
    }
    
    private func newAssistIdentified(_ assist:JinyAssist,_ view:UIView?,_ rect:CGRect?,_ webview:UIView?) {
        assistStatus = .ToBeTriggered
        setAssistValues(assist, view: view, rect: rect, webview: webview)
        JinyEventDetector.shared.delegate = self
        if let trigger = currentAssist?.trigger {
            if let delay = trigger.delay {
                assistTimer = Timer.init(timeInterval: TimeInterval(delay/1000), target: self, selector: #selector(triggerAssist), userInfo: nil, repeats: false)
            } else if let type = trigger.event?[constant_type], let value = trigger.event?[constant_value], type == constant_click, value == constant_optIn { triggerAssist() }
        } else { triggerAssist() }
    }
    
    private func sameAssistIdentified() {
        switch assistStatus {
        case .Presented:
            self.delegate?.sameAssistIdentified(view: anchorWebview, rect: anchorRect, inWebview: anchorWebview)
        case .ToRepeat:
            assistStatus = .ToBeTriggered
            triggerAssist()
        default:
            return
        }
    }
    
    @objc private func triggerAssist() {
        cancelTimer()
        guard let assist = currentAssist else { return }
        delegate?.newAssistIdentified(assist, view: anchorView, rect: anchorRect, inWebview: anchorWebview)
    }
    
    func noAssistFound() {
        setAssistValues(nil, view: nil, rect: nil, webview: nil)
        
    }
    
    func getCurrentAssist() -> JinyAssist? { return currentAssist }
    
    func assistCompleted(assist:JinyAssist) {
        assistsToCheck = assistsToCheck.filter { $0 != assist}
        currentAssist = nil
    }
    
    func cancelTimer() {
        assistTimer?.invalidate()
        assistTimer = nil
    }
    
    func currentAssistPresented() { assistStatus = .Presented }
    
    func repeatAssist() { assistStatus = .ToRepeat }
    
}


extension JinyAssistManager:JinyEventDetectorDelegate {
    
    func clickDetected(view: UIView?, point: CGPoint) {
        guard let assist = currentAssist else { return }
        guard let type = assist.trigger?.event?[constant_type], let value = assist.trigger?.event?[constant_value], type == constant_click, value == constant_showDiscovery else { return }
        if assist.isWeb {
            guard let rectToCheck = anchorRect else { return }
            if rectToCheck.contains(point) { triggerAssist() }
        } else {
            guard let viewToCheck = anchorView, let viewTouched = view else { return }
            if  viewToCheck == viewTouched { triggerAssist() }
        }
    }
    
    func newTaggedEvent(taggedEvents:Dictionary<String,Any>) {
        
    }
    
    
}
