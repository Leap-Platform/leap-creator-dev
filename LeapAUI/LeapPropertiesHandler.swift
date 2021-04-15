//
//  LeapPropertiesHandler.swift
//  LeapAUISDK
//
//  Created by Aravind GS on 05/04/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

class LeapPropertiesHandler {
    
    static let shared = LeapPropertiesHandler()
    let prefs = UserDefaults.standard
    let customLongPropertiesKey = "leap_custom_long_properties"
    let customStringPropertiesKey = "leap_custom_string_properties"
    let customIntPropertiesKey = "leap_custom_int_properties"
    
    let defaultLongPropertiesKey = "leap_default_long_properties"
    let defaultStringPropertiesKey = "leap_default_string_properties"
    let defaultIntPropetiesKey = "leap_default_int_properties"
    
    let leapSessionStartKey = "leap_last_session_start"
    let leapSessionEndKey = "leap_last_session_end"
    let leapCurrentSessionKey = "leap_current_session_start"
    let leapVersionKey = "leap_last_session_version"
    private var startTime: Int64 = 0
    private var endTime: Int64 = 0
    private var totalTime: Int64 = 0
    
    func start() {
        let sessionStart = Int64(Date().timeIntervalSince1970)
        prefs.setValue(sessionStart, forKey: leapCurrentSessionKey)
        prefs.synchronize()
        addObservers()
        setDefaultLongProperties()
        setDefaultIntProperties()
        setDefaultStringProperties()
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishLaunching(_:)), name: UIApplication.didFinishLaunchingNotification, object: nil)
    }
    
    @objc func didFinishLaunching(_ notification: NSNotification) {
        if let totalTimeSpentOnApp = prefs.value(forKey: constant_totalTimeSpentOnApp) as? Int64 {
            totalTime = totalTimeSpentOnApp
        }
    }
    
    @objc func didBecomeActive(_ notification: NSNotification) {
        startTime = Int64(Date().timeIntervalSince1970)
    }
    
    @objc func willResignActive(_ notification: NSNotification) {
        endTime = Int64(Date().timeIntervalSince1970)
        totalTime = totalTime + (endTime - startTime)
        DispatchQueue.main.async {
        // save total time spent on app
            self.prefs.setValue(self.totalTime, forKey: constant_totalTimeSpentOnApp)
        // replace session start time and session end time
            let sessionStartTime = self.prefs.value(forKey: self.leapCurrentSessionKey) as? Int64
        let sessionEndTime = Int64(Date().timeIntervalSince1970)
        // save session start time
            self.prefs.setValue(sessionStartTime, forKey: self.leapSessionStartKey)
        // save session end time
            self.prefs.setValue(sessionEndTime, forKey: self.leapSessionEndKey)
            print("Total time spent on the app is \(self.totalTime) seconds")
        }
    }
    
    func setDefaultLongProperties() {
        let firstInstalled = getInstalledDate()
        let firstSession = getFirstSession()
        let lastSession = getLastSession() ?? Int64(Date().timeIntervalSince1970)
        let lastUpdated = getLastUpdated()
        let longProperties:Dictionary<String,Int64> = [
            "timeElapsedSinceFirstInstall"  : firstInstalled,
            "timeElapsedSinceFirstSession"  : firstSession,
            "timeElapsedSinceLastSession"   : lastSession,
            "timeElapsedSinceLastUpdate"    : lastUpdated
        ]
        prefs.set(longProperties, forKey: defaultLongPropertiesKey)
        prefs.synchronize()
    }
    
    func setDefaultIntProperties() {
        let sessionCount = getSessionCount()
        let totalDuration = getTotalDuration()
        let intProperties: Dictionary<String, Int> = [
            "sessionCount"          : sessionCount,
            constant_totalTimeSpentOnApp   : totalDuration
        ]
        prefs.setValue(intProperties, forKey: defaultIntPropetiesKey)
        prefs.synchronize()
    }
    
    func setDefaultStringProperties() {
        let deviceLanguage = Locale.preferredLanguages.first ?? "en"
        let stringProperties = [
            "deviceLanguage":deviceLanguage
        ]
        prefs.setValue(stringProperties, forKey: defaultStringPropertiesKey)
        prefs.synchronize()
        
    }
    
    func saveCustomLongProperty(_ key: String, _ value: Int64) {
        var customLongProperties = getCustomLongProperties()
        customLongProperties[key] = value
        prefs.setValue(customLongProperties, forKey: customLongPropertiesKey)
        prefs.synchronize()
    }
    
    func saveCustomIntProperty(_ key:String, _ value:Int) {
        var customIntProperties = getCustomIntProperties()
        customIntProperties[key] = value
        prefs.setValue(customIntProperties, forKey: customIntPropertiesKey)
        prefs.synchronize()
    }
    
    func saveCustomStringProperty(_ key:String, _ value: String) {
        var customStringProperties = getCustomStringProperties()
        customStringProperties[key] = value
        prefs.setValue(customStringProperties, forKey: customStringPropertiesKey)
        prefs.synchronize()
    }
    
    func getDefaultLongProperties() -> Dictionary<String, Int64> {
        return prefs.value(forKey: defaultLongPropertiesKey) as? Dictionary<String,Int64> ?? [:]
    }
    
    func getDefaultIntProperties() -> Dictionary<String, Int> {
        return prefs.value(forKey: defaultIntPropetiesKey) as? Dictionary<String,Int> ?? [:]
    }
    
    func getDefaultStringProperties() -> Dictionary<String, String> {
        return prefs.value(forKey: defaultStringPropertiesKey) as? Dictionary<String,String> ?? [:]
    }
    
    func getCustomLongProperties() -> Dictionary<String, Int64> {
        return prefs.value(forKey: customLongPropertiesKey) as? Dictionary<String,Int64> ?? [:]
    }
    
    func getCustomIntProperties() -> Dictionary<String, Int> {
        return prefs.value(forKey: customIntPropertiesKey) as? Dictionary<String,Int> ?? [:]
    }
    
    func getCustomStringProperties() -> Dictionary<String, String> {
        return prefs.value(forKey: customStringPropertiesKey) as? Dictionary<String,String> ?? [:]
    }
    
    private func getStoredFirstInstallDate () -> Int64? {
        let defaultLongProps = getDefaultLongProperties()
        return defaultLongProps["timeElapsedSinceFirstInstall"]
    }
    
    private func getInstalledDate() -> Int64 {
        let firstInstallDate:Int64 = {
            let storedValue = getStoredFirstInstallDate()
            guard let value = storedValue else {
                if let urlToDocumentsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last,
                   let installDateAny = (try? FileManager.default.attributesOfItem(atPath: urlToDocumentsFolder.path)[.creationDate]),
                   let installDate = installDateAny as? Date { return Int64(installDate.timeIntervalSince1970) }
                else { return Int64(Date().timeIntervalSince1970) }
            }
            return value
        }()
        return firstInstallDate
    }
    
    
    private func getFirstSession() -> Int64 {
        return {
            let defaultLongProps = getDefaultLongProperties()
            guard let firstSessionStored = defaultLongProps["timeElapsedSinceFirstSession"] else {
                return Int64(Date().timeIntervalSince1970)
            }
            return firstSessionStored
        }()
    }
    
    private func getLastSession() -> Int64? {
        return prefs.value(forKey: leapSessionEndKey) as? Int64
    }
    
    private func getSessionCount() -> Int {
        let defaultIntProps = getDefaultIntProperties()
        return (defaultIntProps["sessionCount"] ?? 0) + 1
    }

    private func getTotalDuration() -> Int {
        return Int(prefs.value(forKey: constant_totalTimeSpentOnApp) as? Int64 ?? 0)
    }
    
    private func getLastUpdated() -> Int64 {
        let defaultLongProps = getDefaultLongProperties()
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        if let lastSessionVersion = prefs.string(forKey: leapVersionKey),
           lastSessionVersion == currentVersion {
            return defaultLongProps["timeElapsedSinceLastUpdate"] ?? Int64(Date().timeIntervalSince1970)
        }
        prefs.setValue(currentVersion, forKey: leapVersionKey)
        prefs.synchronize()
        return Int64(Date().timeIntervalSince1970)
    }
    
}
