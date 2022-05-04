//
//  LeapStarter.swift
//  LeapCore
//
//  Created by Aravind GS on 17/03/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

// MARK: - LEAPSTARTER CLASS
class LeapStarter: NSObject {
    
    private var contextManager: LeapContextManager
    
    private var fetchedProjectIds: Array<String> = []
    private var currentEmbeddedProjectId: String?
    
    private var configRepo: LeapConfigRepository?
    
    init(_ token : String, uiManager: LeapAUIHandler?) {
        self.contextManager = LeapContextManager(withUIHandler: uiManager)
        super.init()
        self.contextManager.delegate = self
        LeapSharedInformation.shared.setAPIKey(token)
        LeapSharedInformation.shared.setSessionId()
        configRepo = LeapConfigRepository(token: token)
        fetchConfigForDetection()
    }
    
    func auiCallback() -> LeapAUICallback? {
        return self.contextManager
    }
    
    func fetchConfigForDetection() {
        configRepo?.fetchConfig(completion: { [weak self] config in
            DispatchQueue.main.async {
                self?.startContextDetection(config: config)
            }
        })
    }
}

// Updated Config and Projects
extension LeapStarter {
    
    public func startProject(projectId: String, resetProject: Bool, isEmbedProject: Bool) {
        let projIds = projectId.components(separatedBy: "#")
        guard let mainProjId = projIds.first else { return }
        if isEmbedProject {
            contextManager.resetForProjectId(mainProjId)
            guard mainProjId != currentEmbeddedProjectId else { return }
        } else {
            if resetProject { contextManager.resetForProjectId(mainProjId) }
            else {
                guard !fetchedProjectIds.contains(mainProjId) else {
                    guard let savedProjectConfig = configRepo?.getSavedProjectConfigFor(projectId: mainProjId) else { return }
                    let projectConfig = LeapConfig(withDict: savedProjectConfig, isPreview: false)
                    contextManager.appendProjectConfig(withConfig: projectConfig, resetProject: resetProject)
                    return
                }
            }
        }
        if let currentEmbed = currentEmbeddedProjectId {
            contextManager.removeConfigFor(projectId: currentEmbed)
            currentEmbeddedProjectId = nil
        }
        startSubProject(projectId: projectId, resetProject: resetProject, isEmbedProject: isEmbedProject)
    }
    
    private func startSubProject(projectId: String, resetProject: Bool, isEmbedProject: Bool) {
        
        let projIds = projectId.components(separatedBy: "#")
        guard let mainProjId = projIds.first else { return }
        let subFlowId:String? = {
            guard projIds.count == 2 else { return  nil }
            return projIds[1]
        }()
        let isEmbeddedFlow = contextManager.isFlowEmbedFor(projectId: mainProjId)
        
        configRepo?.fetchConfig(projectId: mainProjId, completion: { config in
            DispatchQueue.main.async {
                if !isEmbedProject { self.fetchedProjectIds.append(mainProjId) }
                
                let projectConfig = LeapConfig(withDict: config, isPreview: false)
                if isEmbeddedFlow {
                    var projParams:LeapProjectParameters?
                    projectConfig.contextProjectParametersDict.forEach { key, parameters in
                        if key.hasPrefix("discovery_") && parameters.deploymentId == mainProjId {
                            projParams = parameters
                        }
                    }
                    if let projectParameters = projParams {
                        projectParameters.setEmbed(embed: true)
                        projectParameters.setEnabled(enabled: true)
                    }
                }
                self.contextManager.appendProjectConfig(withConfig: projectConfig, resetProject: resetProject)
                guard let subflowProjectId = subFlowId else { return }
                self.contextManager.startSubproj(mainProjId: mainProjId, subProjId: subflowProjectId)
            }
        })
    }
    
    private func appendProjectConfig() {
        self.currentEmbeddedProjectId = nil
        for projId in self.fetchedProjectIds {
            guard let projectConfigDict = self.configRepo?.getSavedProjectConfigFor(projectId: projId) else { break }
            let projectConfig  = LeapConfig(withDict: projectConfigDict, isPreview: false)
            self.contextManager.appendProjectConfig(withConfig: projectConfig, resetProject: false)
        }
    }
}

// MARK: - CONTEXT DETECTION METHODS
extension LeapStarter {
    private func startContextDetection(config: Dictionary<String, AnyHashable>) {
        DispatchQueue.main.async {
            let configuration = LeapConfig(withDict: config, isPreview: false)
            self.contextManager.initialize(withConfig: configuration)
        }
    }
}

extension LeapStarter: LeapContextManagerDelegate {
    
    func fetchUpdatedConfig(completion: @escaping(_ : LeapConfig?) -> Void) {
        configRepo?.fetchConfig(completion: { [weak self] updatedConfig in
            DispatchQueue.main.async {
                let updatedLeapConfig  = LeapConfig(withDict: updatedConfig, isPreview: false)
                completion(updatedLeapConfig)
                self?.appendProjectConfig()
            }
        })
    }
    
    func getCurrentEmbeddedProjectId() -> String? {
        return self.currentEmbeddedProjectId
    }
    
    func resetCurrentEmbeddedProjectId() {
        self.currentEmbeddedProjectId = nil
    }
}

// MARK: - LOCAL/REMOTE CONFIGURATION HANDLING
class LeapConfigRepository {
    
    private let remoteConfigHandler: LeapRemoteConfigHandler?
    
    init(token: String) {
        remoteConfigHandler = LeapRemoteConfigHandler(token: token)
    }
    
