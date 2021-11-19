//
//  LeapSharedInfo.swift
//  LeapCore
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

/// LeapSharedInformation class is responsible for storing and retrieving data that can be accessed through LeapCore functionality. It  stores api key,  session id, language code and mute status of the SDK

struct LeapSharedInformationConstants {
    static let assistsPresentedInSession = "leap_assists_presented"
    static let assistsDismissedByUser = "leap_assists_dismissed"
    static let discoveryPresentedInSession = "leap_discovery_presented"
    static let discoveryDismissedByUser = "leap_discovery_dismissed"
    static let discoveryFlowCompleted = "leap_discovery_flow_completed"
    static let terminatedDiscoveries = "leap_terminated_discoveries"
    static let mutedDiscoveries = "leap_muted_discoveries"
    static let muted = "leap_muted"
    static let discoveryTerminationSent = "leap_discovery_termination_sent"
    static let assistTerminationSent = "leap_assist_termination_sent"
    static let completedFlows = "leap_completed_flows"
}

enum LeapDownloadStatus {
    case notDownloaded
    case isDownloading
    case downloaded
}

class LeapSharedInformation {
    static let shared = LeapSharedInformation()
    private let prefs = UserDefaults.standard
    private var sessionId:String?
    
    private var assistsPresentedInPreviewSession:Dictionary<String,Int> = [:]
    private var assistsDismissedByUserInPreview:Array<Int> = []
    private var discoveryPresentedInPreviewSession:Dictionary<String,Int> = [:]
    private var discoveryDismissedByUserInPreview:Array<Int> = []
    private var discoveryFlowCompletedInPreview:Dictionary<String,Int> = [:]
    private var mutedDiscoveriesInPreview:Array<Int> = []
    private var terminatedDiscoveriesInPreview:Array<Int> = []
    private var completedFlowsInPreview:Dictionary<String,Array<Int>> = [:]
    private var assistTerminationSentInPreview:Array<Int> = []
    private var discoveryTerminationSentInPreview:Array<Int> = []
}


// MARK: - API KEY GETTER AND SETTER
extension LeapSharedInformation {
    
    func setAPIKey(_ token: String) {
        guard !token.isEmpty else { fatalError("Empty Token") }
        prefs.setValue(token, forKey: constant_LeapAPIKey)
    }
    
    func getAPIKey() -> String? { return prefs.object(forKey: constant_LeapAPIKey) as? String }
}

// MARK: - SESSION ID GENERATOR, GETTER AND SETTER
extension LeapSharedInformation {
    
    func getSessionId() -> String? {
           if sessionId == nil { setSessionId() }
           return sessionId
       }
       
       func setSessionId() {
           guard sessionId == nil else { return }
           sessionId = generateSessionId()
       }
       
       func generateSessionId() -> String {
           let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
           let randomString = String((0..<32).map{_ in letters.randomElement()!})
           return randomString
       }
    
}

// MARK: - LEAP ID GENERATOR, GETTER AND SETTER

extension LeapSharedInformation {
    
    func getLeapId() -> String {
        guard let leapId = prefs.value(forKey: "leap_id") as? String else { return generateLeapId() }
        return leapId
    }
    
    private func generateLeapId() -> String {
        let leapId =  "\(randomString(8))-\(randomString(4))-\(randomString(4))-\(randomString(4))-\(randomString(12))"
        prefs.setValue(leapId, forKey: "leap_id")
        prefs.synchronize()
        return leapId
    }
    
    func randomString(_ length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        let randomString = String((0..<length).map{_ in letters.randomElement()!})
        return randomString
    }
}

// MARK: - APP INFO
extension LeapSharedInformation {
    func getVersionCode() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
    
    func getVersionName() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
}

// MARK: - ASSIST HANDLING
extension LeapSharedInformation {
    
    func assistPresentedInSession(assistId:Int, isPreview:Bool) {
        var assistsPresent = getAssistsPresentedInfo(isPreview: isPreview)
        let currentAssistCount = assistsPresent[String(assistId)] ?? 0
        assistsPresent[String(assistId)] = currentAssistCount + 1
        guard !isPreview else {
            assistsPresentedInPreviewSession = assistsPresent
            return
        }
        prefs.setValue(assistsPresent, forKey: LeapSharedInformationConstants.assistsPresentedInSession)
        prefs.synchronize()
    }
    
    func assistDismissedByUser(assistId:Int, isPreview:Bool) {
        var assistsDismissed = getDismissedAssistInfo(isPreview: isPreview)
        if !assistsDismissed.contains(assistId) { assistsDismissed.append(assistId) }
        guard !isPreview else {
            assistsDismissedByUserInPreview = assistsDismissed
            return
        }
        prefs.setValue(assistsDismissed, forKey: LeapSharedInformationConstants.assistsDismissedByUser)
        prefs.synchronize()
    }
    
