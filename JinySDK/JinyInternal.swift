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
//        return self.contextManager
        return nil
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
        let url = URL(string: "http://dashboard.jiny.mockable.io/newIosData")
        var req = URLRequest(url: url!)
        req.addValue(ASIdentifierManager.shared().advertisingIdentifier.uuidString, forHTTPHeaderField: "identifier")
        let session = URLSession.shared
        let configTask = session.dataTask(with: req) { (data, response, error) in
            guard let resultData = data else { return }
            guard let configDict = try?  JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,Any> else { return }
            self.jinyConfiguration = JinyConfig(withDict: configDict)
            self.setupDefaultLanguage()
            self.startContextDetection()
        }
        configTask.resume()
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
