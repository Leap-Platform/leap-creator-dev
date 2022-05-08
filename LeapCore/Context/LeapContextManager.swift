//
//  LeapContextManager.swift
//  LeapCore
//
//  Created by Aravind GS on 06/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

protocol LeapContextManagerDelegate:NSObjectProtocol {
    func fetchUpdatedConfig(completion: @escaping(_ :LeapConfig?)->Void)
    func getCurrentEmbeddedProjectId() -> String?
    func resetCurrentEmbeddedProjectId()
}

/// LeapContextManager class acts as the central hub of the Core SDK once the config is downloaded. It invokes the LeapContextDetector class which helps in identifying the current flow, page and stage to be executed. LeapContextManager acts as the delegate to LeapContextDetector receiving information about flow, page and stage and passing it to LeapFlowManager & LeapStageManager.  LeapContextManager also acts as delegate to LeapStageManager, there by understanding if a new stage is identified or the same stage is identified and invoking the AUI SDK . LeapContextManger is also responsible for communicating with LeapAnalyticsManager
class LeapContextManager:NSObject {
    
    private var contextDetector:LeapContextDetector?
    private var assistManager:LeapAssistManager?
    private var discoveryManager:LeapDiscoveryManager?
    private var flowManager:LeapFlowManager?
    private var pageManager:LeapPageManager?
    private var stageManager:LeapStageManager?
    private var analyticsManager:LeapAnalyticsManager?
    private weak var analyticsDelegate: LeapAnalyticsDelegate?
    private var configuration:LeapConfig?
    private var previewConfig: LeapConfig?
    private weak var auiHandler:LeapAUIHandler?
    public weak var delegate:LeapContextManagerDelegate?
    private var taggedEvents:Dictionary<String,Any> = [:]
    private var lastEventId: String?
    private var lastEventLanguage: String?
    
    init(withUIHandler uiHandler:LeapAUIHandler?) {
        auiHandler = uiHandler
    }
    
    /// Methods to setup all managers and setting up their delegates to be this class. After setting up all managers, it calls the start method and starts the context detection
    func initialize(withConfig: LeapConfig) {
            configuration = withConfig
            contextDetector = LeapContextDetector(withDelegate: self)
            analyticsManager = LeapAnalyticsManager(self)
            analyticsDelegate = analyticsManager
            assistManager = LeapAssistManager(self)
            discoveryManager = LeapDiscoveryManager(self)
            flowManager = LeapFlowManager(self)
            pageManager = LeapPageManager(self)
            stageManager = LeapStageManager(self)
            self.start()
            print("[Leap]Context Detection started")
    }
    
    func appendProjectConfig(withConfig:LeapConfig, resetProject:Bool) {
        if configuration == nil { configuration = LeapConfig(withDict: [:], isPreview: false) }
        if resetProject {
            for assist in withConfig.assists {
                LeapSharedInformation.shared.resetAssist(assist.id, isPreview: self.isPreview())
            }
            for discovery in withConfig.discoveries {
                LeapSharedInformation.shared.resetDiscovery(discovery.id, isPreview: isPreview())
            }
        }
        let isTerminated:Bool = isNewConfigTerminated(newConfig: withConfig)
        if !isTerminated {
            auiHandler?.removeAllViews()
            assistManager?.resetAssistManager()
            discoveryManager?.resetDiscoveryManager()
            flowManager?.resetFlowsArray()
            pageManager?.resetPageManager()
            stageManager?.resetStageManager()
            if let state = contextDetector?.getState() {
                switch state {
                case .Stage: contextDetector?.switchState()
                default: break
                }
            }
        }
        appendNewProjectConfig(projectConfig: withConfig)
    }
    
    private func appendNewProjectConfig(projectConfig:LeapConfig) {
        
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
        
        startSoundDownload()
    }
    
    private func isNewConfigTerminated(newConfig:LeapConfig) -> Bool {
        let discoveries = newConfig.discoveries
        if discoveries.count > 0 {
            let terminatedDiscoveries = LeapSharedInformation.shared.getTerminatedDiscoveries(isPreview: false)
            if discoveries.count == 1 {
                let discovery = discoveries[0]
                return terminatedDiscoveries.contains(discovery.id)
            } else {
                let fmDisc = discoveries.first { discovery in
                    guard let projParams = newConfig.contextProjectParametersDict["discovery_\(discovery.id)"], let type = projParams.projectType else { return false }
                    return type == constant_STATIC_FLOW_CHECKLIST || type == constant_DYNAMIC_FLOW_CHECKLIST || type == constant_STATIC_FLOW_MENU || type == constant_DYNAMIC_FLOW_MENU
                }
                guard let flowMenuDisc = fmDisc else { return false }
                return terminatedDiscoveries.contains(flowMenuDisc.id)
                
            }
        }
        return false
    }
    
    private func getFlowMenuDisc(discoveries:Array<LeapDiscovery>) -> LeapDiscovery? {
        return nil
    }
    
    func resetForProjectId(_ projectId:String) {
        let params = configuration?.projectParameters.first { $0.deploymentId == projectId }
        guard let projParams = params, let id = projParams.id else { return }
        LeapSharedInformation.shared.resetAssist(id, isPreview: isPreview())
        assistManager?.removeAssistFromCompletedInSession(assistId: id)
        LeapSharedInformation.shared.resetDiscovery(id, isPreview: isPreview())
        discoveryManager?.removeDiscoveryFromCompletedInSession(disId: id)
    }
    