    func getAssistsPresentedInfo(isPreview:Bool) -> Dictionary<String, Int>{
        return isPreview ? assistsPresentedInPreviewSession : (prefs.value(forKey: LeapSharedInformationConstants.assistsPresentedInSession) as? Dictionary<String,Int>) ?? [:]
    }
    
    func getDismissedAssistInfo(isPreview:Bool) -> Array<Int> {
        return  isPreview ? assistsDismissedByUserInPreview : (prefs.value(forKey: LeapSharedInformationConstants.assistsDismissedByUser) as? Array<Int>) ?? []
    }
}

// MARK: - DISCOVERY HANDLING {
extension LeapSharedInformation {
    
    func discoveryPresentedInSession(discoveryId:Int, isPreview:Bool) {
        var discoveryPresent = getDiscoveriesPresentedInfo(isPreview: isPreview)
        let currentDiscoveryCount = discoveryPresent[String(discoveryId)] ?? 0
        discoveryPresent[String(discoveryId)] = currentDiscoveryCount + 1
        guard !isPreview else {
            discoveryPresentedInPreviewSession = discoveryPresent
            return
        }
        prefs.setValue(discoveryPresent, forKey: LeapSharedInformationConstants.discoveryPresentedInSession)
        prefs.synchronize()
    }
    
    func discoveryDismissedByUser(discoveryId:Int, isPreview:Bool) {
        var discoveryDismissed = getDismissedDiscoveryInfo(isPreview: isPreview)
        if !discoveryDismissed.contains(discoveryId) { discoveryDismissed.append(discoveryId) }
        guard !isPreview else {
            discoveryDismissedByUserInPreview = discoveryDismissed
            return
        }
        prefs.setValue(discoveryDismissed, forKey: LeapSharedInformationConstants.discoveryDismissedByUser)
        prefs.synchronize()
    }
    
    func discoveryFlowCompleted(discoveryId:Int, isPreview:Bool) {
        var discoveryFlowCompleted = getDiscoveryFlowCompletedInfo(isPreview: isPreview)
        let flowCount =  (discoveryFlowCompleted[String(discoveryId)] ?? 0) + 1
        discoveryFlowCompleted[String(discoveryId)] = flowCount
        guard !isPreview else {
            discoveryFlowCompletedInPreview = discoveryFlowCompleted
            return
        }
        prefs.setValue(discoveryFlowCompleted, forKey: LeapSharedInformationConstants.discoveryFlowCompleted)
        prefs.synchronize()
    }
    
    func muteDisovery(_ id:Int, isPreview:Bool) {
        var mutedDiscoveries = getMutedDiscoveries(isPreview: isPreview)
        if !mutedDiscoveries.contains(id) { mutedDiscoveries.append(id) }
        guard  !isPreview else {
            mutedDiscoveriesInPreview = mutedDiscoveries
            return
        }
        prefs.setValue(mutedDiscoveries, forKey: LeapSharedInformationConstants.mutedDiscoveries)
        prefs.synchronize()
    }
    
    func unmuteDiscovery(_ id:Int, isPreview:Bool) {
        var mutedDiscoveries = getMutedDiscoveries(isPreview: isPreview)
        mutedDiscoveries = mutedDiscoveries.filter{ $0 != id }
        guard !isPreview else {
            mutedDiscoveriesInPreview = mutedDiscoveries
            return
        }
        prefs.setValue(mutedDiscoveries, forKey: LeapSharedInformationConstants.mutedDiscoveries)
        prefs.synchronize()
    }
    
    func terminateDiscovery(_ id:Int, isPreview:Bool) {
        var terminatedDiscoveries = getTerminatedDiscoveries(isPreview: isPreview)
        if !terminatedDiscoveries.contains(id) { terminatedDiscoveries.append(id) }
        guard !isPreview else {
            terminatedDiscoveriesInPreview = terminatedDiscoveries
            return
        }
        prefs.setValue(terminatedDiscoveries, forKey: LeapSharedInformationConstants.terminatedDiscoveries)
        prefs.synchronize()
    }
    
    func getMutedDiscoveries(isPreview:Bool) -> Array<Int> {
        return isPreview ? mutedDiscoveriesInPreview : prefs.array(forKey: LeapSharedInformationConstants.mutedDiscoveries) as? Array <Int> ?? []
    }
    
    func getDiscoveriesPresentedInfo(isPreview:Bool) -> Dictionary<String,Int> {
        return isPreview ? discoveryPresentedInPreviewSession : (prefs.value(forKey: LeapSharedInformationConstants.discoveryPresentedInSession) as? Dictionary<String,Int>) ?? [:]
    }

