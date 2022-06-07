//
//  LeapConfigManager.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 11/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation

protocol LeapConfigManagerDelegate: AnyObject {
    func resetForProjectId(_ projectId: String)
    func appendProjectConfig(withConfig: LeapConfig, resetProject: Bool)
    func startSubproj(mainProjId: String, subProjId: String)
}

class LeapConfigManager: NSObject {
    
    private var configRepo: LeapConfigRepository?
    private weak var configRepoDelegate: LeapConfigRepositoryDelegate?
    
    private var configuration: LeapConfig?
    private var previewConfig: LeapConfig?
    
    weak var delegate: LeapConfigManagerDelegate?
    
    private var projectManager: LeapProjectManager?
    
    init(with projectManager: LeapProjectManager, configRepo: LeapConfigRepository) {
        self.configRepo = configRepo
        self.configRepoDelegate = configRepo
        self.projectManager = projectManager
    }
    
    func currentConfiguration() -> LeapConfig? {
        if let preview = previewConfig { return preview }
        return configuration
    }
    
    func getConfig(projectId: String?, completion: ((_ config: LeapConfig) -> Void)?) {
        configRepoDelegate?.fetchConfig(projectId: projectId, completion: { [weak self] config in
            DispatchQueue.main.async {
                let configuration = LeapConfig(withDict: config, isPreview: false)
                self?.configuration = configuration
                completion?(configuration)
            }
        })
    }
    
