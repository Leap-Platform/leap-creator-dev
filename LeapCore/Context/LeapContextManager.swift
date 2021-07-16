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
    func fetchUpdatedConfig(config:@escaping(_ :LeapConfig?)->Void)
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
    private var configuration:LeapConfig?
    private var previewConfig: LeapConfig?
    private var previewSounds:Dictionary<String,Any>?
    private weak var auiHandler:LeapAUIHandler?
    public weak var delegate:LeapContextManagerDelegate?
    private var taggedEvents:Dictionary<String,Any> = [:]
    private var lastEventId: String?
    private var lastEventLanguage: String?
    private var isInitialized:Bool = false
    
    init(withUIHandler uiHandler:LeapAUIHandler?) {
        auiHandler = uiHandler
    }
    
    /// Methods to setup all managers and setting up their delegates to be this class. After setting up all managers, it calls the start method and starts the context detection
    func initialize(withConfig:LeapConfig) {
        if isInitialized {
            appendProjectConfig(withConfig: withConfig, resetProject: false)
        } else {
            isInitialized = true
            configuration = withConfig
            contextDetector = LeapContextDetector(withDelegate: self)
            assistManager = LeapAssistManager(self)
            discoveryManager = LeapDiscoveryManager(self)
            flowManager = LeapFlowManager(self)
            pageManager = LeapPageManager(self)
            stageManager = LeapStageManager(self)
            analyticsManager = LeapAnalyticsManager(self)
            self.start()
        }
        
    }
    
    func appendProjectConfig(withConfig:LeapConfig, resetProject:Bool) {
        if resetProject {
            for assist in withConfig.assists {
                LeapSharedInformation.shared.resetAssist(assist.id)
            }
            for discovery in withConfig.discoveries {
                LeapSharedInformation.shared.resetDiscovery(discovery.id)
            }
        }
        if isInitialized {
            contextDetector?.stop()
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
            //Append config
            if configuration == nil { configuration = withConfig }
            else { appendNewProjectConfig(projectConfig: withConfig) }
            contextDetector?.start()
        } else {
            initialize(withConfig: withConfig)
        }
       
        
    }
    
    private func appendNewProjectConfig(projectConfig:LeapConfig) {
        
        configuration?.projectParameters.append(contentsOf: projectConfig.projectParameters)
        
        projectConfig.nativeIdentifiers.forEach { (key, value) in
            configuration?.nativeIdentifiers[key] = value
        }
        
        projectConfig.webIdentifiers.forEach { (key, value) in
            configuration?.webIdentifiers[key] = value
        }
        for assist in projectConfig.assists {
            if !(configuration?.assists.contains(assist))! { configuration?.assists.append(assist) }
        }
        
        for discovery in projectConfig.discoveries {
            if !(configuration?.discoveries.contains(discovery))! { configuration?.discoveries.append(discovery) }
        }
        
        for flow in projectConfig.flows {
            if !(configuration?.flows.contains(flow))! { configuration?.flows.append(flow) }
        }
        
        configuration?.supportedAppLocales = Array(Set(configuration?.supportedAppLocales ?? [] + projectConfig.supportedAppLocales))
        configuration?.discoverySounds += projectConfig.discoverySounds
        configuration?.auiContent += projectConfig.auiContent
        projectConfig.iconSetting.forEach { (key, value) in
            configuration?.iconSetting[key] = value
        }
        configuration?.languages += projectConfig.languages.compactMap({ lang -> LeapLanguage? in
            guard let presentLanguages = configuration?.languages,
                  !presentLanguages.contains(lang) else { return nil }
            return lang
        })
        auiHandler?.startMediaFetch()
    }
    
    /// Sets all triggers in trigger manager and starts context detection. By default context detection is in Discovery mode, hence checks all the relevant triggers first to start discovery
    func start() {
        startSoundDownload()
        contextDetector?.start()
        NotificationCenter.default.addObserver(self, selector: #selector(authLiveNotification(_:)), name: .init("leap_creator_live"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(previewNotification(_:)), name: .init("leap_preview_config"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(endPreview), name: .init("leap_end_preview"), object: nil)
    }
    
    @objc func previewNotification(_ notification:NSNotification) {
        contextDetector?.stop()
        guard let previewDict = notification.object as? Dictionary<String,Any> else { return }
        let tempConfig = previewDict["config"] as? Dictionary<String,Any>
        let configDict = ["data":[tempConfig]]
        assistManager?.resetManagerSession()
        discoveryManager?.resetManagerSession()
        flowManager?.resetFlowsArray()
        pageManager?.resetPageManager()
        stageManager?.resetStageManager()
        auiHandler?.removeAllViews()
        previewConfig = LeapConfig(withDict: configDict, isPreview: true)
        analyticsManager = nil
        previewSounds = previewDict["localeSounds"] as? Dictionary<String,Any>
        if let state =  contextDetector?.getState(), state == .Stage { contextDetector?.switchState() }
        contextDetector?.start()
        auiHandler?.startMediaFetch()
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
        previewSounds = nil
        previewConfig = nil
        analyticsManager = LeapAnalyticsManager(self)
        contextDetector?.start()
    }
    
    func getProjectParameter() -> LeapProjectParameters? {
        let id: Int? = {
            guard let state = contextDetector?.getState() else { return nil }
            switch state {
            case .Discovery:
                if let am = assistManager,
                   let assist = am.getCurrentAssist() { return assist.id }
                else if let dm = discoveryManager,
                        let discovery = dm.getCurrentDiscovery() { return discovery.id }
                else { return nil }
                
            case .Stage:
                if let fm = flowManager { return fm.getDiscoveryId()}
            }
            return nil
        }()
        
        for params in self.currentConfiguration()?.projectParameters ?? [] {
            if params.id == id {
                return params
            }
        }
        return nil
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
        assistManager?.resetAssistManager()
        discoveryManager?.resetDiscoveryManager()
    }
    
    // MARK: - Flow Methods
    func getCurrentFlow() -> LeapFlow? {
        return flowManager?.getRelevantFlow(lookForParent: false)
    }
    
    func getParentFlow() -> LeapFlow? {
        return flowManager?.getRelevantFlow(lookForParent: true)
    }
    
    // MARK: - Page Methods
    func pageIdentified(_ page: LeapPage) {
        pageManager?.setCurrentPage(page)
        flowManager?.updateFlowArrayAndResetCounter()
    }
    
    func pageNotIdentified() {
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
    
    func stageIdentified(_ stage: LeapStage, pointerView: UIView?, pointerRect: CGRect?, webviewForRect:UIView?) {
        stageManager?.setCurrentStage(stage, view: pointerView, rect: pointerRect, webviewForRect: webviewForRect)
    }
    
    func stageNotIdentified() {
        stageManager?.noStageFound()
    }
}

// MARK: - ASSIST MANAGER DELEGATE METHODS
extension LeapContextManager:LeapAssistManagerDelegate {
    
    func getAllAssists() -> Array<LeapAssist> {
        if let preview = previewConfig {
            return preview.assists
        }
        guard let config = self.currentConfiguration() else { return [] }
        return config.assists
    }
    
    func newAssistIdentified(_ assist: LeapAssist, view: UIView?, rect: CGRect?, inWebview: UIView?) {
        guard let aui = auiHandler, let assistInstructionInfoDict = assist.instructionInfoDict else { return }
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
    
}

// MARK: - DISCOVERY MANAGER DELEGATE METHODS
extension LeapContextManager:LeapDiscoveryManagerDelegate {
    
    func getAllDiscoveries() -> Array<LeapDiscovery> {
        if let preview = previewConfig {
            return preview.discoveries
        }
        guard let config = self.currentConfiguration() else { return [] }
        return config.discoveries
    }
    
    func newDiscoveryIdentified(discovery: LeapDiscovery, view:UIView?, rect:CGRect?, webview:UIView?) {
        guard  let aui = auiHandler, let dm = discoveryManager else { return }
        guard !dm.isManualTrigger()  else {
            //present leap button
            let iconInfo:Dictionary<String,AnyHashable> = getIconSettings(discovery.id)
            aui.presentLeapButton(for: iconInfo, iconEnabled: discovery.enableIcon)
            return
        }
        guard let instruction = discovery.instructionInfoDict else { return }
        let iconInfo:Dictionary<String,AnyHashable> = discovery.enableIcon ? getIconSettings(discovery.id) : [:]
        let localeCode = generateLangDicts(localeCodes: discovery.localeCodes)
        let htmlUrl = discovery.languageOption?[constant_htmlUrl]
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
    
}

// MARK: - FLOW MANAGER DELEGATE METHODS
extension LeapContextManager:LeapFlowManagerDelegate {
    
    func noActiveFlows() {
        pageManager?.resetPageManager()
        stageManager?.resetStageManager()
        contextDetector?.switchState()
    }
    
}

// MARK: - PAGE MANAGER DELEGATE METHODS
extension LeapContextManager:LeapPageManagerDelegate {
    func newPageIdentified() {
        //        sendContextInfoEvent(eventTag: "leapPageEvent")
    }
}

// MARK: - STAGE MANAGER DELEGATE METHODS
extension LeapContextManager:LeapStageManagerDelegate {
    
    func getCurrentPage() -> LeapPage? {
        return pageManager?.getCurrentPage()
    }
    
    func newStageFound(_ stage: LeapStage, view: UIView?, rect: CGRect?, webviewForRect:UIView?) {
        let iconInfo:Dictionary<String,AnyHashable> = {
            guard let fm = flowManager, let discId = fm.getDiscoveryId() else { return [:] }
            let currentDiscovery = self.currentConfiguration()?.discoveries.first { $0.id == discId }
            guard let discovery = currentDiscovery, discovery.enableIcon else {return [:] }
            return getIconSettings(discId)
        }()
        
        guard !LeapSharedInformation.shared.isMuted(), let stageInstructionInfoDict = stage.instructionInfoDict else { return }
        if let anchorRect = rect {
            auiHandler?.performWebStage(instruction: stageInstructionInfoDict, rect: anchorRect, webview: webviewForRect, iconInfo: iconInfo)
        } else {
            auiHandler?.performNativeStage(instruction: stageInstructionInfoDict, view: view, iconInfo: iconInfo)
        }
        //sendContextInfoEvent(eventTag: "leapInstructionEvent")
    }
    
    func sameStageFound(_ stage: LeapStage, view:UIView?, newRect: CGRect?, webviewForRect:UIView?) {
        if let rect = newRect { auiHandler?.updateRect(rect: rect, inWebView: webviewForRect) }
        else if let anchorView = view { auiHandler?.updateView(inView: anchorView) }
    }
    
    func dismissStage() { auiHandler?.removeAllViews() }
    
    func removeStage(_ stage: LeapStage) { pageManager?.removeStage(stage) }
    
    func isSuccessStagePerformed() {
        if let discoveryId = flowManager?.getDiscoveryId() {
            LeapSharedInformation.shared.discoveryFlowCompleted(discoveryId: discoveryId)
        }
        auiHandler?.removeAllViews()
        flowManager?.popLastFlow()
    }
    
}

// MARK: - CREATE AND SEND ANALYTICS EVENT
extension LeapContextManager {
    
    func sendStartScreenEvent(instructionId: String) -> LeapAnalyticsEvent? {
        guard let projectParameter = getProjectParameter() else { return nil }
        if lastEventId == instructionId && lastEventLanguage == LeapPreferences.shared.getUserLanguage() {
            return nil
        }
        let event = LeapAnalyticsEvent(withEvent: EventName.startScreenEvent, withParams: projectParameter)
        lastEventId = instructionId
        lastEventLanguage = event.language
        print("start screen")
        return event
    }
    
    func sendOptInEvent() -> LeapAnalyticsEvent? {
        guard let projectParameter = getProjectParameter() else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.optInEvent, withParams: projectParameter)
        print("Opt in")
        return event
    }
    
    func sendOptOutEvent() -> LeapAnalyticsEvent? {
        guard let projectParameter = getProjectParameter() else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.optOutEvent, withParams: projectParameter)
        lastEventId = nil
        print("Opt out")
        return event
    }
    
    func sendInstructionEvent(instructionId: String) -> LeapAnalyticsEvent? {
        guard let projectParameter = getProjectParameter() else { return nil }
        if lastEventId == instructionId && lastEventLanguage == LeapPreferences.shared.getUserLanguage() {
            return nil
        }
        let event = LeapAnalyticsEvent(withEvent: EventName.instructionEvent, withParams: projectParameter)
        lastEventId = instructionId
        lastEventLanguage = event.language
        event.elementName = stageManager?.getCurrentStage()?.name
        event.pageName = pageManager?.getCurrentPage()?.name
        print("element seen")
        return event
    }
    
    func sendAssistInstructionEvent(instructionId: String) -> LeapAnalyticsEvent? {
        guard let projectParameter = getProjectParameter() else { return nil }
        if lastEventId == instructionId && lastEventLanguage == LeapPreferences.shared.getUserLanguage() {
            return nil
        }
        let event = LeapAnalyticsEvent(withEvent: EventName.instructionEvent, withParams: projectParameter)
        lastEventId = instructionId
        lastEventLanguage = event.language
        event.elementName = assistManager?.getCurrentAssist()?.name
        print("assist element seen")
        return event
    }
    
    func sendFlowSuccessEvent() -> LeapAnalyticsEvent? {
        guard let projectParameter = getProjectParameter() else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.flowSuccessEvent, withParams: projectParameter)
        print("flow success")
        return event
    }
    
    func sendFlowStopEvent() -> LeapAnalyticsEvent? {
        guard let projectParameter = getProjectParameter() else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.flowStopEvent, withParams: projectParameter)
        event.elementName = stageManager?.getCurrentStage()?.name
        event.pageName = pageManager?.getCurrentPage()?.name
        print("flow stop")
        return event
    }
    
    func sendFlowDisableEvent() -> LeapAnalyticsEvent? {
        guard let projectParameter = getProjectParameter() else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.flowDisableEvent, withParams: projectParameter)
        print("flow disable")
        return event
    }
    
    func sendLanguageChangeEvent(from previousLanguage: String, to currentLanguage: String) -> LeapAnalyticsEvent? {
        guard let projectParameter = getProjectParameter() else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.languageChangeEvent, withParams: projectParameter)
        event.language = currentLanguage
        event.previousLanguage = previousLanguage
        print("Language change")
        return event
    }
    
    func sendAUIActionTrackingEvent(action: Dictionary<String,Any>?) -> LeapAnalyticsEvent? {
        guard let projectParameter = getProjectParameter() else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.actionTrackingEvent, withParams: projectParameter)
        
        guard let body = action?[constant_body] as? Dictionary<String, Any> else { return nil }
        
        if let id = body[constant_id] as? String {
            
            if lastEventId == id { return nil }
            
            lastEventId = id
        }
        
        if let labelValue = body[constant_buttonLabel] as? String {
            event.actionEventValue = labelValue
        }
        // cases for actionEventType
        if let _ = body[constant_external_link] as? Bool {
            event.actionEventType = constant_external_link
        } else if let _ = body[constant_deep_link] as? Bool {
            event.actionEventType = constant_deep_link
        } else if let _ = body[constant_end_flow] as? Bool {
            event.actionEventType = constant_end_flow
        } else if let _ = body[constant_close] as? Bool {
            event.actionEventType = constant_close
        } else if let _ = body[constant_anchor_click] as? Bool {
            event.actionEventType = constant_anchor_click
            event.actionEventValue = nil
        }
        
        event.elementName = stageManager?.getCurrentStage()?.name ?? assistManager?.getCurrentAssist()?.name
        event.pageName = pageManager?.getCurrentPage()?.name
        
        print("AUI action tracking")
        return event
    }
    
    func sendLeapSDKDisableEvent() -> LeapAnalyticsEvent? {
        guard let projectParameter = getProjectParameter() else { return nil }
        let event = LeapAnalyticsEvent(withEvent: EventName.leapSdkDisableEvent, withParams: projectParameter)
        event.language = nil
        print("Leap SDK disable")
        return event
    }
}

