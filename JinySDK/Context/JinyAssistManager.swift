//
//  JinyAssistManager.swift
//  JinySDK
//
//  Created by Aravind GS on 26/08/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

protocol JinyAssistManagerDelegate:NSObjectProtocol {
    
    func getTriggeredEvents() -> Dictionary<String,Any>
    func newAssistIdentified(_ assist:JinyAssist, view:UIView?, rect:CGRect?, inWebview:UIView?)
    func sameAssistIdentified(view:UIView?, rect:CGRect?, inWebview:UIView?)
    func dismissAssist()
    
}


class JinyAssistManager {
    
    private weak var delegate:JinyAssistManagerDelegate?
    private var assistsToCheck:Array<JinyAssist> = []
    private var currentAssist:JinyAssist?
    private var assistTimer:Timer?
    
    
    
    init(_ assistDelegate:JinyAssistManagerDelegate) { delegate = assistDelegate }
    
    func setAssistsToCheck(assists:Array<JinyAssist>) { assistsToCheck = assists }
    
    func getAssistsToCheck() -> Array<JinyAssist> { return assistsToCheck }
    
    func getCurrentAssist() -> JinyAssist? { return currentAssist }
    
    func triggerAssist(_ assist:JinyAssist,_ view:UIView?,_ rect:CGRect?,_ webview:UIView?) {
        let prevAssist = currentAssist
        currentAssist = assist
        
        if prevAssist == currentAssist {
            if assistTimer == nil { self.delegate?.sameAssistIdentified(view: view, rect: rect, inWebview: webview)}
            return
        }
        
        if prevAssist != nil {
            if assistTimer != nil {
                assistTimer?.invalidate()
                assistTimer = nil
            } else { self.delegate?.dismissAssist() }
        }
        
        let type =  currentAssist?.trigger?.type ?? "instant"
        if type == "delay" {
            let delay = currentAssist?.trigger?.delay ?? 0
            assistTimer = Timer(timeInterval: TimeInterval(delay/1000), repeats: false, block: { (timer) in
                self.assistTimer?.invalidate()
                self.assistTimer = nil
                self.delegate?.newAssistIdentified(assist, view: view, rect: rect, inWebview: webview)
            })
            RunLoop.main.add(assistTimer!, forMode: .default)
        } else  { delegate?.newAssistIdentified(assist, view: view, rect: rect, inWebview: webview) }
    }
    
    func resetManager() {
        guard let _ = currentAssist else { return }
        self.delegate?.dismissAssist()
        assistTimer?.invalidate()
        assistTimer = nil
        currentAssist = nil
    }
    
    func resetAssist() { currentAssist = nil }
    
}
