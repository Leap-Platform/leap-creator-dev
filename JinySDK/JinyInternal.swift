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
    var contextManager:JinyContextManager
    
    init(_ token : String, uiManager:JinyAUIHandler?) {
        self.contextManager = JinyContextManager(withUIHandler: uiManager)
        super.init()
        JinySharedInformation.shared.setAPIKey(token)
        JinySharedInformation.shared.setSessionId()
        fetchConfig()
    }
    
    func auiCallback() -> JinyAUICallback? {
        return self.contextManager
    }
    
}

// MARK: - CONFIGURATION DOWNLOAD AND HANDLING

extension JinyInternal {
    
    private func fetchConfig() {
        let url = URL(string: "https://odin-dev-gke.leap.is/odin/api/v1/config/fetch")
        var req = URLRequest(url: url!)
        req.httpMethod = "PUT"
        let dict:Dictionary<String,String> = [:]
        let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        req.httpBody = jsonData
        getHeaders().forEach { req.addValue($0.value, forHTTPHeaderField: $0.key) }
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
            self.saveHeaders(headers: httpResponse.allHeaderFields)
            self.saveConfig(config: configDict)
            self.startContextDetection(config: configDict)
        }
        configTask.resume()
    }
    
    private func getHeaders() -> Dictionary<String,String> {
        var headers = [
            "x-jiny-client-id"      : JinySharedInformation.shared.getAPIKey(),
            "x-app-version-code"    : JinySharedInformation.shared.getVersionCode(),
            "x-app-version-name"    : JinySharedInformation.shared.getVersionName(),
            "Content-Type"          : "application/json"
        ]
        getSavedHeaders().forEach { headers[$0.key] = $0.value }
        return headers
    }
    
    private func saveHeaders(headers:Dictionary<AnyHashable, Any>) {
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
    
    private func getSavedHeaders() -> Dictionary<String,String> {
        let prefs = UserDefaults.standard
        let headers = prefs.object(forKey: "jiny_saved_headers") as? Dictionary<String,String> ?? [:]
        return headers
    }
    
    private func saveConfig(config:Dictionary<String,AnyHashable>) {
        guard let configData = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted),
              let configString = String(data: configData, encoding: .utf8) else { return }
        let prefs = UserDefaults.standard
        prefs.setValue(configString, forKey: "jiny_config")
        prefs.synchronize()
    }
    
    private func getSavedConfig() -> Dictionary<String,AnyHashable> {
        let prefs = UserDefaults.standard
        guard let configString = prefs.value(forKey: "jiny_config") as? String,
              let configData = configString.data(using: .utf8),
              let config = try? JSONSerialization.jsonObject(with: configData, options: .allowFragments) as? Dictionary<String,AnyHashable> else { return [:] }
        return config
    }
}

// MARK: - CONTEXT DETECTION METHODS
extension JinyInternal {
    private func startContextDetection(config:Dictionary<String,AnyHashable>) {
        DispatchQueue.main.async {
            let configuration = JinyConfig(withDict: config)
            self.contextManager.initialize(withConfig: configuration)
        }
    }
}
