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
    func fetchUpdatedConfig(completion: @escaping(_ : LeapConfig?) -> Void)
    func getCurrentEmbeddedProjectId() -> String?
    func resetCurrentEmbeddedProjectId()
}

enum LeapState {
    case live
    case preview
    case creator
}

/// LeapContextManager class acts as the central hub of the Core SDK once the config is downloaded. It invokes the LeapContextDetector class which helps in identifying the current flow, page and stage to be executed. LeapContextManager acts as the delegate to LeapContextDetector receiving information about flow, page and stage and passing it to LeapFlowManager & LeapStageManager.  LeapContextManager also acts as delegate to LeapStageManager, there by understanding if a new stage is identified or the same stage is identified and invoking the AUI SDK . LeapContextManger is also responsible for communicating with LeapAnalyticsManager
class LeapContextManager: NSObject {
    
    private var contextDetector: LeapContextDetector?
    private var assistManager: LeapAssistManager?
    private var discoveryManager: LeapDiscoveryManager?
    private var flowManager: LeapFlowManager?
    private var pageManager: LeapPageManager?
    private var stageManager: LeapStageManager?
    private var analyticsManager: LeapAnalyticsManager?
    private var configManager: LeapConfigManager?
    private weak var analyticsDelegate: LeapAnalyticsDelegate?
    private weak var auiHandler: LeapAUIHandler?
    private weak var delegate: LeapContextManagerDelegate?
    private var taggedEvents: Dictionary<String, Any> = [:]
    
    private var leapState: LeapState = .live
    
    init(with uiHandler: LeapAUIHandler?, configManager: LeapConfigManager) {
        super.init()
        self.auiHandler = uiHandler
        self.configManager = configManager
        self.delegate = configManager
        self.configManager?.delegate = self
    }
    
