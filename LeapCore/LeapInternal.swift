//
//  LeapInternal.swift
//  LeapCore
//
//  Created by Aravind GS on 17/03/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

class LeapInternal:NSObject {
    var contextManager:LeapContextManager
    private let configUrl:String = {
        #if DEV
        return "https://odin-dev-gke.leap.is/odin/api/v1/config/fetch"
        #elseif STAGE
        return "https://odin-stage-gke.leap.is/odin/api/v1/config/fetch"
        #elseif PROD
        return "https://odin.leap.is/odin/api/v1/config/fetch"
        #else
        return "https://odin.leap.is/odin/api/v1/config/fetch"
        #endif
    }()
    var fetchedProjectIds:Array<String> = []
    var embeddedProjectIds:Array<String> = []
    var currentEmbeddedProjectId:String?
    
    init(_ token : String, uiManager:LeapAUIHandler?) {
        self.contextManager = LeapContextManager(withUIHandler: uiManager)
        super.init()
        self.contextManager.delegate = self
        resetSavedHeaders(for: token)
        LeapSharedInformation.shared.setAPIKey(token)
        LeapSharedInformation.shared.setSessionId()
        fetchConfig()
    }
    
    init(_ token:String, projectId:String, uiManager:LeapAUIHandler?, resetProject:Bool) {
        self.contextManager = LeapContextManager(withUIHandler: uiManager)
        super.init()
        self.contextManager.delegate = self
        resetSavedHeaders(for: token)
        LeapSharedInformation.shared.setAPIKey(token)
        LeapSharedInformation.shared.setSessionId()
        fetchProjectConfig(projectId: projectId, resetProject:resetProject)
    }
    
    
    
    func auiCallback() -> LeapAUICallback? {
        return self.contextManager
    }
    
}

// MARK: - CONFIGURATION DOWNLOAD AND HANDLING

extension LeapInternal {
    
