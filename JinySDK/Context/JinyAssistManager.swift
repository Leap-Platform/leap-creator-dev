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

    func newAssistIdentified(_ assist:JinyAssist, view:UIView?, rect:CGRect?, inWebview:UIView?)
    func sameAssistIdentified(view:UIView?, rect:CGRect?, inWebview:UIView?)
    func dismissAssist()
    
}


class JinyAssistManager {
    
    private weak var delegate:JinyAssistManagerDelegate?
    private var allAssists:Array<JinyAssist> = []
    private weak var currentAssist:JinyAssist?
    private var assistTimer:Timer?
    private var assistsCompletedInSession:Array<Int> = []
    
    init(_ assistDelegate:JinyAssistManagerDelegate) { delegate = assistDelegate }
    
    func setAssistsToCheck(assists:Array<JinyAssist>) { allAssists = assists }
    
    func getAssistsToCheck() -> Array<JinyAssist> {
        let assistSessionCount = JinySharedInformation.shared.getAssistsPresentedInfo()
        let assistsDismissedByUser = JinySharedInformation.shared.getDismissedAssistInfo()
        let assistsToCheck = allAssists.filter { (tempAssist) -> Bool in
            /// Eliminate assists already presented in current session
            if assistsCompletedInSession.contains(tempAssist.id) { return false }
            
            /// Elimination using termination frequency
            if let terminationFreq = tempAssist.terminationFrequency {
                ///Eliminate nDismissByUser
                if let dismissByUser = terminationFreq.nDismissByUser ?? -1, dismissByUser > -1 {
                    if assistsDismissedByUser.contains(tempAssist.id) { return false }
                }
                /// Eliminate nSessions
                if let nSessions = terminationFreq.nSession ?? -1, nSessions > -1 {
                    let currentAssistSessionCount = assistSessionCount[String(tempAssist.id)] ?? 0
                    if currentAssistSessionCount >= nSessions { return false }
                }
            }
            return true
        }
        return assistsToCheck
    }
    
    func getCurrentAssist() -> JinyAssist? { return currentAssist }
    
    func triggerAssist(_ assist:JinyAssist,_ view:UIView?,_ rect:CGRect?,_ webview:UIView?) {
        
        if assist == currentAssist {
            if assistTimer == nil  { self.delegate?.sameAssistIdentified(view: view, rect: rect, inWebview: webview) }
            return
        }
        
        if currentAssist != nil {
            if assistTimer != nil {
                assistTimer?.invalidate()
                assistTimer = nil
            } else {
                self.delegate?.dismissAssist()
                markCurrentAssistComplete()
            }
        }
        
        currentAssist = assist
        let type =  currentAssist?.trigger?.type ?? "instant"
        if type == "delay" {
            let delay = currentAssist?.trigger?.delay ?? 0
            assistTimer = Timer(timeInterval: TimeInterval(delay/1000), repeats: false, block: { (timer) in
                self.assistTimer?.invalidate()
                self.assistTimer = nil
                self.delegate?.newAssistIdentified(assist, view: view, rect: rect, inWebview: webview)
            })
            RunLoop.main.add(assistTimer!, forMode: .default)
        } else  {
            delegate?.newAssistIdentified(assist, view: view, rect: rect, inWebview: webview)
        }
    }
    
    func resetAssistManager() {
        guard let _ = currentAssist else { return }
        if assistTimer != nil {
            assistTimer?.invalidate()
            assistTimer = nil
            currentAssist = nil
        } else {
            self.delegate?.dismissAssist()
            markCurrentAssistComplete()
        }
    }
    
    func assistDismissed(byUser:Bool, autoDismissed:Bool) {
        guard let assist = currentAssist, byUser || autoDismissed  else { return }
        if byUser { JinySharedInformation.shared.assistDismissedByUser(assistId: assist.id) }
        markCurrentAssistComplete()
    }
    
    func markCurrentAssistComplete() {
        guard let assist = currentAssist else { return }
        if !(assistsCompletedInSession.contains(assist.id)) { assistsCompletedInSession.append(assist.id) }
        JinySharedInformation.shared.assistPresented(assistId: assist.id)
        currentAssist = nil
    }
    
}