    /// Sets all triggers in trigger manager and starts context detection. By default context detection is in Discovery mode, hence checks all the relevant triggers first to start discovery
    func start() {
        startSoundDownload()
        contextDetector?.start()
        NotificationCenter.default.addObserver(self, selector: #selector(authLiveNotification(_:)), name: .init("leap_creator_live"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(previewNotification(_:)), name: .init("leap_preview_config"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(endPreview), name: .init("leap_end_preview"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appGoesToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appResumes), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func appGoesToBackground() {
        contextDetector?.stop()
        assistManager?.resetCurrentAssist()
        discoveryManager?.resetDiscovery()
        pageManager?.resetPageManager()
        stageManager?.resetCurrentStage()
        auiHandler?.appGoesToBackground()
    }
    
    @objc func appResumes() {
        contextDetector?.start()
    }
    
    func startSubproj(mainProjId:String, subProjId:String) {
        var mainId:String?
        var mainParams:LeapProjectParameters?
        
        var subId:String?
        var subParams:LeapProjectParameters?
        
        configuration?.contextProjectParametersDict.forEach({ key, parameters in
            if key.hasPrefix("discovery_") && parameters.deploymentId == mainProjId {
                mainId = key.components(separatedBy: "_")[1]
                mainParams = parameters
            }
            if key.hasPrefix("discovery_") && parameters.deploymentId == subProjId {
                subId = key.components(separatedBy: "_")[1]
                subParams = parameters
            }
        })
        
        guard let mainId = mainId, let mainParams = mainParams, let subId = subId, let subParams = subParams, let flowId = getFlowIdFor(projId: subProjId) else { return }
        
        let isMainProjFlowMenu = isFlowMenu(projectParams: mainParams)
        let isSubProjFlowMenu = isFlowMenu(projectParams: subParams)
        
        if !isMainProjFlowMenu || isSubProjFlowMenu { return }
        
        // context detection is stopped
        contextDetector?.stop()
        
        let flowSelected = self.currentConfiguration()?.flows.first { $0.id == flowId }
        guard let flow = flowSelected, let _ = flowManager else {
            // context detection is started
            self.contextDetector?.start()
            return
        }
        if let connectedProjs = configuration?.connectedProjects {
            for connectedProj in connectedProjs {
                if let connectedProjId = connectedProj[constant_projectId],
                   let deepLinkURL = connectedProj[constant_deepLinkURL],
                   connectedProjId == subProjId, let url = URL(string: deepLinkURL) {
                    UIApplication.shared.open(url)
                    break
                }
            }
        }
        let fmDiscovery = configuration?.discoveries.first { $0.id == Int(mainId) }
        guard let discovery = fmDiscovery else { return }
        let iconInfo:Dictionary<String,AnyHashable> = discovery.enableIcon ? getIconSettings(discovery.id) : [:]
        let htmlUrl = discovery.languageOption?[constant_htmlUrl]
        
        auiHandler?.showLanguageOptionsIfApplicable(withLocaleCodes: self.generateLangDicts(localeCodes: discovery.localeCodes), iconInfo: iconInfo, localeHtmlUrl: htmlUrl, handler: { chosen in
            if chosen {
                                
                
                self.analyticsDelegate?.queue(event: .startScreenEvent, for: LeapAnalyticsModel(projectParameter: mainParams, instructionId: mainId, isProjectFlowMenu: isMainProjFlowMenu, currentFlowMenu: self.validateFlowMenu().projectParams))
                
                self.analyticsDelegate?.queue(event: .optInEvent, for: LeapAnalyticsModel(projectParameter: mainParams, isProjectFlowMenu: isMainProjFlowMenu, currentFlowMenu: self.validateFlowMenu().projectParams, currentSubFlow: self.getSubFlowProjectParams()))
                                
                self.analyticsDelegate?.queue(event: .startScreenEvent, for: LeapAnalyticsModel(projectParameter: subParams, instructionId: subId, isProjectFlowMenu: isSubProjFlowMenu, currentFlowMenu: self.validateFlowMenu().projectParams))
                
                self.analyticsDelegate?.queue(event: .optInEvent, for: LeapAnalyticsModel(projectParameter: subParams, isProjectFlowMenu: isSubProjFlowMenu, currentFlowMenu: self.validateFlowMenu().projectParams, currentSubFlow: self.getSubFlowProjectParams()))
                
                self.flowManager?.addNewFlow(flow, false, Int(mainId), subDisId: Int(subId))
                self.contextDetector?.switchState()
                self.discoveryManager?.discoveryDismissed(byUser: false, optIn: true)
                if self.isStaticFlow(), let firstStep = flow.firstStep, let stage = self.getStage(firstStep) {
                    self.stageManager?.setFirstStage(stage)
                }
            }
            // context detection is started
            self.contextDetector?.start()
        })
    }
    
    @objc func previewNotification(_ notification:NSNotification) {
        contextDetector?.stop()
        guard let previewDict = notification.object as? Dictionary<String,Any> else { return }
        let tempConfig:Array<Dictionary<String,Any>> = {
            var configs = previewDict["configs"] as? Array<Any> ?? []
            configs = configs.filter{ !($0 is NSNull) }
            return configs as? Array<Dictionary<String,Any>> ?? []
        }()
        let configDict = ["data": tempConfig ]
        print("[Leap] Preview config received")
        assistManager?.resetManagerSession()
        discoveryManager?.resetManagerSession()
        flowManager?.resetFlowsArray()
        pageManager?.resetPageManager()
        stageManager?.resetStageManager()
        auiHandler?.removeAllViews()
        previewConfig = LeapConfig(withDict: configDict, isPreview: true)
        analyticsManager = nil
        if let state =  contextDetector?.getState(), state == .Stage { contextDetector?.switchState() }
        LeapPreferences.shared.isPreview = true
        contextDetector?.start()
        startSoundDownload()
    }
    
    func currentConfiguration() -> LeapConfig? {
        if let preview = previewConfig { return preview }
        return configuration
    }
    
    @objc func authLiveNotification(_ notification:NSNotification) {
        contextDetector?.stop()
        self.auiHandler?.removeAllViews()
        assistManager?.resetAssistManager()
        discoveryManager?.resetDiscovery()
        flowManager?.resetFlowsArray()
        pageManager?.resetPageManager()
        stageManager?.resetStageManager()
    }
    
    @objc func endPreview() {
        contextDetector?.stop()
        if let state =  contextDetector?.getState(), state == .Stage { contextDetector?.switchState() }
        auiHandler?.removeAllViews()
        assistManager?.resetManagerSession()
        discoveryManager?.resetManagerSession()
        flowManager?.resetFlowsArray()
        pageManager?.resetPageManager()
        stageManager?.resetStageManager()
        previewConfig = nil
        LeapSharedInformation.shared.previewEnded()
        LeapPreferences.shared.isPreview = false
        LeapPreferences.shared.previewUserLanguage = LeapPreferences.shared.getUserLanguage() ?? constant_ang
        analyticsManager = LeapAnalyticsManager(self)
        contextDetector?.start()
    }
    
    func getProjectParameter() -> LeapProjectParameters? {
        guard let state = contextDetector?.getState() else { return nil }
        switch state {
        case .Discovery:
            if let am = assistManager,
               let assist = am.getCurrentAssist() { return currentConfiguration()?.contextProjectParametersDict["assist_\(assist.id)"] }
            else if let dm = discoveryManager,
                    let discovery = dm.getCurrentDiscovery() { return currentConfiguration()?.contextProjectParametersDict["discovery_\(discovery.id)"] }
            else { return nil }
            
        case .Stage:
            if let fm = flowManager, let flow = fm.getArrayOfFlows().last, let flowId = flow.id { return currentConfiguration()?.contextProjectParametersDict["flow_\(flowId)"] }
        }
        return nil
    }
    
    func removeConfigFor(projectId:String) {
        let params:LeapProjectParameters?  = {
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
}

// MARK: - SOUND DOWNLOAD INITIATION
extension LeapContextManager {
    func startSoundDownload() {
        guard let aui = auiHandler else { return }
        DispatchQueue.global().async {
            aui.startMediaFetch()
        }
    }
}

// MARK: - CONTEXT DETECTOR DELEGATE METHODS
extension LeapContextManager:LeapContextDetectorDelegate {
    
    // MARK: - Identifier Methods
    func getWebIdentifier(identifierId: String) -> LeapWebIdentifier? {
        guard let currentConfiguration = self.currentConfiguration() else { return nil }
        return currentConfiguration.webIdentifiers[identifierId]
    }
    
    func getNativeIdentifier(identifierId: String) -> LeapNativeIdentifier? {
        guard let currentConfiguration = self.currentConfiguration() else { return nil }
        return currentConfiguration.nativeIdentifiers[identifierId]
    }
    
    func getNativeIdentifierDict() -> [String : LeapNativeIdentifier] {
        guard let currentConfiguration = self.currentConfiguration() else { return [:] }
        return currentConfiguration.nativeIdentifiers
    }
    
    func getWebIdentifierDict() -> [String : LeapWebIdentifier] {
        guard let currentConfiguration = self.currentConfiguration() else { return [:] }
        return currentConfiguration.webIdentifiers
    }
    
    
    // MARK: - Context Methods
    
    func getContextsToCheck() -> Array<LeapContext> {
        
        return (assistManager?.getAssistsToCheck() ?? []) + (discoveryManager?.getDiscoveriesToCheck() ?? [])
    }
    
    func getLiveContext() -> LeapContext? {
        if let currentAssist = assistManager?.getCurrentAssist() { return currentAssist }
        else if let currentDiscovery = discoveryManager?.getCurrentDiscovery() { return currentDiscovery }
        return nil
    }
    
    func contextDetected(context: LeapContext, view: UIView?, rect: CGRect?, webview: UIView?) {
//        print("[Leap] Context Detected")
        if let assist = context as? LeapAssist {
            discoveryManager?.resetDiscoveryManager()
            assistManager?.triggerAssist(assist, view, rect, webview)
        }
        else if let discovery = context as? LeapDiscovery {
            assistManager?.resetAssistManager()
            discoveryManager?.triggerDiscovery(discovery, view, rect, webview)
        }
    }
    
    func noContextDetected() {
//        print("[Leap] No Context Detected")
        assistManager?.resetAssistManager()
        discoveryManager?.resetDiscoveryManager()
    }
    
    // MARK: - Flow Methods
    
    func isDiscoveryFlowMenu() -> Bool {
        guard let discoveryId = flowManager?.getDiscoveryId() ?? discoveryManager?.getCurrentDiscovery()?.id, let projParams = self.currentConfiguration()?.contextProjectParametersDict["discovery_\(discoveryId)"]
        else { return false }
        let type = projParams.projectType ?? ""
        return type == constant_STATIC_FLOW_CHECKLIST || type == constant_DYNAMIC_FLOW_CHECKLIST || type == constant_STATIC_FLOW_MENU || type == constant_DYNAMIC_FLOW_MENU
    }
    
    func getFlowMenuDiscovery() -> LeapDiscovery? {
        guard let fm = flowManager, let disId = fm.getDiscoveryId() else { return nil }
        let discovery = self.currentConfiguration()?.discoveries.first { $0.id == disId }
        return discovery
    }
    
    func getCurrentFlow() -> LeapFlow? {
        return flowManager?.getRelevantFlow(lookForParent: false)
    }
    
    func getParentFlow() -> LeapFlow? {
        return flowManager?.getRelevantFlow(lookForParent: true)
    }
    
    func isStaticFlow() -> Bool {
        guard let params = getProjectParams() else { return false }
        let type = params.projectType ?? "DYNAMIC_FLOW"
        return type == "STATIC_FLOW"
    }
    
    // MARK: - Page Methods
    func pageIdentified(_ page: LeapPage) {
        pageManager?.setCurrentPage(page)
        flowManager?.updateFlowArrayAndResetCounter()
    }
    
    func pageNotIdentified(flowMenuIconNeeded:Bool?) {
        if flowMenuIconNeeded ?? false, let discovery = getFlowMenuDiscovery() {
            let iconInfo:Dictionary<String,AnyHashable> = getIconSettings(discovery.id)
            auiHandler?.presentLeapButton(for: iconInfo, iconEnabled: discovery.enableIcon)
        } else { auiHandler?.removeAllViews() }
        pageManager?.setCurrentPage(nil)
        stageManager?.noStageFound()
    }
    
    
    // MARK: - Stage Methods
    func getStagesToCheck() -> Array<LeapStage> {
        return stageManager?.getStagesToCheck() ?? []
    }
    
    func getCurrentStage() -> LeapStage? {
        return stageManager?.getCurrentStage()
    }
    
    func stageIdentified(_ stage: LeapStage, pointerView: UIView?, pointerRect: CGRect?, webviewForRect:UIView?, flowMenuIconNeeded:Bool?) {
        stageManager?.setCurrentStage(stage, view: pointerView, rect: pointerRect, webviewForRect: webviewForRect, flowMenuIconNeeded: flowMenuIconNeeded)
    }
    
    func stageNotIdentified(flowMenuIconNeeded:Bool?) {
        if flowMenuIconNeeded ?? false, let discovery = getFlowMenuDiscovery() {
            let iconInfo:Dictionary<String,AnyHashable> = getIconSettings(discovery.id)
            auiHandler?.presentLeapButton(for: iconInfo, iconEnabled: discovery.enableIcon)
        } else { auiHandler?.removeAllViews() }
        stageManager?.noStageFound()
    }
}

// MARK: - ASSIST MANAGER DELEGATE METHODS
extension LeapContextManager: LeapAssistManagerDelegate {
    
    func getAllAssists() -> Array<LeapAssist> {
        if let preview = previewConfig {
            return preview.assists
        }
        guard let config = self.currentConfiguration() else { return [] }
        return config.assists
    }
    
    func newAssistIdentified(_ assist: LeapAssist, view: UIView?, rect: CGRect?, inWebview: UIView?) {
        guard let aui = auiHandler, let assistInstructionInfoDict = assist.instructionInfoDict else { return }
        if let currentEmbeddedDeploymentId = delegate?.getCurrentEmbeddedProjectId() {
            var parameters:LeapProjectParameters?
            self.currentConfiguration()?.contextProjectParametersDict.forEach({ key, params in
                if params.deploymentId == currentEmbeddedDeploymentId {parameters = params }
            })
            if let currentParameters = parameters,
               let projId = currentParameters.projectId,
               let assistIdFromParams = self.currentConfiguration()?.projectContextDict["assist_\(projId)"] {
                if assistIdFromParams != assist.id {
                    removeConfigFor(projectId: currentEmbeddedDeploymentId)
                    delegate?.resetCurrentEmbeddedProjectId()
                }
            }
        }
        if let anchorRect = rect {
            aui.performWebAssist(instruction: assistInstructionInfoDict, rect: anchorRect, webview: inWebview, localeCode: assist.localeCode)
        } else {
            aui.performNativeAssist(instruction: assistInstructionInfoDict, view: view, localeCode: assist.localeCode)
        }
    }
    
    func sameAssistIdentified(view: UIView?, rect: CGRect?, inWebview: UIView?) {
        if let anchorRect = rect { auiHandler?.updateRect(rect: anchorRect, inWebView: inWebview) }
        else if let anchorView = view { auiHandler?.updateView(inView: anchorView) }
    }
    
    func dismissAssist() { auiHandler?.removeAllViews() }
    
    func sendAssistTerminationEvent(with id: Int, for rule: String) {
        let projectParams = self.currentConfiguration()?.projectParameters.first { $0.id == id }
        analyticsDelegate?.queue(event: .projectTerminationEvent, for: LeapAnalyticsModel(projectParameter: projectParams, terminationRule: rule))
        LeapSharedInformation.shared.terminationEventSent(discoveryId: nil, assistId: id, isPreview: isPreview())
    }
}

// MARK: - DISCOVERY MANAGER DELEGATE METHODS
extension LeapContextManager: LeapDiscoveryManagerDelegate {
    
    func getAllDiscoveries() -> Array<LeapDiscovery> {
        if let preview = previewConfig {
            return preview.discoveries
        }
        guard let config = self.currentConfiguration() else { return [] }
        return config.discoveries
    }
    
    func getFlowProjIdsFor(flowIds:Array<Int>) -> Array<String> {
        guard let config = self.currentConfiguration() else { return [] }
        let projIds:Array<String> = flowIds.compactMap { flowId -> String? in
            return config.contextProjectParametersDict["flow_\(flowId)"]?.deploymentId
        }
        return projIds
    }
    
    func getProjContextIdDict() -> Dictionary<String, Int> {
        return self.currentConfiguration()?.projectContextDict ?? [:]
    }
    
    func getProjParametersDict() -> Dictionary<String, LeapProjectParameters> {
        return self.currentConfiguration()?.contextProjectParametersDict ?? [:]
    }
    
    func newDiscoveryIdentified(discovery: LeapDiscovery, view:UIView?, rect:CGRect?, webview:UIView?) {
        guard  let aui = auiHandler, let dm = discoveryManager else { return }
        if let currentEmbeddedDeploymentId = delegate?.getCurrentEmbeddedProjectId() {
            var parameters:LeapProjectParameters?
            self.currentConfiguration()?.contextProjectParametersDict.forEach({ key, params in
                if params.deploymentId == currentEmbeddedDeploymentId {parameters = params }
            })
            if let currentParameters = parameters,
               let projId = currentParameters.projectId,
               let discoveryIdFromParams = self.currentConfiguration()?.projectContextDict["discovery_\(projId)"] {
                if discoveryIdFromParams != discovery.id {
                    removeConfigFor(projectId: currentEmbeddedDeploymentId)
                    delegate?.resetCurrentEmbeddedProjectId()
                }
            }
        }
        guard !dm.isManualTrigger()  else {
            //present leap button
            let iconInfo:Dictionary<String,AnyHashable> = getIconSettings(discovery.id)
            aui.presentLeapButton(for: iconInfo, iconEnabled: discovery.enableIcon)
            return
        }
        let htmlUrl = discovery.languageOption?[constant_htmlUrl]
        let iconInfo:Dictionary<String,AnyHashable> = discovery.enableIcon ? getIconSettings(discovery.id) : [:]
        guard !discovery.autoStart else {
            auiHandler?.showLanguageOptionsIfApplicable(withLocaleCodes: self.generateLangDicts(localeCodes: discovery.localeCodes), iconInfo: iconInfo, localeHtmlUrl: htmlUrl, handler: { langChose in
                if langChose {
                    self.didPresentAssist()
                    self.didDismissView(byUser: true, autoDismissed: false, panelOpen: false, action: [constant_body:[constant_optIn:true]])
                } else {
                    self.auiHandler?.presentLeapButton(for: iconInfo, iconEnabled: !iconInfo.isEmpty)
                }
            })
            return
        }
        
        guard let instruction = discovery.instructionInfoDict else { return }
        
        let localeCode = generateLangDicts(localeCodes: discovery.localeCodes)
        

        if let anchorRect = rect {
            aui.performWebDiscovery(instruction: instruction, rect: anchorRect, webview: webview, localeCodes: localeCode, iconInfo: iconInfo, localeHtmlUrl: htmlUrl)
        } else {
            aui.performNativeDiscovery(instruction: instruction, view: view, localeCodes: localeCode, iconInfo: iconInfo, localeHtmlUrl: htmlUrl)
        }
    }
    
    func sameDiscoveryIdentified(discovery: LeapDiscovery, view:UIView?, rect:CGRect?, webview:UIView?) {
        if let anchorRect = rect { auiHandler?.updateRect(rect: anchorRect, inWebView: webview) }
        else if let anchorView = view { auiHandler?.updateView(inView: anchorView) }
    }
    
    func dismissDiscovery() { auiHandler?.removeAllViews() }
    
    func sendDiscoveryTerminationEvent(with id: Int, for rule: String) {
        let projectParams = self.currentConfiguration()?.projectParameters.first { $0.id == id }
        analyticsDelegate?.queue(event: .projectTerminationEvent, for: LeapAnalyticsModel(projectParameter: projectParams, terminationRule: rule))
        LeapSharedInformation.shared.terminationEventSent(discoveryId: id, assistId: nil, isPreview: isPreview())
    }
}

// MARK: - FLOW MANAGER DELEGATE METHODS
extension LeapContextManager: LeapFlowManagerDelegate {
    
    func noActiveFlows() {
        pageManager?.resetPageManager()
        stageManager?.resetStageManager()
        guard let state = contextDetector?.getState(), state == .Stage else { return }
        contextDetector?.switchState()
    }
}

// MARK: - PAGE MANAGER DELEGATE METHODS
extension LeapContextManager: LeapPageManagerDelegate {
    func newPageIdentified() {
        //        sendContextInfoEvent(eventTag: "leapPageEvent")
    }
}

// MARK: - STAGE MANAGER DELEGATE METHODS
extension LeapContextManager: LeapStageManagerDelegate {
    
    func getCurrentPage() -> LeapPage? {
        return pageManager?.getCurrentPage()
    }
    
    func getStage(_ name:String) -> LeapStage? {
        guard let fm = flowManager, let flow = fm.getArrayOfFlows().last else { return nil }
        let nameArray = name.components(separatedBy: "_")
        guard nameArray.count == 6 else { return nil }
        let flowId:Int? = {
            guard nameArray[0] == "flow" else { return nil }
            return Int(nameArray[1])
        }()
        guard let flowId = flowId, flowId == flow.id else { return nil }

        let pageId:Int? = {
            guard nameArray[2] == "page" else { return nil }
            return Int(nameArray[3])
        }()
        guard let pageId = pageId else { return nil }
        let pageFound:LeapPage? = flow.pages.first{ $0.id == pageId }
        guard let page = pageFound else { return nil }

        let stageId:Int? = {
            guard nameArray[4] == "stage" else { return nil }
            return Int(nameArray[5])
        }()
        guard let stageId = stageId else { return nil }
        let stage:LeapStage? = page.stages.first{ $0.id == stageId }
        return stage
    }
    
    func getProjectParams() -> LeapProjectParameters? {
        return getProjectParameter()
    }
    
    func newStageFound(_ stage: LeapStage, view: UIView?, rect: CGRect?, webviewForRect:UIView?, flowMenuIconNeeded:Bool?) {
        let iconInfo:Dictionary<String,AnyHashable> = {
            guard let fm = flowManager, let discId = fm.getDiscoveryId() else { return [:] }
            if isDiscoveryFlowMenu(), let iconNeeded = flowMenuIconNeeded {
                if !iconNeeded { return [:] }
                return getIconSettings(discId)
            }
            let currentDiscovery = self.currentConfiguration()?.discoveries.first { $0.id == discId }
            guard let discovery = currentDiscovery, discovery.enableIcon else {return [:] }
            return getIconSettings(discId)
        }()
        if iconInfo.isEmpty { auiHandler?.removeAllViews() }
        guard !LeapSharedInformation.shared.isMuted(isPreview: isPreview()), let stageInstructionInfoDict = stage.instructionInfoDict else { return }
        if let anchorRect = rect {
            auiHandler?.performWebStage(instruction: stageInstructionInfoDict, rect: anchorRect, webview: webviewForRect, iconInfo: iconInfo)
        } else {
            auiHandler?.performNativeStage(instruction: stageInstructionInfoDict, view: view, iconInfo: iconInfo)
        }
        //sendContextInfoEvent(eventTag: "leapInstructionEvent")
    }
    
    func sameStageFound(_ stage: LeapStage, view:UIView?, newRect: CGRect?, webviewForRect:UIView?, flowMenuIconNeeded:Bool?) {
        if let rect = newRect { auiHandler?.updateRect(rect: rect, inWebView: webviewForRect) }
        else if let anchorView = view { auiHandler?.updateView(inView: anchorView) }
    }
    
    func dismissStage() { auiHandler?.removeAllViews() }
    
    func removeStage(_ stage: LeapStage) { pageManager?.removeStage(stage) }
    
    func isSuccessStagePerformed() {
        if let discoveryId = flowManager?.getDiscoveryId() {
            LeapSharedInformation.shared.discoveryFlowCompleted(discoveryId: discoveryId, isPreview: isPreview())
            let flowsCompletedCount = LeapSharedInformation.shared.getDiscoveryFlowCompletedInfo(isPreview: isPreview())
            let discovery = currentConfiguration()?.discoveries.first { $0.id == discoveryId }
            if let currentFlowCompletedCount = flowsCompletedCount["\(discoveryId)"], let perApp = discovery?.terminationfrequency?.perApp, perApp != -1 {
                if currentFlowCompletedCount >= perApp {
                    analyticsDelegate?.queue(event: .projectTerminationEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter(), terminationRule: "After \(perApp) flow completion"))
                }
            }
        }
        if let flowId = flowManager?.getArrayOfFlows().last?.id, let discoveryId = flowManager?.getDiscoveryId() {
            LeapSharedInformation.shared.saveCompletedFlowInfo(flowId,disId: discoveryId, isPreview: isPreview())
        }
        auiHandler?.removeAllViews()
        flowManager?.popLastFlow()
    }
    
}

extension LeapContextManager {
    
    func validateFlowMenu() -> (isFlowMenu: Bool, projectParams: LeapProjectParameters?) {
        if let discoveryId = flowManager?.getDiscoveryId(), let projectParams = currentConfiguration()?.contextProjectParametersDict["discovery_\(discoveryId)"] {
            if projectParams.projectType == constant_DYNAMIC_FLOW_MENU || projectParams.projectType == constant_DYNAMIC_FLOW_CHECKLIST || projectParams.projectType == constant_STATIC_FLOW_MENU || projectParams.projectType == constant_STATIC_FLOW_CHECKLIST {
                return (true, projectParams)
            } else {
                return (false, nil)
            }
        }
        return (false, nil)
    }
    
    func getSubFlowProjectParams() -> LeapProjectParameters? {
        if let discoveryId = flowManager?.getSubId(), let projectParams = currentConfiguration()?.contextProjectParametersDict["discovery_\(discoveryId)"] {
            return projectParams
        }
        return nil
    }
    
    func isFlowMenu(projectParams: LeapProjectParameters?) -> Bool {
        if projectParams?.projectType == constant_DYNAMIC_FLOW_MENU || projectParams?.projectType == constant_DYNAMIC_FLOW_CHECKLIST || projectParams?.projectType == constant_STATIC_FLOW_MENU || projectParams?.projectType == constant_STATIC_FLOW_CHECKLIST {
            return true
        } else {
            return false
        }
    }
}

// MARK: - ANALYTICS MANAGER DELEGATE METHODS
extension LeapContextManager: LeapEventsDelegate {
    
    func sendPayload(_ payload: Dictionary<String, Any>) {
        auiHandler?.sendEvent(event: payload)
    }
}

// MARK: - AUICALLBACK METHODS
extension LeapContextManager:LeapAUICallback {
    
    func getDefaultMedia() -> Dictionary<String, Any> {
        guard let config = self.currentConfiguration() else { return [:] }
        let auiContent = config.auiContent.compactMap { content -> Dictionary<String,Any>? in
            var updatedContent:Dictionary<String,Any>? = content
            var content:Array<String> = updatedContent?[constant_content] as? Array<String> ?? []
            for discovery in config.discoveries {
                if !discovery.autoStart { continue }
                if let discoveryHtml = discovery.instruction?.assistInfo?.htmlUrl {
                    content = content.filter{ $0 != discoveryHtml }
                }
            }
            if content.isEmpty { return nil }
            updatedContent?[constant_content] = content
            return updatedContent
        }
        let discoverySounds = config.discoverySounds.compactMap { tempDiscoverySound -> [String:Any]? in
            var discoverySound = tempDiscoverySound
            var jinySound = discoverySound[constant_leapSounds] as? [String:[[String:AnyHashable]]]
            for disc in config.discoveries {
                if !disc.autoStart { continue }
                if let soundNameForDis = disc.instruction?.soundName {
                    jinySound?.forEach({ localeCode, localeSoundsArray in
                        let newLocaleSoundsArray = localeSoundsArray.filter { localeSoundInfo in
                            if let soundName = localeSoundInfo[constant_name] as? String {
                                return soundNameForDis != soundName
                            }
                            return true
                        }
                        if newLocaleSoundsArray.isEmpty { jinySound?.removeValue(forKey: localeCode) }
                        else { jinySound?[localeCode] = newLocaleSoundsArray }
                    })
                } else { continue }
            }
            discoverySound[constant_leapSounds] = jinySound
            return discoverySound
        }
        let initialMedia:Dictionary<String,Any> = [constant_discoverySounds:discoverySounds, constant_auiContent:auiContent, constant_iconSetting:config.iconSetting, constant_localeSounds:config.localeSounds]
        return initialMedia
    }

    
    func isFlowMenu() -> Bool {
        return isDiscoveryFlowMenu()
    }
    
    func getFlowMenuInfo() -> Dictionary<String, Bool>? {
        guard let currentDiscovery = discoveryManager?.getCurrentDiscovery() else { return nil }
        return getFlowMenuInfo(discovery: currentDiscovery)
    }
    
    func getWebScript(_ identifier:String) -> String? {
        guard let webId = getWebIdentifier(identifierId: identifier) else { return nil }
        let basicElementScript = LeapJSMaker.generateBasicElementScript(id: webId)
        let focusScript = "(\(basicElementScript)).focus()"
        return focusScript
    }
    
    func getCurrentLanguageOptionsTexts() -> Dictionary<String,String> {
        let langCode = getLanguageCode()
        let lang = self.currentConfiguration()?.languages.first{ $0.localeId == langCode }
        let languages = getLanguagesForCurrentInstruction()
        guard let language = lang else {
            var dict:Dictionary<String, String> = [constant_stop:"Stop"]
            if languages.count > 1 { dict[constant_language] = "Language" }
            return dict
        }
        let stopText = language.muteText
        let languageText = language.changeLanguageText
        var dict:Dictionary<String, String> = [constant_stop:stopText]
        if languages.count > 1 { dict[constant_language] = languageText }
        return dict
    }
    
    func getLanguagesForCurrentInstruction() -> Array<Dictionary<String,String>> {
        guard let discovery = getLiveDiscovery() else { return [] }
        return generateLangDicts(localeCodes: discovery.localeCodes)
    }
    
    func getIconInfoForCurrentInstruction() -> Dictionary<String,Any>? {
        guard let discovery = getLiveDiscovery() else { return nil }
        return getIconSettings(discovery.id)
    }
    
    func getLanguageHtmlUrl() -> String? {
        guard let discovery = getLiveDiscovery() else { return nil }
        return discovery.languageOption?[constant_htmlUrl]
    }
    
    func getLanguageCode() -> String {
        if let code = LeapPreferences.shared.getUserLanguage() { return code }
        if let firstLanguage = self.currentConfiguration()?.languages.first { return firstLanguage.localeId }
        return "ang"
    }
    
    func getTTSCodeFor(code:String) -> String? {
        let lang = self.currentConfiguration()?.languages.first{ $0.localeId == code }
        guard let language = lang,
              let ttsInfo = language.ttsInfo,
              let locale = ttsInfo.ttsLocale,
              let region = ttsInfo.ttsRegion else { return nil }
        return "\(locale)-\(region)"
    }
    
    func didPresentAssist() {
        guard let state = contextDetector?.getState() else { return }
        switch state {
        case .Discovery:
            if let am = assistManager, let assist = am.getCurrentAssist() {
                // assist Instriuction
                am.assistPresented()
                guard let instruction = assist.instruction else { return }
                self.analyticsDelegate?.queue(event: .assistInstructionEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter(), instructionId: instruction.id, currentAssist: assistManager?.getCurrentAssist()))
            }
            else if let dm = discoveryManager, let discovery = dm.getCurrentDiscovery() {
                dm.discoveryPresented()
                // start screen event
                guard let instruction = discovery.instruction else { return }
                
                guard let projectParameters = getProjectParameter() else { return }
                
                self.analyticsDelegate?.queue(event: .startScreenEvent, for: LeapAnalyticsModel(projectParameter: projectParameters, instructionId: instruction.id, isProjectFlowMenu: isFlowMenu(projectParams: projectParameters), currentFlowMenu: validateFlowMenu().projectParams))
            }
        case .Stage:
            // stage instruction
            // TODO: triggered multiple times
            // TODO: Instruction should be triggered once, check id (UUID) and if there is a change in language, can send event again.
            // TODO: - above scenario for start screen and element seen
            guard let sm = stageManager, let stage = sm.getCurrentStage(), let instruction = stage.instruction else { return }
            // Element seen Event
            self.analyticsDelegate?.queue(event: .instructionEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter(), instructionId: instruction.id, currentFlowMenu: validateFlowMenu().projectParams, currentSubFlow: getSubFlowProjectParams(), currentStage: stageManager?.getCurrentStage(), currentPage: pageManager?.getCurrentPage()))
            break
        }
    }
    
