//
//  JinySharedInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

/// JinySharedInformation class is responsible for storing and retrieving data that can be accessed through JinySDK functionality. It  stores api key,  session id, language code and mute status of the SDK

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
    private var audioLanguageCode:String?
    private var mute:Bool = false
    private var audioDownloadStatus:Dictionary<String,Dictionary<String, JinyDownloadStatus>> = [:]
}


// MARK: - API KEY GETTER AND SETTER
extension JinySharedInformation {
    
    func setAPIKey(_ token:String) {
        guard apiKey == nil else { return }
        apiKey = token
    }
    
    func getAPIKey() -> String {
        return apiKey!
    }
    
}


// MARK: - AUDIO LANGUAGE CODE GETTER AND SETTER
extension JinySharedInformation {
    
    func setLanguage(_ language: String) {
        audioLanguageCode = language
        saveLanguageToPrefs(audioLanguageCode!)
    }
    
    func getLanguage() -> String? {
        guard audioLanguageCode != nil else { return getLanguageFromPref() }
        return audioLanguageCode
    }
    
    func saveLanguageToPrefs(_ code:String) {
        
        prefs.set(code, forKey: "audio_language_code")
        prefs.synchronize()
    }
    
    func getLanguageFromPref() -> String? {
        if let code = prefs.value(forKey: "audio_language_code") as? String { audioLanguageCode = code }
        return audioLanguageCode
    }
    
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

extension JinySharedInformation {
     
    func addToMutedDiscovery(_ discoveryId:Int) {
        var mutedDiscoveryList = prefs.array(forKey: "muted_discoveries") as? Array<Int> ?? []
        guard !mutedDiscoveryList.contains(discoveryId) else { return }
        mutedDiscoveryList.append(discoveryId)
        prefs.set(mutedDiscoveryList, forKey: "muted_discoveries")
        prefs.synchronize()
            
    }
    
    func removeFromMuteDiscovery(_ discoveryId:Int) {
        guard var mutedDiscoveryList = prefs.array(forKey: "muted_discoveries") as? Array<Int>, mutedDiscoveryList.contains(discoveryId) else { return }
        mutedDiscoveryList = mutedDiscoveryList.filter{ $0 != discoveryId }
        prefs.set(mutedDiscoveryList, forKey: "muted_discoveries")
        prefs.synchronize()
    }
    
    func getMutedDiscoveryIds() ->Array <Int> {
        return prefs.array(forKey: "muted_discoveries") as? Array<Int> ?? []
    }
    
    private func unmuteAllDiscoveries() {
        prefs.set([], forKey: "muted_discoveries")
        prefs.synchronize()
    }
    
}

extension JinySharedInformation {
    
    func isMuted() -> Bool {
        mute = checkForMuteInPref()
        return mute
    }
    
    func muteJiny() {
        mute = true
        setPrefMute()
    }
    
    func unmuteJiny() {
        mute = false
        setPrefMute()
        unmuteAllDiscoveries()
    }
    
    private func checkForMuteInPref() -> Bool {
        let muted = prefs.bool(forKey: "muted")
        return muted
        
    }
    
    private func setPrefMute() {
        prefs.set(mute, forKey: "muted")
        prefs.synchronize()
    }
    
}

extension JinySharedInformation {
    
    func discoveryPresented(discoveryId:Int) {
        if prefs.dictionary(forKey: "jiny_discovery_count") == nil {
            let discList:Dictionary<String,Int> = [:]
            prefs.set(discList, forKey: "jiny_discovery_count")
        }
        guard var discList = prefs.dictionary(forKey: "jiny_discovery_count") as? Dictionary<String,Int> else { return }
        if discList[String(discoveryId)] == nil {
            discList[String(discoveryId)] = 1
        } else {
            discList[String(discoveryId)] = discList[String(discoveryId)]! + 1
        }
        prefs.set(discList,forKey: "jiny_discovery_count")
        prefs.synchronize()
    }
    
    func getDiscoveryCount() -> Dictionary<String,Int> {
        return prefs.dictionary(forKey: "jiny_discovery_count") as? Dictionary<String,Int> ?? [:]
    }
    
    func discoveryDismissed(discoveryId:Int) {
        if prefs.dictionary(forKey: "jiny_discovery_dismiss_count") == nil {
            let discDismissList:Dictionary<String,Int> = [:]
            prefs.set(discDismissList, forKey: "jiny_discovery_dismiss_count")
        }
        guard var discDismissList = prefs.dictionary(forKey: "jiny_discovery_dismiss_count") as? Dictionary<String,Int> else { return }
        if discDismissList[String(discoveryId)] == nil { discDismissList[String(discoveryId)] = 1 }
        else { discDismissList[String(discoveryId)] = discDismissList[String(discoveryId)]! + 1 }
        prefs.set(discDismissList, forKey: "jiny_discovery_dismiss_count")
        prefs.synchronize()
    }
    
    func getDiscoveryDismissCount() -> Dictionary<String, Int> {
        return prefs.dictionary(forKey: "jiny_discovery_dismiss_count") as? Dictionary<String,Int> ?? [:]
    }
    
    func flowCompletedFor(discoveryId:Int) {
           if prefs.dictionary(forKey: "jiny_discovery_flow_count") == nil {
               let discDismissList:Dictionary<String,Int> = [:]
               prefs.set(discDismissList, forKey: "jiny_discovery_flow_count")
           }
           guard var discDismissList = prefs.dictionary(forKey: "jiny_discovery_flow_count") as? Dictionary<String,Int> else { return }
           if discDismissList[String(discoveryId)] == nil { discDismissList[String(discoveryId)] = 1 }
           else { discDismissList[String(discoveryId)] = discDismissList[String(discoveryId)]! + 1 }
           prefs.set(discDismissList, forKey: "jiny_discovery_flow_count")
           prefs.synchronize()
       }
       
       func getDiscoveryFlowCount() -> Dictionary<String, Int> {
           return prefs.dictionary(forKey: "jiny_discovery_flow_count") as? Dictionary<String,Int> ?? [:]
       }
    
}


// MARK: - AUDIO STATUS
extension JinySharedInformation {
    
    func getAudioStatusDict() -> Dictionary<String,Dictionary<String, JinyDownloadStatus>> { return audioDownloadStatus }
    
    func getAudioStatusForLangCode(_ code:String) -> Dictionary<String,JinyDownloadStatus>? { return audioDownloadStatus[code] }

    func getAudioStatusForLangCode(_ code:String, audioName:String) -> JinyDownloadStatus {
        guard let langDict = audioDownloadStatus[code] else { return .notDownloaded }
        guard let status = langDict[audioName] else { return .notDownloaded }
        return status
    }
    
    func setAudioStatus(for audioName:String, in langCode:String, to status:JinyDownloadStatus) {
        var langDict = audioDownloadStatus[langCode]
        if langDict == nil { audioDownloadStatus[langCode] = [audioName:status] }
        else {
            langDict![audioName] =  status
            audioDownloadStatus[langCode] = langDict
        }
    }
    
}
