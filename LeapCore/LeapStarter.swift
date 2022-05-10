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
    private weak var configRepoDelegate: LeapConfigRepositoryDelegate?
    
    init(_ token : String, uiManager: LeapAUIHandler?) {
        self.contextManager = LeapContextManager(withUIHandler: uiManager)
        super.init()
        self.contextManager.delegate = self
        LeapSharedInformation.shared.setAPIKey(token)
        LeapSharedInformation.shared.setSessionId()
        configRepo = LeapConfigRepository(token: token)
        configRepoDelegate = configRepo
        fetchConfigForDetection()
    }
    
    func auiCallback() -> LeapAUICallback? {
        return self.contextManager
    }
    
    func fetchConfigForDetection() {
        configRepoDelegate?.fetchConfig(projectId: nil, completion: { [weak self] config in
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
        
        configRepoDelegate?.fetchConfig(projectId: mainProjId, completion: { config in
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
        configRepoDelegate?.fetchConfig(projectId: nil, completion: { [weak self] updatedConfig in
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