    func getDismissedDiscoveryInfo(isPreview:Bool) -> Array<Int> {
        return isPreview ? discoveryDismissedByUserInPreview : (prefs.value(forKey: LeapSharedInformationConstants.discoveryDismissedByUser) as? Array<Int>) ?? []
    }
    
    func getDiscoveryFlowCompletedInfo(isPreview:Bool) -> Dictionary<String,Int> {
        return isPreview ? discoveryFlowCompletedInPreview : (prefs.value(forKey: LeapSharedInformationConstants.discoveryFlowCompleted) as? Dictionary<String,Int>) ?? [:]
    }
    
    func getTerminatedDiscoveries(isPreview:Bool) -> Array<Int> {
        return isPreview ? terminatedDiscoveriesInPreview : (prefs.value(forKey: LeapSharedInformationConstants.terminatedDiscoveries) as? Array<Int>) ?? []
    }
    
    
}

// MARK: - RESET LEAP CONTEXT

extension LeapSharedInformation {
    
    func resetAssist(_ assistId: Int, isPreview:Bool) {
        
        var assistPresented = self.getAssistsPresentedInfo(isPreview: isPreview)
        if let _ = assistPresented[String(assistId)] {
            assistPresented[String(assistId)] = 0
        }
        if isPreview {
            assistsPresentedInPreviewSession = assistPresented
        } else {
            prefs.setValue(assistPresented, forKey: LeapSharedInformationConstants.assistsPresentedInSession)
        }
        
        
        var assistDismissed = self.getDismissedAssistInfo(isPreview: isPreview)
        if assistDismissed.contains(assistId) { assistDismissed = assistDismissed.filter{ $0 != assistId} }
        if isPreview {
            assistsDismissedByUserInPreview = assistDismissed
        } else {
            prefs.setValue(assistDismissed, forKey: LeapSharedInformationConstants.assistsDismissedByUser)
        }
        removeTerminationEventSent(discoveryId: nil, assistId: assistId, isPreview: isPreview)
    }
    
    func resetDiscovery(_ discoveryId: Int, isPreview:Bool) {
        
        var presentedDiscoveries = self.getDiscoveriesPresentedInfo(isPreview: isPreview)
        if let _ = presentedDiscoveries[String(discoveryId)] {
            presentedDiscoveries[String(discoveryId)] = 0
        }
        if isPreview {
            discoveryPresentedInPreviewSession = presentedDiscoveries
        } else {
            prefs.setValue(presentedDiscoveries, forKey: LeapSharedInformationConstants.discoveryPresentedInSession)
        }
        
        
        var dismissedDiscoveries = self.getDismissedDiscoveryInfo(isPreview: isPreview)
        if dismissedDiscoveries.contains(discoveryId) { dismissedDiscoveries = dismissedDiscoveries.filter { $0 != discoveryId} }
        if isPreview {
            discoveryDismissedByUserInPreview = dismissedDiscoveries
        } else {
            prefs.setValue(dismissedDiscoveries, forKey: LeapSharedInformationConstants.discoveryDismissedByUser)
        }
        
        var flowCompletedInfo = self.getDiscoveryFlowCompletedInfo(isPreview: isPreview)
        if let _ = flowCompletedInfo[String(discoveryId)] {
            flowCompletedInfo[String(discoveryId)] = 0
        }
        if isPreview {
            discoveryFlowCompletedInPreview = flowCompletedInfo
        } else {
            prefs.setValue(flowCompletedInfo, forKey: LeapSharedInformationConstants.discoveryFlowCompleted)
        }
        
        var flowInfo = getCompletedFlowInfo(isPreview: isPreview)
        flowInfo.removeValue(forKey: "\(discoveryId)")
        if isPreview {
            completedFlowsInPreview = flowInfo
        } else {
            prefs.setValue(flowInfo, forKey: LeapSharedInformationConstants.completedFlows)
        }
        
        self.unmuteDiscovery(discoveryId, isPreview: isPreview)
        
        var terminatedDiscoveries = getTerminatedDiscoveries(isPreview: isPreview)
        if terminatedDiscoveries.contains(discoveryId) { terminatedDiscoveries = terminatedDiscoveries.filter{ $0 != discoveryId} }
        if isPreview {
            terminatedDiscoveriesInPreview = terminatedDiscoveries
        } else {
            prefs.setValue(terminatedDiscoveries, forKey: LeapSharedInformationConstants.terminatedDiscoveries)
        }
        removeTerminationEventSent(discoveryId: discoveryId, assistId: nil,isPreview: isPreview)
    }
    
}

