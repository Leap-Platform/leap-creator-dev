//
//  JinyInternal.swift
//  JinySDK
//
//  Created by Aravind GS on 17/03/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import AdSupport

class JinyInternal:NSObject {
    private var apikey:String
    var jinyConfiguration:JinyConfig?
    var contextManager:JinyContextManager
    
    init(_ token : String, uiManager:JinyAUIHandler?) {
        self.apikey = token
        self.contextManager = JinyContextManager(withUIHandler: uiManager)
        super.init()
        JinySharedInformation.shared.setAPIKey(apikey)
        JinySharedInformation.shared.setSessionId()
        addObservers()
        fetchConfig()
    }
    
    func auiCallback() -> JinyAUICallback? {
        return self.contextManager
    }
    
}


// MARK: - OBSERVER AND LISTENER METHODS

extension JinyInternal {
    
    private func addObservers() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(appLaunched), name: UIApplication.didFinishLaunchingNotification, object: nil)
        nc.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc private func appLaunched() {
        
    }
    
    @objc private func appWillEnterForeground() {
        
    }
    
    @objc private func appDidEnterBackground() {
        
    }
    
    @objc private func appWillTerminate() {
        
    }
}


// MARK: - FETCH CONFIGURATION AND AUDIO DOWNLOAD

extension JinyInternal {
    
    func fetchConfig() {
        let url = URL(string: "https://odin-dev-gke.jiny.io/odin/api/v3/config")
        var req = URLRequest(url: url!)
        req.httpMethod = "PUT"
        let dict:Dictionary<String,String> = [:]
        let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        req.httpBody = jsonData
//        let headers = getSavedHeaders()
//        headers.forEach { (key,value) in
//            req.addValue(value, forHTTPHeaderField: key)
//        }
//        req.addValue("6e0062e7-4c8a-41c9-b67e-0305dc2302cf", forHTTPHeaderField: "x-jiny-client-id")
        req.addValue("2c9fba13-57ad-4948-a359-5180180cc7b7", forHTTPHeaderField: "x-jiny-client-id")
        req.addValue("1", forHTTPHeaderField: "x-app-version-code")
        req.addValue("0.1.1", forHTTPHeaderField: "x-app-version-name")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let configTask = URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard let resultData = data else { return }
            guard let configDict = try?  JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,Any> else { return }
            self.jinyConfiguration = JinyConfig(withDict: configDict)
            if let httpResponse = response as? HTTPURLResponse {
                let headers = httpResponse.allHeaderFields
                self.saveHeaders(headers: headers)
            }
            self.setupDefaultLanguage()
            self.startContextDetection()
        }
        configTask.resume()
//        let url = URL(string: "http://dashboard.jiny.mockable.io/newIosData")
//        var req = URLRequest(url: url!)
//        req.addValue(ASIdentifierManager.shared().advertisingIdentifier.uuidString, forHTTPHeaderField: "identifier")
//        let session = URLSession.shared
//        let configTask = session.dataTask(with: req) { (data, response, error) in
//            guard let resultData = data else { return }
//            guard let configDict = try?  JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,Any> else { return }
//            self.jinyConfiguration = JinyConfig(withDict: configDict)
//            self.setupDefaultLanguage()
//            self.startContextDetection()
//        }
//        configTask.resume()
    }
    
    func saveHeaders(headers:Dictionary<AnyHashable, Any>) {
        var toSaveHeaders:Dictionary<String,String> = [:]
        headers.forEach { (key,value) in
            if let headerField = key as? String, let valueField = value as? String {
                if headerField.starts(with: "x-jiny-") { toSaveHeaders[headerField] = valueField }
            }
        }
        let prefs = UserDefaults.standard
        prefs.set(toSaveHeaders, forKey: "jiny_saved_headers")
        prefs.synchronize()
    }
    
    func getSavedHeaders() -> Dictionary<String,String> {
        let prefs = UserDefaults.standard
        let headers = prefs.object(forKey: "jiny_saved_headers") as? Dictionary<String,String> ?? [:]
        return headers
    }
    
    func setupDefaultLanguage() {
        guard let config = self.jinyConfiguration else { return }
        if let lang = JinySharedInformation.shared.getLanguage() {
            for language in config.languages { if lang == language.localeId { return } }
        }
        var newDefault:String?
        for lang in config.languages {
            if lang.localeId == "" { continue }
            newDefault = lang.localeId
            break
        }
        guard let defaultLang = newDefault else { return }
        JinySharedInformation.shared.setLanguage(defaultLang)
        
    }
}

// MARK: - CONTEXT DETECTION METHODS
extension JinyInternal {
    
    func startContextDetection() {
        guard let configuration = self.jinyConfiguration else { return }
        DispatchQueue.main.async {
            self.contextManager.initialize(withConfig: configuration)
        }
    }
}