// MARK: - ANALYTICS MANAGER DELEGATE METHODS
extension LeapContextManager: LeapAnalyticsManagerDelegate {
    
    func getHeaders() -> Dictionary<String, String> {
        guard let apiKey = LeapSharedInformation.shared.getAPIKey() else { return [:] }
        return [
            Constants.AnalyticsKeys.xLeapId:UIDevice.current.identifierForVendor?.uuidString ?? "",
            Constants.AnalyticsKeys.xJinyClientId: apiKey,
            Constants.AnalyticsKeys.contentTypeKey:Constants.AnalyticsKeys.contentTypeValue
        ]
    }
    
    func failedToSendEvents(payload: Array<Dictionary<String, Any>>) {
        
    }
    
    func sendEvents(payload: Array<Dictionary<String, Any>>) {
        print("\(payload.count) events sent - \(payload)")
    }
    
    func sendPayload(_ payload: Dictionary<String, Any>) {
        auiHandler?.sendEvent(event: payload)
    }
    
}

// MARK: - AUICALLBACK METHODS
extension LeapContextManager:LeapAUICallback {
    
    func getDefaultMedia() -> Dictionary<String, Any> {
        guard let config = self.currentConfiguration() else { return [:] }
        var initialMedia:Dictionary<String,Any> = [constant_discoverySounds:config.discoverySounds, constant_auiContent:config.auiContent, constant_iconSetting:config.iconSetting]
        if previewSounds != nil { initialMedia[constant_previewSounds] = [previewSounds] }
        return initialMedia
    }
    
