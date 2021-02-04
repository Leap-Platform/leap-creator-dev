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
        fetchConfig()
    }
    
    func auiCallback() -> JinyAUICallback? {
        return self.contextManager
    }
    
}

// MARK: - CONFIGURATION DOWNLOAD AND HANDLING

extension JinyInternal {
    
    func fetchConfig() {
        let url = URL(string: "https://odin-dev-gke.jiny.io/odin/api/v3/config")
        var req = URLRequest(url: url!)
        req.httpMethod = "PUT"
        let dict:Dictionary<String,String> = [:]
        let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        req.httpBody = jsonData
        getHeaders().forEach { req.addValue($0.value, forHTTPHeaderField: $0.key) }
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
    
    func getHeaders() -> Dictionary<String,String> {
        var headers = [
            "x-jiny-client-id"      : JinySharedInformation.shared.getAPIKey(),
            "x-app-version-code"    : JinySharedInformation.shared.getVersionCode(),
            "x-app-version-name"    : JinySharedInformation.shared.getVersionName(),
            "Content-Type"          : "application/json"
        ]
        getSavedHeaders().forEach { headers[$0.key] = $0.value }
        return headers
    }
    
    func getSavedHeaders() -> Dictionary<String,String> {
        let prefs = UserDefaults.standard
        let headers = prefs.object(forKey: "jiny_saved_headers") as? Dictionary<String,String> ?? [:]
        return headers
    }
    
    func setupDefaultLanguage() {
        guard let config = self.jinyConfiguration else { return }
        if let currentLocaleId = JinySharedInformation.shared.getLanguage() {
            let currentDefaultLanguage = config.languages.first { (tempLanguage) -> Bool in
                return tempLanguage.localeId == currentLocaleId
            }
            if currentDefaultLanguage != nil { return }
        }
        let newDefaultLanguage = config.languages.first { (languageToCheck) -> Bool in
            return !languageToCheck.localeId.isEmpty
        }
        guard let defaultLanguage = newDefaultLanguage else { return }
        JinySharedInformation.shared.setLanguage(defaultLanguage.localeId, byUser:false)
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