    /// Methods to setup all managers and setting up their delegates to be this class. After setting up all managers, it calls the start method and starts the context detection
    func initializeLeapEngine() {
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
    
    private func startContextDetection() {
        guard leapState == .live || leapState == .preview else { return }
        contextDetector?.start()
    }
    
    private func isNewConfigTerminated(newConfig: LeapConfig) -> Bool {
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
    
    /// Sets all triggers in trigger manager and starts context detection. By default context detection is in Discovery mode, hence checks all the relevant triggers first to start discovery
    func start() {
        startSoundDownload()
        startContextDetection()
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
        startContextDetection()
    }
    
    @objc func previewNotification(_ notification: NSNotification) {
        leapState = .preview
        contextDetector?.stop()
        guard let previewDict = notification.object as? Dictionary<String,Any> else { return }
        let tempConfig: Array<Dictionary<String, Any>> = {
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
        configManager?.setPreviewConfig(config: LeapConfig(withDict: configDict, isPreview: true)) 
        analyticsManager = nil
        if let state =  contextDetector?.getState(), state == .Stage { contextDetector?.switchState() }
        LeapPreferences.shared.isPreview = true
        startContextDetection()
        startSoundDownload()
    }
    
    @objc func authLiveNotification(_ notification: NSNotification) {
        leapState = .creator
        contextDetector?.stop()
        self.auiHandler?.removeAllViews()
        assistManager?.resetAssistManager()
        discoveryManager?.resetDiscovery()
        flowManager?.resetFlowsArray()
        pageManager?.resetPageManager()
        stageManager?.resetStageManager()
    }
    
    @objc func endPreview() {
        leapState = .live
        contextDetector?.stop()
        if let state =  contextDetector?.getState(), state == .Stage { contextDetector?.switchState() }
        auiHandler?.removeAllViews()
        assistManager?.resetManagerSession()
        discoveryManager?.resetManagerSession()
        flowManager?.resetFlowsArray()
        pageManager?.resetPageManager()
        stageManager?.resetStageManager()
        configManager?.resetPreviewConfig()
        LeapSharedInformation.shared.previewEnded()
        LeapPreferences.shared.isPreview = false
        LeapPreferences.shared.previewUserLanguage = LeapPreferences.shared.getUserLanguage() ?? constant_ang
        analyticsManager = LeapAnalyticsManager(self)
        startContextDetection()
    }
    
    func getProjectParameter() -> LeapProjectParameters? {
        guard let state = contextDetector?.getState() else { return nil }
        switch state {
        case .Discovery:
            if let am = assistManager,
               let assist = am.getCurrentAssist() { return configManager?.currentConfiguration()?.contextProjectParametersDict["assist_\(assist.id)"] }
            else if let dm = discoveryManager,
                    let discovery = dm.getCurrentDiscovery() { return configManager?.currentConfiguration()?.contextProjectParametersDict["discovery_\(discovery.id)"] }
            else { return nil }
            
        case .Stage:
            if let fm = flowManager, let flow = fm.getArrayOfFlows().last, let flowId = flow.id { return configManager?.currentConfiguration()?.contextProjectParametersDict["flow_\(flowId)"] }
        }
        return nil
    }
}

extension LeapContextManager: LeapConfigManagerDelegate {
    
    func resetForProjectId(_ projectId: String) {
        guard leapState == .live else { return }
        let params = configManager?.currentConfiguration()?.projectParameters.first { $0.deploymentId == projectId }
        guard let projParams = params, let id = projParams.id else { return }
        LeapSharedInformation.shared.resetAssist(id, isPreview: configManager?.isPreview() ?? false)
        assistManager?.removeAssistFromCompletedInSession(assistId: id)
        LeapSharedInformation.shared.resetDiscovery(id, isPreview: configManager?.isPreview() ?? false)
        discoveryManager?.removeDiscoveryFromCompletedInSession(disId: id)
    }
    
    func appendProjectConfig(withConfig: LeapConfig, resetProject: Bool) {
       
        let isTerminated: Bool = isNewConfigTerminated(newConfig: withConfig)
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
        startSoundDownload()
    }
    
    func startSubproj(mainProjId: String, subProjId: String) {
        var mainId:String?
        var mainParams:LeapProjectParameters?
        
        var subId:String?
        var subParams:LeapProjectParameters?
        
        guard leapState == .live else { return }
        
        configManager?.currentConfiguration()?.contextProjectParametersDict.forEach({ key, parameters in
            if key.hasPrefix("discovery_") && parameters.deploymentId == mainProjId {
                mainId = key.components(separatedBy: "_")[1]
                mainParams = parameters
            }
            if key.hasPrefix("discovery_") && parameters.deploymentId == subProjId {
                subId = key.components(separatedBy: "_")[1]
                subParams = parameters
            }
        })
        
        guard let mainId = mainId, let mainParams = mainParams, let subId = subId, let subParams = subParams, let flowId = configManager?.getFlowIdFor(projId: subProjId) else { return }
        
        let isMainProjFlowMenu = isFlowMenu(projectParams: mainParams)
        let isSubProjFlowMenu = isFlowMenu(projectParams: subParams)
        
        if !isMainProjFlowMenu || isSubProjFlowMenu { return }
        
        // context detection is stopped
        contextDetector?.stop()
        
        let flowSelected = self.configManager?.currentConfiguration()?.flows.first { $0.id == flowId }
        guard let flow = flowSelected, let _ = flowManager else {
            // context detection is started
            self.startContextDetection()
            return
        }
        if let connectedProjs = configManager?.currentConfiguration()?.connectedProjects {
            for connectedProj in connectedProjs {
                if let connectedProjId = connectedProj[constant_projectId],
                   let deepLinkURL = connectedProj[constant_deepLinkURL],
                   connectedProjId == subProjId, let url = URL(string: deepLinkURL) {
                    UIApplication.shared.open(url)
                    break
                }
            }
        }
        let fmDiscovery = configManager?.currentConfiguration()?.discoveries.first { $0.id == Int(mainId) }
        guard let discovery = fmDiscovery else { return }
        let iconInfo:Dictionary<String,AnyHashable> = discovery.enableIcon ? (configManager?.getIconSettings(discovery.id) ?? [:]) : [:]
        let htmlUrl = discovery.languageOption?[constant_htmlUrl]
        
        auiHandler?.showLanguageOptionsIfApplicable(withLocaleCodes: self.configManager?.generateLangDicts(localeCodes: discovery.localeCodes) ?? [[:]], iconInfo: iconInfo, localeHtmlUrl: htmlUrl, handler: { chosen in
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
            self.startContextDetection()
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
extension LeapContextManager: LeapContextDetectorDelegate {
    
    // MARK: - Identifier Methods
    func getWebIdentifier(identifierId: String) -> LeapWebIdentifier? {
        guard let currentConfiguration = self.configManager?.currentConfiguration() else { return nil }
        return currentConfiguration.webIdentifiers[identifierId]
    }
    
    func getNativeIdentifier(identifierId: String) -> LeapNativeIdentifier? {
        guard let currentConfiguration = self.configManager?.currentConfiguration() else { return nil }
        return currentConfiguration.nativeIdentifiers[identifierId]
    }
    
    func getNativeIdentifierDict() -> [String : LeapNativeIdentifier] {
        guard let currentConfiguration = self.configManager?.currentConfiguration() else { return [:] }
        return currentConfiguration.nativeIdentifiers
    }
    
    func getWebIdentifierDict() -> [String : LeapWebIdentifier] {
        guard let currentConfiguration = self.configManager?.currentConfiguration() else { return [:] }
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
        guard let discoveryId = flowManager?.getDiscoveryId() ?? discoveryManager?.getCurrentDiscovery()?.id, let projParams = self.configManager?.currentConfiguration()?.contextProjectParametersDict["discovery_\(discoveryId)"]
        else { return false }
        let type = projParams.projectType ?? ""
        return type == constant_STATIC_FLOW_CHECKLIST || type == constant_DYNAMIC_FLOW_CHECKLIST || type == constant_STATIC_FLOW_MENU || type == constant_DYNAMIC_FLOW_MENU
    }
    
    func getFlowMenuDiscovery() -> LeapDiscovery? {
        guard let fm = flowManager, let disId = fm.getDiscoveryId() else { return nil }
        let discovery = self.configManager?.currentConfiguration()?.discoveries.first { $0.id == disId }
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
            let iconInfo: Dictionary<String,AnyHashable> = configManager?.getIconSettings(discovery.id) ?? [:]
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
            let iconInfo: Dictionary<String,AnyHashable> = configManager?.getIconSettings(discovery.id) ?? [:]
            auiHandler?.presentLeapButton(for: iconInfo, iconEnabled: discovery.enableIcon)
        } else { auiHandler?.removeAllViews() }
        stageManager?.noStageFound()
    }
}

// MARK: - ASSIST MANAGER DELEGATE METHODS
extension LeapContextManager: LeapAssistManagerDelegate {
    
    func getAllAssists() -> Array<LeapAssist> {
        if leapState == .preview, let preview = configManager?.currentConfiguration() {
            return preview.assists
        }
        guard let config = self.configManager?.currentConfiguration() else { return [] }
        return config.assists
    }
    
    func newAssistIdentified(_ assist: LeapAssist, view: UIView?, rect: CGRect?, inWebview: UIView?) {
        guard let aui = auiHandler, let assistInstructionInfoDict = assist.instructionInfoDict else { return }
        if let currentEmbeddedDeploymentId = delegate?.getCurrentEmbeddedProjectId() {
            var parameters:LeapProjectParameters?
            self.configManager?.currentConfiguration()?.contextProjectParametersDict.forEach({ key, params in
                if params.deploymentId == currentEmbeddedDeploymentId {parameters = params }
            })
            if let currentParameters = parameters,
               let projId = currentParameters.projectId,
               let assistIdFromParams = self.configManager?.currentConfiguration()?.projectContextDict["assist_\(projId)"] {
                if assistIdFromParams != assist.id {
                    configManager?.removeConfigFor(projectId: currentEmbeddedDeploymentId)
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
        let projectParams = self.configManager?.currentConfiguration()?.projectParameters.first { $0.id == id }
        analyticsDelegate?.queue(event: .projectTerminationEvent, for: LeapAnalyticsModel(projectParameter: projectParams, terminationRule: rule))
        LeapSharedInformation.shared.terminationEventSent(discoveryId: nil, assistId: id, isPreview: configManager?.isPreview() ?? false)
    }
}

// MARK: - DISCOVERY MANAGER DELEGATE METHODS
extension LeapContextManager: LeapDiscoveryManagerDelegate {
    
    func isPreview() -> Bool {
        return configManager?.isPreview() ?? false
    }
    
    func getAllDiscoveries() -> Array<LeapDiscovery> {
        if leapState == .preview, let preview = configManager?.currentConfiguration() {
            return preview.discoveries
        }
        guard let config = self.configManager?.currentConfiguration() else { return [] }
        return config.discoveries
    }
    
    func getFlowProjIdsFor(flowIds:Array<Int>) -> Array<String> {
        guard let config = self.configManager?.currentConfiguration() else { return [] }
        let projIds:Array<String> = flowIds.compactMap { flowId -> String? in
            return config.contextProjectParametersDict["flow_\(flowId)"]?.deploymentId
        }
        return projIds
    }
    
    func getProjContextIdDict() -> Dictionary<String, Int> {
        return self.configManager?.currentConfiguration()?.projectContextDict ?? [:]
    }
    
    func getProjParametersDict() -> Dictionary<String, LeapProjectParameters> {
        return self.configManager?.currentConfiguration()?.contextProjectParametersDict ?? [:]
    }
    
    func newDiscoveryIdentified(discovery: LeapDiscovery, view:UIView?, rect:CGRect?, webview:UIView?) {
        guard  let aui = auiHandler, let dm = discoveryManager else { return }
        if let currentEmbeddedDeploymentId = delegate?.getCurrentEmbeddedProjectId() {
            var parameters:LeapProjectParameters?
            self.configManager?.currentConfiguration()?.contextProjectParametersDict.forEach({ key, params in
                if params.deploymentId == currentEmbeddedDeploymentId {parameters = params }
            })
            if let currentParameters = parameters,
               let projId = currentParameters.projectId,
               let discoveryIdFromParams = self.configManager?.currentConfiguration()?.projectContextDict["discovery_\(projId)"] {
                if discoveryIdFromParams != discovery.id {
                    configManager?.removeConfigFor(projectId: currentEmbeddedDeploymentId)
                    delegate?.resetCurrentEmbeddedProjectId()
                }
            }
        }
        guard !dm.isManualTrigger()  else {
            //present leap button
            let iconInfo: Dictionary<String,AnyHashable> = configManager?.getIconSettings(discovery.id) ?? [:]
            aui.presentLeapButton(for: iconInfo, iconEnabled: discovery.enableIcon)
            return
        }
        let htmlUrl = discovery.languageOption?[constant_htmlUrl]
        let iconInfo:Dictionary<String,AnyHashable> = discovery.enableIcon ? (configManager?.getIconSettings(discovery.id) ?? [:]) : [:]
        guard !discovery.autoStart else {
            auiHandler?.showLanguageOptionsIfApplicable(withLocaleCodes: self.configManager?.generateLangDicts(localeCodes: discovery.localeCodes) ?? [[:]], iconInfo: iconInfo, localeHtmlUrl: htmlUrl, handler: { langChose in
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
        
        let localeCode = configManager?.generateLangDicts(localeCodes: discovery.localeCodes) ?? [[:]]
        
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
        let projectParams = self.configManager?.currentConfiguration()?.projectParameters.first { $0.id == id }
        analyticsDelegate?.queue(event: .projectTerminationEvent, for: LeapAnalyticsModel(projectParameter: projectParams, terminationRule: rule))
        LeapSharedInformation.shared.terminationEventSent(discoveryId: id, assistId: nil, isPreview: configManager?.isPreview() ?? false)
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
                return configManager?.getIconSettings(discId) ?? [:]
            }
            let currentDiscovery = self.configManager?.currentConfiguration()?.discoveries.first { $0.id == discId }
            guard let discovery = currentDiscovery, discovery.enableIcon else {return [:] }
            return configManager?.getIconSettings(discId) ?? [:]
        }()
        if iconInfo.isEmpty { auiHandler?.removeAllViews() }
        guard !LeapSharedInformation.shared.isMuted(isPreview: configManager?.isPreview() ?? false), let stageInstructionInfoDict = stage.instructionInfoDict else { return }
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
            LeapSharedInformation.shared.discoveryFlowCompleted(discoveryId: discoveryId, isPreview: configManager?.isPreview() ?? false)
            let flowsCompletedCount = LeapSharedInformation.shared.getDiscoveryFlowCompletedInfo(isPreview: configManager?.isPreview() ?? false)
            let discovery = configManager?.currentConfiguration()?.discoveries.first { $0.id == discoveryId }
            if let currentFlowCompletedCount = flowsCompletedCount["\(discoveryId)"], let perApp = discovery?.terminationfrequency?.perApp, perApp != -1 {
                if currentFlowCompletedCount >= perApp {
                    analyticsDelegate?.queue(event: .projectTerminationEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter(), terminationRule: "After \(perApp) flow completion"))
                }
            }
        }
        if let flowId = flowManager?.getArrayOfFlows().last?.id, let discoveryId = flowManager?.getDiscoveryId() {
            LeapSharedInformation.shared.saveCompletedFlowInfo(flowId,disId: discoveryId, isPreview: configManager?.isPreview() ?? false)
        }
        auiHandler?.removeAllViews()
        flowManager?.popLastFlow()
    }
    
}

extension LeapContextManager {
    
    func validateFlowMenu() -> (isFlowMenu: Bool, projectParams: LeapProjectParameters?) {
        if let discoveryId = flowManager?.getDiscoveryId(), let projectParams = configManager?.currentConfiguration()?.contextProjectParametersDict["discovery_\(discoveryId)"] {
            if isFlowMenu(projectParams: projectParams) {
                return (true, projectParams)
            } else {
                return (false, nil)
            }
        }
        return (false, nil)
    }
    
    func getSubFlowProjectParams() -> LeapProjectParameters? {
        if let discoveryId = flowManager?.getSubId(), let projectParams = configManager?.currentConfiguration()?.contextProjectParametersDict["discovery_\(discoveryId)"] {
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
        guard let config = self.configManager?.currentConfiguration() else { return [:] }
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
        return configManager?.getFlowMenuInfo(discovery: currentDiscovery)
    }
    
    func getWebScript(_ identifier:String) -> String? {
        guard let webId = getWebIdentifier(identifierId: identifier) else { return nil }
        let basicElementScript = LeapJSMaker.generateBasicElementScript(id: webId)
        let focusScript = "(\(basicElementScript)).focus()"
        return focusScript
    }
    
    func getCurrentLanguageOptionsTexts() -> Dictionary<String,String> {
        let langCode = getLanguageCode()
        let lang = self.configManager?.currentConfiguration()?.languages.first{ $0.localeId == langCode }
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
    
    func getLanguagesForCurrentInstruction() -> Array<Dictionary<String, String>> {
        guard let discovery = getLiveDiscovery() else { return [] }
        return configManager?.generateLangDicts(localeCodes: discovery.localeCodes) ?? [[:]]
    }
    
    func getIconInfoForCurrentInstruction() -> Dictionary<String,Any>? {
        guard let discovery = getLiveDiscovery() else { return nil }
        return configManager?.getIconSettings(discovery.id) ?? [:]
    }
    
    func getLanguageHtmlUrl() -> String? {
        guard let discovery = getLiveDiscovery() else { return nil }
        return discovery.languageOption?[constant_htmlUrl]
    }
    
    func getLanguageCode() -> String {
        if let code = LeapPreferences.shared.getUserLanguage() { return code }
        if let firstLanguage = self.configManager?.currentConfiguration()?.languages.first { return firstLanguage.localeId }
        return "ang"
    }
    
    func getTTSCodeFor(code:String) -> String? {
        let lang = self.configManager?.currentConfiguration()?.languages.first { $0.localeId == code }
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
                if let disId = flowManager?.getDiscoveryId() { LeapSharedInformation.shared.muteDisovery(disId,isPreview: configManager?.isPreview() ?? false) }
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
            startContextDetection()
            
        }
    }
    
    func optionPanelStopClicked() {
        // Flow Stop event
        self.analyticsDelegate?.queue(event: .flowStopEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter(), currentStage: stageManager?.getCurrentStage(), currentPage: pageManager?.getCurrentPage()))
        guard let dis = getLiveDiscovery() else {
            startContextDetection()
            return
        }
        LeapSharedInformation.shared.muteDisovery(dis.id, isPreview: configManager?.isPreview() ?? false)
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
                LeapSharedInformation.shared.terminateDiscovery(discoveryId, isPreview: configManager?.isPreview() ?? false)
                discoveryManager?.resetDiscovery()
            }
            return
        }
        guard let discoveryId = flowManager?.getDiscoveryId() else { return }
        LeapSharedInformation.shared.terminateDiscovery(discoveryId, isPreview: configManager?.isPreview() ?? false)
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
                    self.startContextDetection()
                    return
                }
                if let assist = liveContext as? LeapAssist, config.assists.contains(assist) {
                    self.contextDetector?.stop()
                    self.startContextDetection()
                } else if let discovery = liveContext as? LeapDiscovery, config.discoveries.contains(discovery) {
                    self.contextDetector?.stop()
                    self.startContextDetection()
                } else {
                    self.auiHandler?.removeAllViews()
                    self.contextDetector?.stop()
                    self.resetAllManagers()
                    self.startContextDetection()
                }
            case .Stage:
                guard let flow = self.flowManager?.getArrayOfFlows().last,
                      config.flows.contains(flow) else {
                    self.contextDetector?.stop()
                    self.auiHandler?.removeAllViews()
                    self.contextDetector?.switchState()
                    self.resetAllManagers()
                    self.startContextDetection()
                    return
                }
                self.contextDetector?.stop()
                self.startContextDetection()
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
        
        LeapSharedInformation.shared.unmuteDiscovery(liveDiscovery.id, isPreview: configManager?.isPreview() ?? false)
        let iconInfo:Dictionary<String,AnyHashable> = liveDiscovery.enableIcon ? (configManager?.getIconSettings(liveDiscovery.id) ?? [:]) : [:]
        let htmlUrl = liveDiscovery.languageOption?[constant_htmlUrl]
        let langDict = self.configManager?.generateLangDicts(localeCodes: liveDiscovery.localeCodes) ?? [[:]]
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
                auiHandler?.performNativeDiscovery(instruction: liveDiscoveryInstructionInfoDict, view: nil, localeCodes: self.configManager?.generateLangDicts(localeCodes: liveDiscovery.localeCodes) ?? [[:]], iconInfo: iconInfo, localeHtmlUrl: htmlUrl)
            }
            return
        }
    
        guard let nativeDict = configManager?.currentConfiguration()?.nativeIdentifiers,
              let webDict = configManager?.currentConfiguration()?.webIdentifiers,
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
            return configManager?.getFlowIdFor(projId: projId)
        }()
        guard let flowId = flowId else {
            analyticsDelegate?.queue(event: .optOutEvent, for: LeapAnalyticsModel(projectParameter: getProjectParameter()))
            discoveryManager?.discoveryDismissed(byUser: byUser, optIn: false)
            return
        }
        let flowSelected = self.configManager?.currentConfiguration()?.flows.first { $0.id == flowId }
        guard let flow = flowSelected, let fm = flowManager else {
            discoveryManager?.discoveryDismissed(byUser: byUser, optIn: false)
            return
        }
        
        let isFlowMenu = isDiscoveryFlowMenu()
        let subId:Int? = {
            guard let projId = body[constant_projectId] as? String, isFlowMenu else { return nil }
            var parameters:LeapProjectParameters?
            self.configManager?.currentConfiguration()?.contextProjectParametersDict.forEach({ key, params in
                if params.deploymentId == projId && key.hasPrefix("discovery_") { parameters = params }
            })
            guard let selectedParameters = parameters,
                  let projectId = selectedParameters.projectId else { return nil }
            
            let subId = self.configManager?.currentConfiguration()?.projectContextDict["discovery_\(projectId)"]
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
    
    func getLiveDiscovery() -> LeapDiscovery? {
        guard let state = contextDetector?.getState(),
              let disId = state == .Discovery ? discoveryManager?.getCurrentDiscovery()?.id : flowManager?.getDiscoveryId() else { return nil }
        let currentDiscovery = self.configManager?.currentConfiguration()?.discoveries.first{ $0.id == disId }
        return currentDiscovery
    }
    
    func resetAllManagers() {
        self.assistManager?.resetCurrentAssist()
        self.discoveryManager?.resetDiscovery()
        self.flowManager?.resetFlowsArray()
        self.pageManager?.resetPageManager()
        self.stageManager?.resetStageManager()
    }
}
