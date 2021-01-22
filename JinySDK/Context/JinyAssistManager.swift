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
    private var allAssists:Array<JinyAssist> = []
    private var currentAssist:JinyAssist?
    private var assistTimer:Timer?
    private var assistsCompletedInSession:Array<Int> = []
    
    init(_ assistDelegate:JinyAssistManagerDelegate) { delegate = assistDelegate }
    
    func setAssistsToCheck(assists:Array<JinyAssist>) { allAssists = assists }
    
    func getAssistsToCheck() -> Array<JinyAssist> {
        let assistSessionCount = JinySharedInformation.shared.getAssistsPresentedInfo()
        let assistsDismissedByUser = JinySharedInformation.shared.getDismissedAssistInfo()
        let assistsToCheck = allAssists.filter { (tempAssist) -> Bool in
            if assistsCompletedInSession.contains(tempAssist.id) { return false }
            if let terminationFreq = tempAssist.terminationFrequency {
                let dismissByUser = terminationFreq.nDismissByUser ?? -1
                if dismissByUser > 0 && assistsDismissedByUser.contains(tempAssist.id) { return false }
                let nSessions = terminationFreq.nSession ?? -1
                if nSessions == -1 { return true }
                let currentAssistSessionCount = assistSessionCount[tempAssist.id] ?? 0
                if currentAssistSessionCount >= nSessions { return false }
            }
            return true
        }
        return assistsToCheck
    }
    
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
            } else {
                self.delegate?.dismissAssist()
            }
        }
        
        let type =  currentAssist?.trigger?.type ?? "instant"
        if type == "delay" {
            let delay = currentAssist?.trigger?.delay ?? 0
            assistTimer = Timer(timeInterval: TimeInterval(delay/1000), repeats: false, block: { (timer) in
                self.assistTimer?.invalidate()
                self.assistTimer = nil
                self.delegate?.newAssistIdentified(assist, view: view, rect: rect, inWebview: webview)
                JinySharedInformation.shared.assistPresented(assistId: assist.id)
            })
            RunLoop.main.add(assistTimer!, forMode: .default)
        } else  {
            delegate?.newAssistIdentified(assist, view: view, rect: rect, inWebview: webview)
            JinySharedInformation.shared.assistPresented(assistId: assist.id)
        }
    }
    
    func resetManager() {
        guard let _ = currentAssist else { return }
        assistTimer?.invalidate()
        assistTimer = nil
        self.delegate?.dismissAssist()
        currentAssist = nil
    }
    
    func assistDismissedByUser() {
        guard let assist = currentAssist else { return }
        JinySharedInformation.shared.assistDismissedByUser(assistId: assist.id)
        currentAssist = nil
    }
    
}
