//
//  LeapAssistManager.swift
//  LeapCore
//
//  Created by Aravind GS on 26/08/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

protocol LeapAssistManagerDelegate:NSObjectProtocol {

    func getAllAssists() -> Array<LeapAssist>
    func newAssistIdentified(_ assist:LeapAssist, view:UIView?, rect:CGRect?, inWebview:UIView?)
    func sameAssistIdentified(view:UIView?, rect:CGRect?, inWebview:UIView?)
    func dismissAssist()
    
}


class LeapAssistManager {
    
    private weak var delegate:LeapAssistManagerDelegate?
    private weak var currentAssist:LeapAssist?
    private var assistTimer:Timer?
    private var assistsCompletedInSession:Array<Int> = []
    
    init(_ assistDelegate:LeapAssistManagerDelegate) { delegate = assistDelegate }
    
    func getAssistsToCheck() -> Array<LeapAssist> {
        let assistSessionCount = LeapSharedInformation.shared.getAssistsPresentedInfo()
        let assistsDismissedByUser = LeapSharedInformation.shared.getDismissedAssistInfo()
        guard let allAssists = delegate?.getAllAssists() else { return [] }
        var assistsToCheck = allAssists.filter { (tempAssist) -> Bool in
            /// Eliminate assists already presented in current session
            if assistsCompletedInSession.contains(tempAssist.id) { return false }
            
            /// Elimination using termination frequency
            if let terminationFreq = tempAssist.terminationFrequency {
                ///Eliminate nDismissByUser
                if let dismissByUser = terminationFreq.nDismissByUser, dismissByUser > -1 {
                    if assistsDismissedByUser.contains(tempAssist.id) { return false }
                }
                /// Eliminate nSessions
                if let nSessions = terminationFreq.nSession, nSessions > -1 {
                    let currentAssistSessionCount = assistSessionCount[String(tempAssist.id)] ?? 0
                    if currentAssistSessionCount >= nSessions { return false }
                }
            }
            return true
        }
        guard let liveAssist = currentAssist else { return assistsToCheck }
        if !assistsToCheck.contains(liveAssist) { assistsToCheck.append(liveAssist) }
        return assistsToCheck
    }
    
    func getCurrentAssist() -> LeapAssist? { return currentAssist }
    
    func triggerAssist(_ assist:LeapAssist,_ view:UIView?,_ rect:CGRect?,_ webview:UIView?) {
        
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
        let type =  currentAssist?.trigger?.type ?? .instant
        if type == .delay {
            let delay = currentAssist?.trigger?.delay ?? 0
            assistTimer = Timer(timeInterval: TimeInterval(delay/1000), repeats: false, block: { (timer) in
                self.assistTimer?.invalidate()
                self.assistTimer = nil
                self.delegate?.newAssistIdentified(assist, view: view, rect: rect, inWebview: webview)
            })
            guard let assistTimer = self.assistTimer else { return }
            RunLoop.main.add(assistTimer, forMode: .default)
        } else  {
            delegate?.newAssistIdentified(assist, view: view, rect: rect, inWebview: webview)
        }
    }
    
    func resetAssistManager() {
        guard let _ = currentAssist else { return }
        if assistTimer != nil {
            assistTimer?.invalidate()
            assistTimer = nil
        } else {
            self.delegate?.dismissAssist()
            markCurrentAssistComplete()
        }
        currentAssist = nil
    }
    
    func resetManagerSession() {
        assistTimer?.invalidate()
        assistTimer = nil
        currentAssist = nil
        assistsCompletedInSession = []
    }
    
    func assistPresented() {
        guard let assist = currentAssist else { return }
        LeapSharedInformation.shared.assistPresented(assistId: assist.id)
    }
    
    func assistDismissed(byUser:Bool, autoDismissed:Bool) {
        guard let assist = currentAssist, byUser || autoDismissed  else { return }
        if byUser { LeapSharedInformation.shared.assistDismissedByUser(assistId: assist.id) }
        markCurrentAssistComplete()
    }
    
    func markCurrentAssistComplete() {
        guard let assist = currentAssist else { return }
        if !(assistsCompletedInSession.contains(assist.id)) { assistsCompletedInSession.append(assist.id) }
        currentAssist = nil
    }
    
}