    func failedToPerform() {
        assistManager?.resetCurrentAssist()
        stageManager?.resetCurrentStage()
        discoveryManager?.resetDiscovery()
    }
    
    func didDismissView(byUser: Bool, autoDismissed: Bool, panelOpen: Bool, action: Dictionary<String,Any>?) {
        guard let state = contextDetector?.getState() else { return }
        switch state {
        case .Discovery:
            if let am = assistManager, let _ = am.getCurrentAssist() {
                // aui action tracking
                if let action = action {
                    self.analyticsDelegate?.queue(event: .actionTrackingEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter(), action: action, currentFlowMenu: validateFlowMenu().projectParams, currentSubFlow: getSubFlowProjectParams(), currentStage: stageManager?.getCurrentStage(), currentPage: pageManager?.getCurrentPage(), currentAssist: assistManager?.getCurrentAssist()))
                }
            }
            guard let liveContext = getLiveContext() else { return }
            if let _  = liveContext as? LeapAssist { assistManager?.assistDismissed(byUser: byUser, autoDismissed: autoDismissed) }
            else if let _ = liveContext as? LeapDiscovery { handleDiscoveryDismiss(byUser: byUser, action: action) }
            
        case .Stage:
            if panelOpen {
                stageManager?.resetCurrentStage()
                return
            }
            // aui action tracking
            if let action = action {
                self.analyticsDelegate?.queue(event: .actionTrackingEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter(), action: action, currentFlowMenu: validateFlowMenu().projectParams, currentSubFlow: getSubFlowProjectParams(), currentStage: stageManager?.getCurrentStage(), currentPage: pageManager?.getCurrentPage(), currentAssist: assistManager?.getCurrentAssist()))
            }
            guard let sm = stageManager, let stage = sm.getCurrentStage() else { return }
            