    func startProject(projectId: String, resetProject: Bool, isEmbedProject: Bool) {
        let projIds = projectId.components(separatedBy: "#")
        guard let mainProjId = projIds.first else { return }
        if isEmbedProject {
            delegate?.resetForProjectId(mainProjId)
            guard mainProjId != projectManager?.getCurrentEmbeddedProjectId() else { return }
        } else {
            if resetProject { delegate?.resetForProjectId(mainProjId) }
            else {
                guard !(projectManager?.getFetchedProjectIds().contains(mainProjId) ?? false) else {
                    guard let savedProjectConfig = configRepo?.getSavedProjectConfigFor(projectId: mainProjId) else { return }
                    let projectConfig = LeapConfig(withDict: savedProjectConfig, isPreview: false)
                    self.appendNewProjectConfig(projectConfig: projectConfig, resetProject: resetProject)
                    return
                }
            }
        }
        if let currentEmbed = projectManager?.getCurrentEmbeddedProjectId() {
            self.removeConfigFor(projectId: currentEmbed)
            projectManager?.resetCurrentEmbeddedProjectId()
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
        let isEmbeddedFlow = isFlowEmbedFor(projectId: mainProjId)
        
        configRepoDelegate?.fetchConfig(projectId: mainProjId, completion: { config in
            DispatchQueue.main.async {
                if !isEmbedProject { self.projectManager?.appendProjectId(projectId: mainProjId) }
                
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
                self.appendNewProjectConfig(projectConfig: projectConfig, resetProject: resetProject)
                guard let subflowProjectId = subFlowId else { return }
                self.delegate?.startSubproj(mainProjId: mainProjId, subProjId: subflowProjectId)
            }
        })
    }
    
    func appendProjectConfig() {
        self.projectManager?.resetCurrentEmbeddedProjectId()
        for projId in (self.projectManager?.getFetchedProjectIds() ?? []) {
            guard let projectConfigDict = self.configRepo?.getSavedProjectConfigFor(projectId: projId) else { break }
            let projectConfig  = LeapConfig(withDict: projectConfigDict, isPreview: false)
            appendNewProjectConfig(projectConfig: projectConfig, resetProject: false)
        }
    }
    
    func setPreviewConfig(config: LeapConfig) {
        previewConfig = config
    }
    
    func resetPreviewConfig() {
        previewConfig = nil
    }
    
    func isPreview() -> Bool {
        guard let _ = self.previewConfig else { return false }
        return true
    }
    
    func isFlowEmbedFor(projectId:String) -> Bool {
        var projParams: LeapProjectParameters?
        self.currentConfiguration()?.contextProjectParametersDict.forEach({ key, params in
            if key.hasPrefix("discovery_") && params.deploymentId == projectId {
                projParams = params
            }
        })
        guard let projectParameters = projParams else { return false }
        return projectParameters.getIsEmbed()
    }
    
    func appendNewProjectConfig(projectConfig: LeapConfig, resetProject: Bool) {
        
        if currentConfiguration() == nil { configuration = LeapConfig(withDict: [:], isPreview: false) }
        
        if resetProject {
            for assist in projectConfig.assists {
                LeapSharedInformation.shared.resetAssist(assist.id, isPreview: self.isPreview())
            }
            for discovery in projectConfig.discoveries {
                LeapSharedInformation.shared.resetDiscovery(discovery.id, isPreview: self.isPreview())
            }
        }

        configuration?.projectParameters.append(contentsOf: projectConfig.projectParameters)
        
        projectConfig.nativeIdentifiers.forEach { (key, value) in
            configuration?.nativeIdentifiers[key] = value
        }
        
        projectConfig.webIdentifiers.forEach { (key, value) in
            configuration?.webIdentifiers[key] = value
        }
        
        if var currentAssists = configuration?.assists {
            currentAssists = currentAssists.filter { !projectConfig.assists.contains($0) }
            currentAssists.insert(contentsOf: projectConfig.assists, at: 0)
            configuration?.assists = currentAssists
        } else {
            configuration?.assists = projectConfig.assists
        }
        
        if var currentDiscoveries = configuration?.discoveries {
            currentDiscoveries = currentDiscoveries.filter { !projectConfig.discoveries.contains($0) }
            currentDiscoveries.insert(contentsOf: projectConfig.discoveries, at: 0)
            configuration?.discoveries = currentDiscoveries
        } else {
            configuration?.discoveries = projectConfig.discoveries
        }
        
        for flow in projectConfig.flows {
            if !(configuration?.flows.contains(flow))! { configuration?.flows.append(flow) }
        }
        
        configuration?.supportedAppLocales = Array(Set(configuration?.supportedAppLocales ?? [] + projectConfig.supportedAppLocales))
        configuration?.discoverySounds += projectConfig.discoverySounds
        configuration?.localeSounds += projectConfig.localeSounds
        configuration?.auiContent += projectConfig.auiContent
        projectConfig.iconSetting.forEach { (key, value) in
            configuration?.iconSetting[key] = value
        }
        configuration?.languages += projectConfig.languages.compactMap({ lang -> LeapLanguage? in
            guard let presentLanguages = configuration?.languages,
                  !presentLanguages.contains(lang) else { return nil }
            return lang
        })
        
        configuration?.contextProjectParametersDict.merge(projectConfig.contextProjectParametersDict, uniquingKeysWith: { _, newParams in
            newParams
        })
        
        configuration?.projectContextDict.merge(projectConfig.projectContextDict, uniquingKeysWith: { _, newContextId in
            newContextId
        })
        
        configuration?.connectedProjects += projectConfig.connectedProjects.compactMap({ tempProj -> Dictionary<String,String>? in
            guard let presentConnectedProjs = configuration?.connectedProjects else { return tempProj }
            if presentConnectedProjs.contains(tempProj) { return nil }
            return tempProj
        })
        
        self.delegate?.appendProjectConfig(withConfig: projectConfig, resetProject: resetProject)
    }
    
    func removeConfigFor(projectId: String) {
        let params: LeapProjectParameters?  = {
            var currentParams:LeapProjectParameters? = nil
            configuration?.contextProjectParametersDict.forEach({ key, params in
                if params.deploymentId == projectId { currentParams = params }
            })
            return currentParams
        }()
        guard let parameters = params,
              let projId = parameters.projectId,
              let config = self.currentConfiguration() else { return }
        config.projectContextDict.forEach({ projIdKey, contextId in
            if projIdKey == "assist_\(projId)"{
                config.assists = config.assists.filter{ $0.id != contextId }
                config.contextProjectParametersDict.removeValue(forKey: "assist_\(contextId)")
            } else if projIdKey == "discovery_\(projId)" {
                if parameters.getIsEmbed() {
                    parameters.setEnabled(enabled: false)
                } else {
                    config.discoveries = config.discoveries.filter{ $0.id != contextId}
                    config.contextProjectParametersDict.removeValue(forKey: "discovery_\(contextId)")
                }
                
            }
        })
    }
    
    func getFlowIdFor(projId: String) -> Int? {
        var flowId: Int? = nil
        self.currentConfiguration()?.contextProjectParametersDict.forEach({ key, projParams in
            if key.hasPrefix("flow_"), projParams.deploymentId == projId {
                flowId = Int(key.split(separator: "_")[1])
            }
        })
        return flowId
    }
    
    func isDiscoveryChecklist(discovery: LeapDiscovery) -> Bool {
        let params = self.currentConfiguration()?.contextProjectParametersDict["discovery_\(discovery.id)"]
        guard let parameters = params else { return false }
        let type = parameters.projectType ?? ""
        return type == constant_DYNAMIC_FLOW_CHECKLIST || type == constant_STATIC_FLOW_CHECKLIST
    }
    
    func getFlowMenuInfo(discovery: LeapDiscovery) -> Dictionary<String, Bool>? {
        guard isDiscoveryChecklist(discovery: discovery) else { return nil }
//        guard let currentDiscovery = discoveryManager?.getCurrentDiscovery() else { return nil }
        let completedFlowIds: Dictionary<String, Array<Int>> = LeapSharedInformation.shared.getCompletedFlowInfo(isPreview: self.isPreview())
        let completedFlowIdForCurrentDiscovery = completedFlowIds["\(discovery.id)"] ?? []
        let completedProjectIds:Array<String> = completedFlowIdForCurrentDiscovery.compactMap { flowId in
            return self.currentConfiguration()?.contextProjectParametersDict["flow_\(flowId)"]?.deploymentId
        }
        var flowInfo: Dictionary<String,Bool> = [:]
        completedProjectIds.forEach { projectId in
            flowInfo[projectId] = true
        }
        discovery.flowProjectIds?.forEach({ projectId in
            if flowInfo[projectId] == nil {
                flowInfo[projectId] = false
            }
        })
        return flowInfo
    }
    
    func getIconSettings(_ discoveryId: Int) -> Dictionary<String, AnyHashable> {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        guard let iconInfo = self.currentConfiguration()?.iconSetting[String(discoveryId)],
              let iconInfoData = try? jsonEncoder.encode(iconInfo),
              let iconInfoDict = try? JSONSerialization.jsonObject(with: iconInfoData, options: .allowFragments) as? Dictionary<String,AnyHashable> else { return [:] }
        return iconInfoDict
    }
    
    func generateLangDicts(localeCodes: Array<String>?) -> Array<Dictionary<String, String>>{
        guard let codes = localeCodes else { return [] }
        let langDicts = codes.map { (langCode) -> Dictionary<String, String>? in
            let tempLanguage = self.currentConfiguration()?.languages.first { $0.localeId == langCode }
            guard let language = tempLanguage else { return nil }
            return ["localeId":language.localeId, "localeName":language.name, "localeScript":language.script]
        }.compactMap { return $0 }
        return langDicts
    }
}

extension LeapConfigManager: LeapContextManagerDelegate {
    
    func fetchUpdatedConfig(completion: @escaping(_ : LeapConfig?) -> Void) {
        configRepoDelegate?.fetchConfig(projectId: nil, completion: { [weak self] updatedConfig in
            DispatchQueue.main.async {
                self?.configuration = LeapConfig(withDict: updatedConfig, isPreview: false)
                completion(self?.configuration)
                self?.appendProjectConfig()
            }
        })
    }
    
    func getCurrentEmbeddedProjectId() -> String? {
        return self.projectManager?.getCurrentEmbeddedProjectId()
    }
    
    func resetCurrentEmbeddedProjectId() {
        self.projectManager?.resetCurrentEmbeddedProjectId()
    }
}