// MARK: - MUTE HANDLING
extension LeapSharedInformation {
    
    func isMuted(isPreview:Bool) -> Bool {
        return prefs.bool(forKey: LeapSharedInformationConstants.muted)
    }
    
    func muteLeap(isPreview:Bool) {
        prefs.setValue(true, forKeyPath: LeapSharedInformationConstants.muted)
        prefs.synchronize()
    }
    
    func unmuteLeap(isPreview:Bool) {
        prefs.setValue(false, forKey: LeapSharedInformationConstants.muted)
        prefs.synchronize()
    }
    
}

extension LeapSharedInformation {
    
    func terminationEventSent(discoveryId: Int?, assistId: Int?, isPreview:Bool) {
        if let discoveryId = discoveryId {
            var terminatedDiscoveries = getTerminatedDiscoveriesEvents(isPreview: isPreview)
            if !terminatedDiscoveries.contains(discoveryId) {
                terminatedDiscoveries.append(discoveryId)
                if isPreview {
                    discoveryTerminationSentInPreview = terminatedDiscoveries
                } else {
                    prefs.setValue(terminatedDiscoveries, forKey: LeapSharedInformationConstants.discoveryTerminationSent)
                }
                
            }
        } else if let assistId = assistId {
            var terminatedAssists = getTerminatedAssistsEvents(isPreview: isPreview)
            if !terminatedAssists.contains(assistId) {
                terminatedAssists.append(assistId)
                if isPreview {
                   assistTerminationSentInPreview = terminatedAssists
                } else {
                    prefs.setValue(terminatedAssists, forKey: LeapSharedInformationConstants.assistTerminationSent)
                }
            }
        }
    }
    
    func removeTerminationEventSent(discoveryId: Int?, assistId: Int?, isPreview:Bool) {
        if let discoveryId = discoveryId {
            var terminatedDiscoveries = getTerminatedDiscoveries(isPreview: isPreview)
            terminatedDiscoveries = terminatedDiscoveries.filter { $0 != discoveryId }
            if isPreview {
                discoveryTerminationSentInPreview = terminatedDiscoveries
            } else {
                prefs.setValue(terminatedDiscoveries, forKey: LeapSharedInformationConstants.discoveryTerminationSent)
            }
            
        } else if let assistId = assistId {
            var terminatedAssists = getTerminatedAssistsEvents(isPreview: isPreview)
            terminatedAssists = terminatedAssists.filter { $0 != assistId }
            if isPreview {
                assistTerminationSentInPreview = terminatedAssists
            } else {
                prefs.setValue(terminatedAssists, forKey: LeapSharedInformationConstants.assistTerminationSent)
            }
            
        }
    }
    
    func getTerminatedDiscoveriesEvents(isPreview:Bool) -> [Int] {
        return isPreview ? discoveryTerminationSentInPreview : prefs.object(forKey: LeapSharedInformationConstants.discoveryTerminationSent) as? Array<Int> ?? []
    }
    
    func getTerminatedAssistsEvents(isPreview:Bool) -> [Int] {
        return isPreview ? assistTerminationSentInPreview : prefs.object(forKey: LeapSharedInformationConstants.assistTerminationSent) as? Array<Int> ?? []
    }
}

extension LeapSharedInformation {
    func saveCompletedFlowInfo(_ flowId:Int, disId:Int, isPreview:Bool) {
        var completedFlows = getCompletedFlowInfo(isPreview: isPreview)
        var completedFlowsForDisId = completedFlows["\(disId)"] ?? []
        if !completedFlowsForDisId.contains(flowId) { completedFlowsForDisId.append(flowId) }
        completedFlows["\(disId)"] = completedFlowsForDisId
        guard !isPreview else {
            completedFlowsInPreview = completedFlows
            return
        }
        prefs.setValue(completedFlows, forKey: LeapSharedInformationConstants.completedFlows)
    }
    
    func getCompletedFlowInfo(isPreview:Bool) -> [String:[Int]] {
        return isPreview ? completedFlowsInPreview : prefs.object(forKey: LeapSharedInformationConstants.completedFlows) as? Dictionary<String,Array<Int>> ?? [:]
    }
}

extension LeapSharedInformation {
    func previewEnded() {
        assistsPresentedInPreviewSession = [:]
        assistsDismissedByUserInPreview = []
        discoveryPresentedInPreviewSession = [:]
        discoveryDismissedByUserInPreview = []
        discoveryFlowCompletedInPreview = [:]
        mutedDiscoveriesInPreview = []
        terminatedDiscoveriesInPreview = []
        completedFlowsInPreview = [:]
        discoveryTerminationSentInPreview = []
        assistTerminationSentInPreview = []
    }
}
