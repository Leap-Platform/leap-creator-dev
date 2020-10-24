//
//  JinyAssistManager.swift
//  JinySDK
//
//  Created by Aravind GS on 26/08/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

protocol JinyAssistManagerDelegate {
    
    func performAssist(_ assist:JinyAssist, view:UIView?, rect:CGRect?, inWebview:UIView?)
    func sameAssistIdentified(view:UIView?, rect:CGRect?, inWebview:UIView?)
    func dismissAssist()
    
}

class JinyAssistManager {
    
    var delegate:JinyAssistManagerDelegate
    var assistsToCheck:Array<JinyAssist> = []
    var assistToBeTriggered:JinyAssist?
    var assistTimer:Timer?
    var anchorView:UIView?
    var anchorRect:CGRect?
    var anchorWebview:UIView?
    var currentAssist:JinyAssist?
    
    init(_ assistDelegate:JinyAssistManagerDelegate) {
        delegate = assistDelegate
    }
    
    func setAssistsToCheck(assists:Array<JinyAssist>) {
        assistsToCheck = assists
    }
    
    func getAssistsToCheck() -> Array<JinyAssist> {
        return assistsToCheck
    }
    
    func assistIdentified(assist:JinyAssist, view:UIView?, rect:CGRect?, webview:UIView?) {
        anchorView = view
        anchorRect = rect
        anchorWebview = webview
        if assistToBeTriggered == assist { return }
        if currentAssist == assist {
            self.delegate.sameAssistIdentified(view: view, rect: rect, inWebview: webview)
            return
        }
        JinyEventDetector.shared.delegate = self
        cancelTimer()
        assistToBeTriggered = assist
        if let delay = assistToBeTriggered?.eventIdentifiers?.delay {
            assistTimer = Timer.init(timeInterval: TimeInterval(delay/1000), target: self, selector: #selector(triggerAssist), userInfo: nil, repeats: false)
            RunLoop.current.add(assistTimer!, forMode: .default)
        } else if let waitForAnchorClick = assistToBeTriggered?.eventIdentifiers?.triggerOnAnchorClick {
            if waitForAnchorClick {return}
        } else {
            self.delegate.performAssist(assist, view: anchorView, rect: anchorRect, inWebview: anchorWebview)
        }
    }
    
    @objc func triggerAssist() {
        assistTimer?.invalidate()
        assistTimer = nil
        self.delegate.performAssist(assistToBeTriggered!, view: anchorView, rect: anchorRect, inWebview: anchorWebview)
    }
    
    func noAssistFound() {
        if assistToBeTriggered != nil { cancelTimer() }
        assistToBeTriggered = nil
        JinyEventDetector.shared.delegate = nil
    }
    
    func assistCompleted(assist:JinyAssist) {
        assistsToCheck = assistsToCheck.filter { $0 != assist}
        assistToBeTriggered = nil
    }
    
    func cancelTimer() {
        assistTimer?.invalidate()
        assistTimer = nil
    }
    
    func setCurrentAssist() {
        currentAssist = assistToBeTriggered
        assistToBeTriggered = nil
    }
    
    func currentAssistPresented() {
        
    }
    
}


extension JinyAssistManager:JinyEventDetectorDelegate {
    
    func clickDetected(view: UIView?, point: CGPoint) {
        guard let onClickTrigger = assistToBeTriggered?.eventIdentifiers?.triggerOnAnchorClick else { return }
        guard onClickTrigger else { return }
        if assistToBeTriggered!.isWeb {
            guard let rectToCheck = anchorRect else { return }
            if rectToCheck.contains(point) { self.delegate.performAssist(assistToBeTriggered!, view: anchorView!, rect: anchorRect!, inWebview: anchorWebview) }
        } else {
            guard let viewToCheck = anchorView, let viewTouched = view else { return }
            if  viewToCheck == viewTouched { self.delegate.performAssist(assistToBeTriggered!, view: anchorView, rect: anchorRect, inWebview: anchorWebview) }
        }
    }
    
    func newTaggedEvent(taggedEvents:Dictionary<String,Any>) {
        
    }
    
    
}