            // Flow success Event
            if stage.isSuccess && (byUser || autoDismissed) {
                self.analyticsDelegate?.queue(event: .flowSuccessEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter(), currentFlowMenu: validateFlowMenu().projectParams, currentSubFlow: getSubFlowProjectParams()))
            }
            
            var endFlow = false
            if let body = action?[constant_body] as? Dictionary<String, Any> { endFlow = body[constant_endFlow] as? Bool ?? false }
            sm.stageDismissed(byUser: byUser, autoDismissed:autoDismissed)
            if endFlow {
                if let disId = flowManager?.getDiscoveryId() { LeapSharedInformation.shared.muteDisovery(disId,isPreview: isPreview()) }
                flowManager?.resetFlowsArray()
                pageManager?.resetPageManager()
                stageManager?.resetStageManager()
                guard let state = contextDetector?.getState(), state == .Stage else { return }
                contextDetector?.switchState()
            }
        }
    }
    
    func leapTapped() {
        //sendContextInfoEvent(eventTag: "leapIconClickedEvent")
        guard let state = contextDetector?.getState() else { return }
        switch state {
        case .Discovery:
            manuallyTriggerCurrentDiscovery()
        case .Stage:
            contextDetector?.stop()
            auiHandler?.removeAllViews()
            contextDetector?.switchState()
            let disId = flowManager?.getDiscoveryId()
            if let discoveryId = disId {
                discoveryManager?.removeDiscoveryFromCompletedInSession(disId: discoveryId)
            }
            flowManager?.resetFlowsArray()
            pageManager?.resetPageManager()
            stageManager?.resetStageManager()
            contextDetector?.start()
            
        }
    }
    
    func optionPanelStopClicked() {
        // Flow Stop event
        self.analyticsDelegate?.queue(event: .flowStopEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter(), currentStage: stageManager?.getCurrentStage(), currentPage: pageManager?.getCurrentPage()))
        guard let dis = getLiveDiscovery() else {
            contextDetector?.start()
            return
        }
        LeapSharedInformation.shared.muteDisovery(dis.id, isPreview: isPreview())
        flowManager?.resetFlowsArray()
        pageManager?.resetPageManager()
        stageManager?.resetStageManager()
        discoveryManager?.resetDiscoveryManager()
        if let state = contextDetector?.getState(), state == .Stage { contextDetector?.switchState() }
    }
    
    func optionPanelOpened() {
    }
    
    func optionPanelClosed() {
        //sendContextInfoEvent(eventTag: "crossClickedFromPanelEvent")
    }
    
    func disableAssistance() {
        // send flow disable event
        self.analyticsDelegate?.queue(event: .flowDisableEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter()))
        
        guard let state = contextDetector?.getState(), state == .Stage else {
            if let discoveryId = discoveryManager?.getCurrentDiscovery()?.id {
                LeapSharedInformation.shared.terminateDiscovery(discoveryId, isPreview: isPreview())
                discoveryManager?.resetDiscovery()
            }
            return
        }
        guard let discoveryId = flowManager?.getDiscoveryId() else { return }
        LeapSharedInformation.shared.terminateDiscovery(discoveryId, isPreview: isPreview())
        discoveryManager?.resetDiscovery()
        flowManager?.resetFlowsArray()
        pageManager?.resetPageManager()
        stageManager?.resetStageManager()
        contextDetector?.switchState()
    }
    
    func disableLeapSDK() {
        contextDetector?.stop()
        analyticsDelegate?.queue(event: .leapSdkDisableEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter()))
    }
    
    func didLanguageChange(from previousLanguage: String, to currentLanguage: String) {
        analyticsDelegate?.queue(event: .languageChangeEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter(), previousLanguage: previousLanguage, currentLanguage: currentLanguage))
    }
    
    func receiveAUIEvent(action: Dictionary<String, Any>) {
        analyticsDelegate?.queue(event: .actionTrackingEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter(), action: action, currentFlowMenu: validateFlowMenu().projectParams, currentSubFlow: getSubFlowProjectParams(), currentStage: stageManager?.getCurrentStage(), currentPage: pageManager?.getCurrentPage(), currentAssist: assistManager?.getCurrentAssist()))
    }
    
    func flush() {
        delegate?.fetchUpdatedConfig(completion: { (config) in
            DispatchQueue.main.async { self.startSoundDownload() }
            guard let config = config, let state = self.contextDetector?.getState() else { return }
            switch state {
            case .Discovery:
                guard let liveContext = self.getLiveContext() else {
                    self.contextDetector?.stop()
                    self.resetAllManagers()
                    self.configuration = config
                    self.contextDetector?.start()
                    return
                }
                if let assist = liveContext as? LeapAssist, config.assists.contains(assist) {
                    self.contextDetector?.stop()
                    self.configuration = config
                    self.contextDetector?.start()
                } else if let discovery = liveContext as? LeapDiscovery, config.discoveries.contains(discovery) {
                    self.contextDetector?.stop()
                    self.configuration = config
                    self.contextDetector?.start()
                } else {
                    self.auiHandler?.removeAllViews()
                    self.contextDetector?.stop()
                    self.resetAllManagers()
                    self.configuration = config
                    self.contextDetector?.start()
                }
            case .Stage:
                guard let flow = self.flowManager?.getArrayOfFlows().last,
                      config.flows.contains(flow) else {
                    self.contextDetector?.stop()
                    self.auiHandler?.removeAllViews()
                    self.contextDetector?.switchState()
                    self.resetAllManagers()
                    self.configuration = config
                    self.contextDetector?.start()
                    return
                }
                self.contextDetector?.stop()
                self.configuration = config
                self.contextDetector?.start()
            }
        })
    }
    
    func getProjectParameters() -> [String : Any]? {
        return self.getProjectParameter()?.dictionary
    }
}

