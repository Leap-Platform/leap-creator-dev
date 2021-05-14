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
    static let assistsPresented = "leap_assists_presented"
    static let assistsDismissedByUser = "leap_assists_dismissed"
    static let discoveryPresented = "leap_discovery_presented"
    static let discoveryDismissedByUser = "leap_discovery_dismissed"
    static let discoveryFlowCompleted = "leap_discovery_flow_completed"
    static let terminatedDiscoveries = "leap_terminated_discoveries"
    static let mutedDiscoveries = "leap_muted_discoveries"
    static let muted = "leap_muted"
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
    
    func assistPresented(assistId:Int) {
        var assistsPresent = prefs.value(forKey: LeapSharedInformationConstants.assistsPresented) as? Dictionary<String,Int> ?? [:]
        let currentAssistCount = assistsPresent[String(assistId)] ?? 0
        assistsPresent[String(assistId)] = currentAssistCount + 1
        prefs.setValue(assistsPresent, forKey: LeapSharedInformationConstants.assistsPresented)
        prefs.synchronize()
    }
    
    func assistDismissedByUser(assistId:Int) {
        var assistsDismissed = prefs.value(forKey: LeapSharedInformationConstants.assistsDismissedByUser) as? Array<Int> ?? []
        if !assistsDismissed.contains(assistId) { assistsDismissed.append(assistId) }
        prefs.setValue(assistsDismissed, forKey: LeapSharedInformationConstants.assistsDismissedByUser)
        prefs.synchronize()
    }
    
    func getAssistsPresentedInfo() -> Dictionary<String, Int>{
        return (prefs.value(forKey: LeapSharedInformationConstants.assistsPresented) as? Dictionary<String,Int>) ?? [:]
    }
    
    func getDismissedAssistInfo() -> Array<Int> {
        return (prefs.value(forKey: LeapSharedInformationConstants.assistsDismissedByUser) as? Array<Int>) ?? []
    }
}

// MARK: - DISCOVERY HANDLING {
extension LeapSharedInformation {
    
    func discoveryPresent(discoveryId:Int) {
        var discoveryPresent = prefs.value(forKey: LeapSharedInformationConstants.discoveryPresented) as? Dictionary<String,Int> ?? [:]
        let currentDiscoveryCount = discoveryPresent[String(discoveryId)] ?? 0
        discoveryPresent[String(discoveryId)] = currentDiscoveryCount + 1
        prefs.setValue(discoveryPresent, forKey: LeapSharedInformationConstants.discoveryPresented)
        prefs.synchronize()
    }
    
    func discoveryDismissedByUser(discoveryId:Int) {
        var discoveryDismissed = prefs.value(forKey: LeapSharedInformationConstants.discoveryDismissedByUser) as? Array<Int> ?? []
        if !discoveryDismissed.contains(discoveryId) { discoveryDismissed.append(discoveryId) }
        prefs.setValue(discoveryDismissed, forKey: LeapSharedInformationConstants.discoveryDismissedByUser)
        prefs.synchronize()
    }
    
    func discoveryFlowCompleted(discoveryId:Int) {
        var discoveryFlowCompleted = prefs.value(forKey: LeapSharedInformationConstants.discoveryFlowCompleted) as? Dictionary<String,Int> ?? [:]
        let flowCount =  (discoveryFlowCompleted[String(discoveryId)] ?? 0) + 1
        discoveryFlowCompleted[String(discoveryId)] = flowCount
        prefs.setValue(discoveryFlowCompleted, forKey: LeapSharedInformationConstants.discoveryFlowCompleted)
        prefs.synchronize()
    }
    
    func muteDisovery(_ id:Int) {
        var mutedDiscoveries = prefs.array(forKey: LeapSharedInformationConstants.mutedDiscoveries) as? Array<Int> ?? []
        if !mutedDiscoveries.contains(id) { mutedDiscoveries.append(id) }
        prefs.setValue(mutedDiscoveries, forKey: LeapSharedInformationConstants.mutedDiscoveries)
        prefs.synchronize()
    }
    
    func unmuteDiscovery(_ id:Int) {
        var mutedDiscoveries = prefs.array(forKey: LeapSharedInformationConstants.mutedDiscoveries) as? Array<Int> ?? []
        mutedDiscoveries = mutedDiscoveries.filter{ $0 != id }
        prefs.setValue(mutedDiscoveries, forKey: LeapSharedInformationConstants.mutedDiscoveries)
        prefs.synchronize()
    }
    
    func terminateDiscovery(_ id:Int) {
        var terminatedDiscoveries = prefs.array(forKey: LeapSharedInformationConstants.terminatedDiscoveries) as? Array<Int> ?? []
        if !terminatedDiscoveries.contains(id) { terminatedDiscoveries.append(id) }
        prefs.setValue(terminatedDiscoveries, forKey: LeapSharedInformationConstants.terminatedDiscoveries)
        prefs.synchronize()
    }
    
    func getMutedDiscoveries() -> Array<Int> {
        return prefs.array(forKey: LeapSharedInformationConstants.mutedDiscoveries) as? Array <Int> ?? []
    }
    
    func getDiscoveriesPresentedInfo() -> Dictionary<String,Int> {
        return (prefs.value(forKey: LeapSharedInformationConstants.discoveryPresented) as? Dictionary<String,Int>) ?? [:]
    }
    
    func getDismissedDiscoveryInfo() -> Array<Int> {
        return (prefs.value(forKey: LeapSharedInformationConstants.discoveryDismissedByUser) as? Array<Int>) ?? []
    }
    
    func getDiscoveryFlowCompletedInfo() -> Dictionary<String,Int> {
        return (prefs.value(forKey: LeapSharedInformationConstants.discoveryFlowCompleted) as? Dictionary<String,Int>) ?? [:]
    }
    
    func getTerminatedDiscoveries() -> Array<Int> {
        return (prefs.value(forKey: LeapSharedInformationConstants.terminatedDiscoveries) as? Array<Int>) ?? []
    }
    
    
}

// MARK: - MUTE HANDLING
extension LeapSharedInformation {
    
    func isMuted() -> Bool {
        return prefs.bool(forKey: LeapSharedInformationConstants.muted)
    }
    
    func muteLeap() {
        prefs.setValue(true, forKeyPath: LeapSharedInformationConstants.muted)
        prefs.synchronize()
    }
    
    func unmuteLeap() {
        prefs.setValue(false, forKey: LeapSharedInformationConstants.muted)
        prefs.synchronize()
    }
    
}