    func triggerEvent(identifier: String, value: Any) {
        
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
                analyticsManager?.saveEvent(event: sendAssistInstructionEvent(instructionId: instruction.id))
            }
            else if let dm = discoveryManager, let discovery = dm.getCurrentDiscovery() {
                dm.discoveryPresented()
                // start screen event
                guard let instruction = discovery.instruction else { return }
                analyticsManager?.saveEvent(event: sendStartScreenEvent(instructionId: instruction.id))
            }
        case .Stage:
            // stage instruction
            // TODO: triggered multiple times
            // TODO: Instruction should be triggered once, check id (UUID) and if there is a change in language, can send event again.
            // TODO: - above scenario for start screen and element seen
            guard let sm = stageManager, let stage = sm.getCurrentStage(), let instruction = stage.instruction else { return }
            // Element seen Event
            analyticsManager?.saveEvent(event: sendInstructionEvent(instructionId: instruction.id))
            // Flow success Event
            if stage.isSuccess {
                analyticsManager?.saveEvent(event: sendFlowSuccessEvent())
            }
            break
        }
    }
    
    func failedToPerform() {
        assistManager?.resetCurrentAssist()
        stageManager?.resetCurrentStage()
        discoveryManager?.resetDiscovery()
    }
    
    func didDismissView(byUser:Bool, autoDismissed:Bool, panelOpen:Bool, action: Dictionary<String,Any>?) {
        guard let state = contextDetector?.getState() else { return }
        switch state {
        case .Discovery:
            if let am = assistManager, let _ = am.getCurrentAssist() {
                // aui action tracking
                if let action = action {
                    analyticsManager?.saveEvent(event: sendAUIActionTrackingEvent(action: action))
                }
            }
            guard let liveContext = getLiveContext() else { return }
            if let _  = liveContext as? LeapAssist { assistManager?.assistDismissed(byUser: byUser, autoDismissed: autoDismissed) }
            else if let _ = liveContext as? LeapDiscovery { handleDiscoveryDismiss(byUser: byUser, action: action) }
            
        case .Stage:
            // aui action tracking
            if let action = action {
                analyticsManager?.saveEvent(event: sendAUIActionTrackingEvent(action: action))
            }
            guard let sm = stageManager, let _ = sm.getCurrentStage() else { return }
            
            var endFlow = false
            if let body = action?[constant_body] as? Dictionary<String, Any> { endFlow = body["endFlow"] as? Bool ?? false }
            if endFlow {  // Flow Stop event
                analyticsManager?.saveEvent(event: sendFlowStopEvent())
                if let disId = flowManager?.getDiscoveryId() { LeapSharedInformation.shared.muteDisovery(disId) }
                flowManager?.resetFlowsArray()
                pageManager?.resetPageManager()
                stageManager?.resetStageManager()
                contextDetector?.switchState()
            }
            sm.stageDismissed(byUser: byUser, autoDismissed:autoDismissed)
        }
    }
    
    func leapTapped() {
        //sendContextInfoEvent(eventTag: "leapIconClickedEvent")
        guard let state = contextDetector?.getState() else { return }
        switch state {
        case .Discovery:
            manuallyTriggerCurrentDiscovery()
        case .Stage:
            break
        }
    }
    
    func optionPanelStopClicked() {
        // Flow Stop event
        analyticsManager?.saveEvent(event: sendFlowStopEvent())
        guard let dis = getLiveDiscovery() else {
            contextDetector?.start()
            return
        }
        LeapSharedInformation.shared.muteDisovery(dis.id)
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
        analyticsManager?.saveEvent(event: sendFlowDisableEvent())
        
        guard let state = contextDetector?.getState(), state == .Stage else { return }
        contextDetector?.switchState()
        guard let discoveryId = flowManager?.getDiscoveryId() else { return }
        LeapSharedInformation.shared.terminateDiscovery(discoveryId)
    }
    
    func disableLeapSDK() {
        contextDetector?.stop()
        analyticsManager?.saveEvent(event: sendLeapSDKDisableEvent())
    }
    
    func didLanguageChange(from previousLanguage: String, to currentLanguage: String) {
        if previousLanguage != currentLanguage {
            analyticsManager?.saveEvent(event: sendLanguageChangeEvent(from: previousLanguage, to: currentLanguage))
        }
    }
    
    func receiveAUIEvent(action: Dictionary<String, Any>) {
        analyticsManager?.saveEvent(event: sendAUIActionTrackingEvent(action: action))
    }
    
    func flush() {
        delegate?.fetchUpdatedConfig(config: { (config) in
            DispatchQueue.main.async { self.auiHandler?.startMediaFetch() }
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
}

// MARK: - ADDITIONAL METHODS
extension LeapContextManager {
    
    func manuallyTriggerCurrentDiscovery() {
        guard let dm = discoveryManager,
              let liveDiscovery = dm.getCurrentDiscovery(),
              let cd = contextDetector else { return }
        LeapSharedInformation.shared.unmuteDiscovery(liveDiscovery.id)
        let iconInfo:Dictionary<String,AnyHashable> = liveDiscovery.enableIcon ? getIconSettings(liveDiscovery.id) : [:]
        let htmlUrl = liveDiscovery.languageOption?["htmlUrl"]
        guard let identifier = liveDiscovery.instruction?.assistInfo?.identifier else {
            if let liveDiscoveryInstructionInfoDict = liveDiscovery.instructionInfoDict {
                auiHandler?.performNativeDiscovery(instruction: liveDiscoveryInstructionInfoDict, view: nil, localeCodes: self.generateLangDicts(localeCodes: liveDiscovery.localeCodes), iconInfo: iconInfo, localeHtmlUrl: htmlUrl)
            }
            return
        }
        let isWeb = liveDiscovery.instruction?.assistInfo?.isWeb ?? false
        contextDetector?.getViewOrRect(allView: cd.fetchViewHierarchy(), id: identifier, isWeb: isWeb, targetCheckCompleted: { (view, rect, webview) in
            if let anchorRect = rect {
                if let liveDiscoveryInstructionInfoDict = liveDiscovery.instructionInfoDict {
                    self.auiHandler?.performWebDiscovery(instruction: liveDiscoveryInstructionInfoDict, rect: anchorRect, webview: webview, localeCodes: self.generateLangDicts(localeCodes: liveDiscovery.localeCodes), iconInfo: iconInfo, localeHtmlUrl: htmlUrl)
                }
            } else {
                if let liveDiscoveryInstructionInfoDict = liveDiscovery.instructionInfoDict {
                    self.auiHandler?.performNativeDiscovery(instruction: liveDiscoveryInstructionInfoDict, view: view, localeCodes: self.generateLangDicts(localeCodes: liveDiscovery.localeCodes), iconInfo: iconInfo, localeHtmlUrl: htmlUrl)
                }
            }
        })
    }
    
    func handleDiscoveryDismiss(byUser:Bool, action:Dictionary<String,Any>?) {
        guard let body = action?["body"] as? Dictionary<String,Any>,
              let optIn = body["optIn"] as? Bool, optIn,
              let dm = discoveryManager,
              let discovery = dm.getCurrentDiscovery(),
              let flowId = discovery.flowId else {
            // optOut
            analyticsManager?.saveEvent(event: sendOptOutEvent())
            discoveryManager?.discoveryDismissed(byUser: byUser, optIn: false)
            return
        }
        // optIn
        analyticsManager?.saveEvent(event: sendOptInEvent())
        let flowSelected = self.currentConfiguration()?.flows.first { $0.id == flowId }
        guard let flow = flowSelected, let fm = flowManager else {
            discoveryManager?.discoveryDismissed(byUser: byUser, optIn: false)
            return
        }
        //sendDiscoveryInfoEvent(eventTag: "discoveryOptInEvent")
        fm.addNewFlow(flow, false, discovery.id)
        contextDetector?.switchState()
        discoveryManager?.discoveryDismissed(byUser: true, optIn: true)
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
        self.assistManager?.resetManagerSession()
        self.discoveryManager?.resetManagerSession()
        self.flowManager?.resetFlowsArray()
        self.pageManager?.resetPageManager()
        self.stageManager?.resetStageManager()
    }
    
}