    private func fetchConfig() {
        let payload = getPayload()
        let payloadData:Data = {
            guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed) else { return Data() }
            return payloadData
        }()
        guard let url = URL(string: configUrl) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.httpBody = payloadData
        getHeaders().forEach { req.addValue($0.value, forHTTPHeaderField: $0.key) }
        let configTask = URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode != 304,
                  let resultData = data,
                  let configDict = try?  JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,AnyHashable>  else {
                print("[Leap]Config fetched failed")
                if let httpUrlResponse = response as? HTTPURLResponse { self.saveHeaders(headers: httpUrlResponse.allHeaderFields) }
                let savedConfig = self.getSavedConfig()
                self.startContextDetection(config: savedConfig)
                return
            }
            print("[Leap]Config fetched successfully")
            self.saveHeaders(headers: httpResponse.allHeaderFields)
            self.saveConfig(config: configDict)
            self.startContextDetection(config: configDict)
        }
        configTask.resume()
    }
    
    public func fetchProjectConfig(projectId:String, resetProject:Bool) {
        //Make API call
        guard !fetchedProjectIds.contains(projectId) else {
            if resetProject { contextManager.resetForProjectId(projectId) }
            return
        }
        let payload = getPayload()
        let payloadData:Data = {
            guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed) else { return Data() }
            return payloadData
        }()
        guard let url = URL(string: configUrl) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.httpBody = payloadData
        getCommonHeaders().forEach { req.addValue($0.value, forHTTPHeaderField: $0.key) }

        req.addValue("[\"\(projectId)\"]", forHTTPHeaderField: "x-jiny-deployment-ids")
        let configTask = URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode != 304,
                  let resultData = data,
                  let configDict = try?  JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,AnyHashable>  else {
                print("[Leap]Project config fetched failed")
                if let httpUrlResponse = response as? HTTPURLResponse { self.saveHeaders(headers: httpUrlResponse.allHeaderFields) }
                let savedConfig = self.getSavedConfig()
                self.startContextDetection(config: savedConfig)
                return
            }
            DispatchQueue.main.async {
                print("[Leap]Project config fetched successfully")
                self.fetchedProjectIds.append(projectId)
                let projectConfig = LeapConfig(withDict: configDict, isPreview: false)
                self.contextManager.appendProjectConfig(withConfig: projectConfig, resetProject: resetProject)
            }
            
        }
        configTask.resume()
    }
    
    public func embedProject(_ projectId:String, resetProject:Bool) {
        if resetProject { contextManager.resetForProjectId(projectId) }
        if embeddedProjectIds.contains(projectId) {
            if embeddedProjectIds.last == projectId { return }
            embeddedProjectIds = embeddedProjectIds.filter { $0 != projectId }
        }
        let payload = getPayload()
        let payloadData:Data = {
            guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed) else { return Data() }
            return payloadData
        }()
        guard let url = URL(string: configUrl) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.httpBody = payloadData
        getCommonHeaders().forEach { req.addValue($0.value, forHTTPHeaderField: $0.key) }

        req.addValue("[\"\(projectId)\"]", forHTTPHeaderField: "x-jiny-deployment-ids")
        let configTask = URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode != 304,
                  let resultData = data,
                  let configDict = try?  JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,AnyHashable>  else {
                if let httpUrlResponse = response as? HTTPURLResponse { self.saveHeaders(headers: httpUrlResponse.allHeaderFields) }
                let savedConfig = self.getSavedConfig()
                self.startContextDetection(config: savedConfig)
                return
            }
            DispatchQueue.main.async {
                for prevProjId in self.embeddedProjectIds {
                    self.contextManager.removeConfigFor(projectId: prevProjId)
                }
                self.embeddedProjectIds.append(projectId)
                self.currentEmbeddedProjectId = projectId
                self.fetchedProjectIds.append(projectId)
                let projectConfig = LeapConfig(withDict: configDict, isPreview: false)
                self.contextManager.appendProjectConfig(withConfig: projectConfig, resetProject: resetProject)
            }
            
        }
        configTask.resume()
    }
    
    private func getHeaders() -> Dictionary<String,String> {
        guard let _ = LeapSharedInformation.shared.getAPIKey() else { return [:] }
        var headers = getCommonHeaders()
        getSavedHeaders().forEach { headers[$0.key] = $0.value }
        return headers
    }
    
    private func getCommonHeaders() -> Dictionary<String,String> {
        guard let apiKey = LeapSharedInformation.shared.getAPIKey(), let versionCode = LeapSharedInformation.shared.getVersionCode(), let versionName = LeapSharedInformation.shared.getVersionName() else { return [:] }
        let headers = [
            "x-jiny-client-id"      : apiKey,
            "x-app-version-code"    : versionCode,
            "x-app-version-name"    : versionName,
            "x-leap-id"             : LeapSharedInformation.shared.getLeapId(),
            "Content-Type"          : "application/json"
        ]
        return headers
    }
    
    private func getPayload() -> Dictionary<String,String> {
        
        let defaultStringProperties = LeapPropertiesHandler.shared.getDefaultStringProperties()
        let defaultLongProperties = LeapPropertiesHandler.shared.getDefaultLongProperties()
        let defaultIntProperties = LeapPropertiesHandler.shared.getDefaultIntProperties()
        
        let customLongProperties = LeapPropertiesHandler.shared.getCustomLongProperties()
        let customStringProperties = LeapPropertiesHandler.shared.getCustomStringProperties()
        let customIntProperties = LeapPropertiesHandler.shared.getCustomIntProperties()
        
        
        var payload:Dictionary<String,String> = customStringProperties
        defaultStringProperties.forEach { (key, value) in
            payload[key] = value
        }
        
        customIntProperties.forEach { (key,value) in
            payload[key] = "\(value)"
        }
        
        defaultIntProperties.forEach { (key, value) in
            payload[key] = "\(value)"
        }
        
        customLongProperties.forEach { (key,value) in
            let timeElapsed = Int64(Date(timeIntervalSince1970: TimeInterval(value)).timeIntervalSinceNow * -1)
            payload[key] = "\(timeElapsed)"
        }
        
        defaultLongProperties.forEach { (key, value) in
            let timeElapsed = Int64(Date(timeIntervalSince1970: TimeInterval(value)).timeIntervalSinceNow * -1)
            payload[key] = "\(timeElapsed)"
        }
        
        return payload
    }
    
    private func saveHeaders(headers:Dictionary<AnyHashable, Any>) {
        var toSaveHeaders:Dictionary<String,String> = [:]
        headers.forEach { (key,value) in
            if let headerField = key as? String, let valueField = value as? String {
                if headerField.starts(with: "x-jiny-") { toSaveHeaders[headerField] = valueField }
            }
        }
        let prefs = UserDefaults.standard
        prefs.set(toSaveHeaders, forKey: "leap_saved_headers")
    }
    
    private func getSavedHeaders() -> Dictionary<String,String> {
        let prefs = UserDefaults.standard
        let headers = prefs.object(forKey: "leap_saved_headers") as? Dictionary<String,String> ?? [:]
        return headers
    }
    
    private func resetSavedHeaders(for token: String) {
        if token != LeapSharedInformation.shared.getAPIKey() {
            let prefs = UserDefaults.standard
            prefs.setValue([:], forKey: "leap_saved_headers")
        }
    }
    
    private func saveConfig(config:Dictionary<String,AnyHashable>) {
        guard let configData = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted),
              let configString = String(data: configData, encoding: .utf8) else { return }
        let prefs = UserDefaults.standard
        prefs.setValue(configString, forKey: "leap_config")
    }
    
    private func getSavedConfig() -> Dictionary<String,AnyHashable> {
        let prefs = UserDefaults.standard
        guard let configString = prefs.value(forKey: "leap_config") as? String,
              let configData = configString.data(using: .utf8),
              let config = try? JSONSerialization.jsonObject(with: configData, options: .allowFragments) as? Dictionary<String,AnyHashable> else { return [:] }
        return config
    }
}

// MARK: - CONTEXT DETECTION METHODS
extension LeapInternal {
    private func startContextDetection(config:Dictionary<String,AnyHashable>) {
        DispatchQueue.main.async {
            let configuration = LeapConfig(withDict: config,isPreview: false)
            self.contextManager.initialize(withConfig: configuration)
        }
    }
}

extension LeapInternal: LeapContextManagerDelegate {
    
    
    func fetchUpdatedConfig(config:@escaping(_ :LeapConfig?)->Void) {
        let payload = getPayload()
        let payloadData:Data = {
            guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed) else { return Data() }
            return payloadData
        }()
        guard let url = URL(string: configUrl) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.httpBody = payloadData
        getHeaders().forEach { req.addValue($0.value, forHTTPHeaderField: $0.key) }
        let configTask = URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode != 304,
                  let resultData = data,
                  let configDict = try?  JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,AnyHashable>  else {
                if let httpUrlResponse = response as? HTTPURLResponse { self.saveHeaders(headers: httpUrlResponse.allHeaderFields) }
                let savedConfig = self.getSavedConfig()
                DispatchQueue.main.async { config(LeapConfig(withDict: savedConfig, isPreview: false)) }
                return
            }
            self.saveHeaders(headers: httpResponse.allHeaderFields)
            self.saveConfig(config: configDict)
            DispatchQueue.main.async { config(LeapConfig(withDict: configDict, isPreview: false)) }
            
        }
        configTask.resume()
    }
}