    private func setConfig(projectId: String? = nil, configDict: Dictionary<String, AnyHashable> = [:], response: URLResponse) {
        
        switch (response as? HTTPURLResponse)?.statusCode {
            
        case 404, 401:
            guard let projectId = projectId else {
                remoteConfigHandler?.resetSavedHeaders()
                self.resetSavedConfig()
                break
            }
            self.resetProjectConfigFor(projectId: projectId)
            
        case 200:
            guard let projectId = projectId else {
                self.saveConfig(config: configDict)
                fallthrough
            }
            self.saveProjectConfig(projectId: projectId, config: configDict)
            
        default:
            if projectId == nil {
                if let httpResponse = response as? HTTPURLResponse {
                    remoteConfigHandler?.saveHeaders(headers: httpResponse.allHeaderFields)
                }
            }
        }
    }
    
    private func getConfig(projectId: String? = nil) -> Dictionary<String, AnyHashable> {
        
        guard let projectId = projectId else {
            return self.getSavedConfig()
        }
        
        let savedProjectConfig = self.getSavedProjectConfigFor(projectId: projectId)
        return savedProjectConfig
    }
    
    func fetchConfig(projectId: String? = nil, completion: ((_ config: Dictionary<String, AnyHashable>) -> Void)? = nil) {
        
        remoteConfigHandler?.fetchConfig(projectId: projectId, completion: { [weak self] (result: Result<ResponseData, RequestError>?) in
            
            DispatchQueue.main.async {
                
                switch result {
                    
                case .success(let responseData):
                    
                    let configDict: Dictionary<String, AnyHashable> = {
                        let dict = try? JSONSerialization.jsonObject(with: responseData.data, options: .allowFragments) as? Dictionary<String, AnyHashable>
                        return dict ?? [:]
                    }()
                    
                    guard !configDict.isEmpty else { return }
                    
                    // make sure to set config before get config.
                    self?.setConfig(projectId: projectId, configDict: configDict, response: responseData.response)
                    guard let config = self?.getConfig() else { return }
                    completion?(config)
                    
                case .failure(let requestErrorResponse):
                    
                    var failureResponse: URLResponse?
                    
                    switch(requestErrorResponse) {
                        
                    case let .clientError(response): failureResponse = response
                        
                    case let .serverError(response): failureResponse = response
                        
                    case .noData: print("Failure")
                        
                        case .dataDecodingError: print("Failure") }
                    
                    guard let failureResponse = failureResponse else { return }
                    
                    // make sure to set config before get config.
                    self?.setConfig(projectId: projectId, response: failureResponse)
                    guard let config = self?.getConfig() else { return }
                    completion?(config)
                    
                    case .none: print("Failure") }
            }
        })
    }
    
    func saveConfig(config:Dictionary<String,AnyHashable>) {
        guard let configData = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted),
              let configString = String(data: configData, encoding: .utf8) else { return }
        let prefs = UserDefaults.standard
        prefs.setValue(configString, forKey: "leap_config")
    }
    
    func getSavedConfig() -> Dictionary<String,AnyHashable> {
        let prefs = UserDefaults.standard
        guard let configString = prefs.value(forKey: "leap_config") as? String,
              let configData = configString.data(using: .utf8),
              let config = try? JSONSerialization.jsonObject(with: configData, options: .allowFragments) as? Dictionary<String,AnyHashable> else { return [:] }
        return config
    }
    
    func resetSavedConfig() {
        let prefs = UserDefaults.standard
        prefs.setValue([:], forKey: "leap_config")
    }
    
    func saveProjectConfig(projectId:String, config:Dictionary<String,AnyHashable>) {
        let prefs = UserDefaults.standard
        var savedConfigs = getSavedProjectConfigs()
        savedConfigs[projectId] = config
        guard let newSavedConfigsData = try? JSONSerialization.data(withJSONObject: savedConfigs, options: .prettyPrinted),
              let newSavedConfigsString = String(data: newSavedConfigsData, encoding: .utf8) else { return }
        prefs.setValue(newSavedConfigsString, forKey: "leap_project_configs")
    }
    
    func getSavedProjectConfigFor(projectId:String) -> Dictionary<String,AnyHashable> {
        let savedProjectConfigs = getSavedProjectConfigs()
        return savedProjectConfigs[projectId] ?? [:]
    }
    
    func getSavedProjectConfigs() -> Dictionary<String,Dictionary<String,AnyHashable>> {
        let prefs = UserDefaults.standard
        guard let savedProjectConfigsString = prefs.value(forKey: "leap_project_configs") as? String,
              let savedConfigsData = savedProjectConfigsString.data(using: .utf8),
              let savedProjectConfigs = try? JSONSerialization.jsonObject(with: savedConfigsData, options: .allowFragments) as? Dictionary<String,Dictionary<String,AnyHashable>> else { return [:] }
        return savedProjectConfigs
    }
    
    func resetProjectConfigFor(projectId: String) {
        let prefs = UserDefaults.standard
        var savedProjectConfigs = getSavedProjectConfigs()
        savedProjectConfigs.removeValue(forKey: projectId)
        guard let newSavedConfigsData = try? JSONSerialization.data(withJSONObject: savedProjectConfigs, options: .prettyPrinted),
              let newSavedConfigsString = String(data: newSavedConfigsData, encoding: .utf8) else { return }
        prefs.setValue(newSavedConfigsString, forKey: "leap_project_configs")
    }
}
