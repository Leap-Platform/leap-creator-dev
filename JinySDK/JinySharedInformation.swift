//
//  JinySharedInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

/// JinySharedInformation class is responsible for storing and retrieving data that can be accessed through JinySDK functionality. It  stores api key,  session id, language code and mute status of the SDK

struct JinySharedInformationConstants {
    static let assistsPresented = "jiny_assists_presented"
    static let assistsDismissedByUser = "jiny_assists_dismissed"
    static let discoveryPresented = "jiny_discovery_presented"
    static let discoveryDismissedByUser = "jiny_discovery_dismissed"
    static let discoveryFlowCompleted = "jiny_discovery_flow_completed"
    static let languageCode = "jiny_audio_language_code"
    static let muted = "jiny_muted"
}

enum JinyDownloadStatus {
    case notDownloaded
    case isDownloading
    case downloaded
}

class JinySharedInformation {
    static let shared = JinySharedInformation()
    private let prefs = UserDefaults.standard
    private var apiKey:String?
    private var sessionId:String?
}


// MARK: - API KEY GETTER AND SETTER
extension JinySharedInformation {
    
    func setAPIKey(_ token:String) {
        guard apiKey == nil else { fatalError("Token already set") }
        guard !token.isEmpty else { fatalError("Empty Token") }
        apiKey = token
    }
    
    func getAPIKey() -> String { return apiKey! }
    
}

// MARK: - SESSION ID GENERATOR, GETTER AND SETTER
extension JinySharedInformation {
    
    func getSessionId() -> String {
           if sessionId == nil { setSessionId() }
           return sessionId!
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


// MARK: - AUDIO LANGUAGE CODE GETTER AND SETTER
extension JinySharedInformation {
    
    func setLanguage(_ language: String) {
        prefs.setValue(language, forKey: JinySharedInformationConstants.languageCode)
        prefs.synchronize()
    }
    
    func getLanguage() -> String? {
        return prefs.value(forKey: JinySharedInformationConstants.languageCode) as? String
    }
}

// MARK: - ASSIST HANDLING
extension JinySharedInformation {
    
    func assistPresented(assistId:Int) {
        var assistsPresent = prefs.value(forKey: JinySharedInformationConstants.assistsPresented) as? Dictionary<String,Int> ?? [:]
        let currentAssistCount = assistsPresent[String(assistId)] ?? 0
        assistsPresent[String(assistId)] = currentAssistCount + 1
        prefs.setValue(assistsPresent, forKey: JinySharedInformationConstants.assistsPresented)
        prefs.synchronize()
    }
    
    func assistDismissedByUser(assistId:Int) {
        var assistsDismissed = prefs.value(forKey: JinySharedInformationConstants.assistsDismissedByUser) as? Array<Int> ?? []
        if !assistsDismissed.contains(assistId) { assistsDismissed.append(assistId) }
        prefs.setValue(assistsDismissed, forKey: JinySharedInformationConstants.assistsDismissedByUser)
        prefs.synchronize()
    }
    
    func getAssistsPresentedInfo() -> Dictionary<String, Int>{
        return (prefs.value(forKey: JinySharedInformationConstants.assistsPresented) as? Dictionary<String,Int>) ?? [:]
    }
    
    func getDismissedAssistInfo() -> Array<Int> {
        return (prefs.value(forKey: JinySharedInformationConstants.assistsDismissedByUser) as? Array<Int>) ?? []
    }
}

// MARK: - DISCOVERY HANDLING {
extension JinySharedInformation {
    
    func discoveryPresent(discoveryId:Int) {
        var discoveryPresent = prefs.value(forKey: JinySharedInformationConstants.discoveryPresented) as? Dictionary<String,Int> ?? [:]
        let currentDiscoveryCount = discoveryPresent[String(discoveryId)] ?? 0
        discoveryPresent[String(discoveryId)] = currentDiscoveryCount + 1
        prefs.setValue(discoveryPresent, forKey: JinySharedInformationConstants.discoveryPresented)
        prefs.synchronize()
    }
    
    func discoveryDismissedByUser(discoveryId:Int) {
        var discoveryDismissed = prefs.value(forKey: JinySharedInformationConstants.discoveryDismissedByUser) as? Array<Int> ?? []
        if !discoveryDismissed.contains(discoveryId) { discoveryDismissed.append(discoveryId) }
        prefs.setValue(discoveryDismissed, forKey: JinySharedInformationConstants.discoveryDismissedByUser)
        prefs.synchronize()
    }
    
    func discoveryFlowCompleted(discoveryId:Int) {
        var discoveryFlowCompleted = prefs.value(forKey: JinySharedInformationConstants.discoveryFlowCompleted) as? Dictionary<String,Int> ?? [:]
        let flowCount =  (discoveryFlowCompleted[String(discoveryId)] ?? 0) + 1
        discoveryFlowCompleted[String(discoveryId)] = flowCount
        prefs.setValue(discoveryFlowCompleted, forKey: JinySharedInformationConstants.discoveryFlowCompleted)
        prefs.synchronize()
    }
    
    func getDiscoveriesPresentedInfo() -> Dictionary<String,Int> {
        return (prefs.value(forKey: JinySharedInformationConstants.discoveryPresented) as? Dictionary<String,Int>) ?? [:]
    }
    
    func getDismissedDiscoveryInfo() -> Array<Int> {
        return (prefs.value(forKey: JinySharedInformationConstants.discoveryDismissedByUser) as? Array<Int>) ?? []
    }
    
    func getDiscoveryFlowCompletedInfo() -> Dictionary<String,Int> {
        return (prefs.value(forKey: JinySharedInformationConstants.discoveryFlowCompleted) as? Dictionary<String,Int>) ?? [:]
    }
    
}

// MARK: - MUTE HANDLING
extension JinySharedInformation {
    
    func isMuted() -> Bool {
        return prefs.bool(forKey: JinySharedInformationConstants.muted)
    }
    
    func muteJiny() {
        prefs.setValue(true, forKeyPath: JinySharedInformationConstants.muted)
        prefs.synchronize()
    }
    
    func unmuteJiny() {
        prefs.setValue(false, forKey: JinySharedInformationConstants.muted)
        prefs.synchronize()
    }
    
}