// MARK: - ADDITIONAL METHODS
extension LeapContextManager {
    
    func manuallyTriggerCurrentDiscovery() {
        guard let dm = discoveryManager,
              let liveDiscovery = dm.getCurrentDiscovery() else { return }
        
        LeapSharedInformation.shared.unmuteDiscovery(liveDiscovery.id, isPreview: isPreview())
        let iconInfo:Dictionary<String,AnyHashable> = liveDiscovery.enableIcon ? getIconSettings(liveDiscovery.id) : [:]
        let htmlUrl = liveDiscovery.languageOption?["htmlUrl"]
        let langDict = self.generateLangDicts(localeCodes: liveDiscovery.localeCodes)
        if liveDiscovery.autoStart {
            auiHandler?.showLanguageOptionsIfApplicable(withLocaleCodes: langDict, iconInfo: iconInfo, localeHtmlUrl: htmlUrl, handler: {[weak self] languageChose in
                guard !languageChose else {
                    self?.didPresentAssist()
                    self?.didDismissView(byUser: true, autoDismissed: false, panelOpen: false, action: [constant_body:[constant_optIn:true]])
                    return
                }
                self?.auiHandler?.presentLeapButton(for: iconInfo, iconEnabled: !iconInfo.isEmpty)
            })
            return
        }
        
        guard let _ = liveDiscovery.instruction?.assistInfo?.identifier else {
            if let liveDiscoveryInstructionInfoDict = liveDiscovery.instructionInfoDict {
                auiHandler?.performNativeDiscovery(instruction: liveDiscoveryInstructionInfoDict, view: nil, localeCodes: self.generateLangDicts(localeCodes: liveDiscovery.localeCodes), iconInfo: iconInfo, localeHtmlUrl: htmlUrl)
            }
            return
        }
    
        guard let nativeDict = currentConfiguration()?.nativeIdentifiers,
              let webDict = currentConfiguration()?.webIdentifiers,
              let controller = UIApplication.getCurrentVC() else { return }
        let hierarchyFetcher = LeapHierarchyFetcher(forController: String(describing: type(of: controller)))
        let hierarchy = hierarchyFetcher.fetchHierarchy()
        let contextValidator = LeapContextsValidator<LeapDiscovery>(withNativeDict: nativeDict, webDict: webDict)
        contextValidator.getTriggerableContext(liveDiscovery, validContexts: [liveDiscovery], hierarchy: hierarchy) {[weak self] contextToTrigger, anchorViewId, anchorRect, anchorWebview in
            if let discoveryInstructionDict = liveDiscovery.instructionInfoDict {
                if let anchorRect = anchorRect {
                    self?.auiHandler?.performWebDiscovery(instruction: discoveryInstructionDict, rect: anchorRect, webview: anchorWebview, localeCodes: langDict, iconInfo: iconInfo, localeHtmlUrl: htmlUrl)
                } else {
                    self?.auiHandler?.performNativeDiscovery(instruction: discoveryInstructionDict, view: anchorWebview, localeCodes: langDict, iconInfo: iconInfo, localeHtmlUrl: htmlUrl)
                }
            }
        }
    }
    
    func handleDiscoveryDismiss(byUser:Bool, action:Dictionary<String,Any>?) {
        guard let body = action?[constant_body] as? Dictionary<String,Any>,
              let optIn = body[constant_optIn] as? Bool, optIn,
              let dm = discoveryManager,
              let discovery = dm.getCurrentDiscovery() else {
            // optOut
            analyticsDelegate?.queue(event: .optOutEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter()))
            discoveryManager?.discoveryDismissed(byUser: byUser, optIn: false)
            return
        }
        
        let flowId:Int? = {
            guard let projId = body[constant_projectId] as? String else { return discovery.flowId }
            return getFlowIdFor(projId: projId)
        }()
        guard let flowId = flowId else {
            analyticsDelegate?.queue(event: .optOutEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter()))
            discoveryManager?.discoveryDismissed(byUser: byUser, optIn: false)
            return
        }
        let flowSelected = self.currentConfiguration()?.flows.first { $0.id == flowId }
        guard let flow = flowSelected, let fm = flowManager else {
            discoveryManager?.discoveryDismissed(byUser: byUser, optIn: false)
            return
        }
        
        let isFlowMenu = isDiscoveryFlowMenu()
        let subId:Int? = {
            guard let projId = body[constant_projectId] as? String, isFlowMenu else { return nil }
            var parameters:LeapProjectParameters?
            self.currentConfiguration()?.contextProjectParametersDict.forEach({ key, params in
                if params.deploymentId == projId && key.hasPrefix("discovery_") { parameters = params }
            })
            guard let selectedParameters = parameters,
                  let projectId = selectedParameters.projectId else { return nil }
            
            let subId = self.currentConfiguration()?.projectContextDict["discovery_\(projectId)"]
            return subId
        }()
        fm.addNewFlow(flow, false, discovery.id, subDisId: subId)
        // intended to switch from discovery to stage
        contextDetector?.switchState()
        if isStaticFlow(), let firstStep = flow.firstStep, let stage = getStage(firstStep) {
            stageManager?.setFirstStage(stage)
        }
        discoveryManager?.discoveryDismissed(byUser: true, optIn: true)
        
        // optIn event
        let flowMenuValidation = validateFlowMenu()
        analyticsManager?.queue(event: .optInEvent, for: LeapAnalyticsModel(projectParameter: flowMenuValidation.projectParams, isProjectFlowMenu: flowMenuValidation.isFlowMenu, currentFlowMenu: flowMenuValidation.projectParams, currentSubFlow: getSubFlowProjectParams()))
        
        // start screen event
        if let subFlowId = flowManager?.getSubId() {
            guard let subFlowProjectParams = getSubFlowProjectParams() else { return }
            analyticsDelegate?.queue(event: .startScreenEvent, for: LeapAnalyticsModel(projectParameter: subFlowProjectParams, instructionId: "\(subFlowId)", isProjectFlowMenu: self.isFlowMenu(projectParams: subFlowProjectParams), currentFlowMenu: validateFlowMenu().projectParams))
        }
        
        // optIn event for sub-flow / project
        let subFlowProjectParams = getSubFlowProjectParams() ?? getProjectParameter()
        analyticsDelegate?.queue(event: .optInEvent, for: LeapAnalyticsModel(projectParameter: subFlowProjectParams, isProjectFlowMenu: self.isFlowMenu(projectParams: subFlowProjectParams), currentFlowMenu: validateFlowMenu().projectParams, currentSubFlow: getSubFlowProjectParams()))
    }
    
    func getIconSettings(_ discoveryId:Int) -> Dictionary<String,AnyHashable> {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        guard let iconInfo = self.currentConfiguration()?.iconSetting[String(discoveryId)],
              let iconInfoData = try? jsonEncoder.encode(iconInfo),
              let iconInfoDict = try? JSONSerialization.jsonObject(with: iconInfoData, options: .allowFragments) as? Dictionary<String,AnyHashable> else { return [:] }
        return iconInfoDict
    }
    
    func generateLangDicts(localeCodes:Array<String>?) -> Array<Dictionary<String,String>>{
        guard let codes = localeCodes else { return [] }
        let langDicts = codes.map { (langCode) -> Dictionary<String,String>? in
            let tempLanguage = self.currentConfiguration()?.languages.first { $0.localeId == langCode }
            guard let language = tempLanguage else { return nil }
            return ["localeId":language.localeId, "localeName":language.name, "localeScript":language.script]
        }.compactMap { return $0 }
        return langDicts
    }
    
    func getLiveDiscovery() -> LeapDiscovery? {
        guard let state = contextDetector?.getState(),
              let disId = state == .Discovery ? discoveryManager?.getCurrentDiscovery()?.id : flowManager?.getDiscoveryId() else { return nil }
        let currentDiscovery = self.currentConfiguration()?.discoveries.first{ $0.id == disId }
        return currentDiscovery
    }
    
    func resetAllManagers() {
        self.assistManager?.resetCurrentAssist()
        self.discoveryManager?.resetDiscovery()
        self.flowManager?.resetFlowsArray()
        self.pageManager?.resetPageManager()
        self.stageManager?.resetStageManager()
    }
    
    func isPreview() -> Bool {
        guard let _ = self.previewConfig else { return false }
        return true
    }
    
    func isDiscoveryChecklist(discovery:LeapDiscovery) -> Bool {
        let params = self.currentConfiguration()?.contextProjectParametersDict["discovery_\(discovery.id)"]
        guard let parameters = params else { return false }
        let type = parameters.projectType ?? ""
        return type == constant_DYNAMIC_FLOW_CHECKLIST || type == constant_STATIC_FLOW_CHECKLIST
    }
    
    func getFlowMenuInfo(discovery: LeapDiscovery) -> Dictionary<String, Bool>? {
        guard isDiscoveryChecklist(discovery: discovery) else { return nil }
        guard let currentDiscovery = discoveryManager?.getCurrentDiscovery() else { return nil }
        let completedFlowIds:Dictionary<String,Array<Int>> = LeapSharedInformation.shared.getCompletedFlowInfo(isPreview: isPreview())
        let completedFlowIdForCurrentDiscovery = completedFlowIds["\(currentDiscovery.id)"] ?? []
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
    
    func getFlowIdFor(projId:String) -> Int? {
        var flowId:Int? = nil
        self.currentConfiguration()?.contextProjectParametersDict.forEach({ key, projParams in
            if key.hasPrefix("flow_"), projParams.deploymentId == projId {
                flowId = Int(key.split(separator: "_")[1])
            }
        })
        return flowId
    }
    
    func isFlowEmbedFor(projectId:String) -> Bool {
        var projParams:LeapProjectParameters?
        self.currentConfiguration()?.contextProjectParametersDict.forEach({ key, params in
            if key.hasPrefix("discovery_") && params.deploymentId == projectId {
                projParams = params
            }
        })
        guard let projectParameters = projParams else { return false }
        return projectParameters.getIsEmbed()
    }
}
