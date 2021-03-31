//
//  LeapContextManager.swift
//  LeapCore
//
//  Created by Aravind GS on 06/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

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
    private weak var auiHandler:LeapAUIHandler?
    private var taggedEvents:Dictionary<String,Any> = [:]
    
    init(withUIHandler uiHandler:LeapAUIHandler?) {
        auiHandler = uiHandler
    }
    
    /// Methods to setup all managers and setting up their delegates to be this class. After setting up all managers, it calls the start method and starts the context detection
    func initialize(withConfig:LeapConfig) {
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
    
    /// Sets all triggers in trigger manager and starts context detection. By default context detection is in Discovery mode, hence checks all the relevant triggers first to start discovery
    func start() {
        startSoundDownload()
        contextDetector?.start()
        NotificationCenter.default.addObserver(self, selector: #selector(authLiveNotification(_:)), name: .init("leap_creator_live"), object: nil)
    }
    
    @objc func authLiveNotification(_ notification:NSNotification) {
        contextDetector?.stop()
        assistManager?.resetAssistManager()
        discoveryManager?.resetDiscovery()
        flowManager?.resetFlowsArray()
        pageManager?.resetPageManager()
        stageManager?.resetStageManager()
    }
    
    func getProjectParameter(withId id: Int) -> LeapProjectParameters? {
        for params in configuration?.projectParameters ?? [] {
            if params.flowId == id {
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
        return configuration!.webIdentifiers[identifierId]
    }
    
    func getNativeIdentifier(identifierId: String) -> LeapNativeIdentifier? {
        return configuration!.nativeIdentifiers[identifierId]
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
        guard let config = configuration else { return [] }
        return config.assists
    }
    
    func newAssistIdentified(_ assist: LeapAssist, view: UIView?, rect: CGRect?, inWebview: UIView?) {
        guard let aui = auiHandler else { return }
        if let anchorRect = rect {
            aui.performWebAssist(instruction: assist.instructionInfoDict!, rect: anchorRect, webview: inWebview, localeCode: assist.localeCode)
        } else {
            aui.performNativeAssist(instruction: assist.instructionInfoDict!, view: view, localeCode: assist.localeCode)

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
        guard let config = configuration else { return [] }
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
        let instruction = discovery.instructionInfoDict!
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
            let currentDiscovery = configuration?.discoveries.first { $0.id == discId }
            guard let discovery = currentDiscovery, discovery.enableIcon else {return [:] }
            return getIconSettings(discId)
        }()
        
        guard !LeapSharedInformation.shared.isMuted() else { return }
        if let anchorRect = rect {
            auiHandler?.performWebStage(instruction: stage.instructionInfoDict!, rect: anchorRect, webview: webviewForRect, iconInfo: iconInfo)
        } else {
            auiHandler?.performNativeStage(instruction: stage.instructionInfoDict!, view: view, iconInfo: iconInfo)
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
    
    func sendTriggerEvent() -> LeapAnalyticsEvent? {
        guard let fm = flowManager else { return nil }
        let flowsArray = fm.getArrayOfFlows()
        guard flowsArray.count > 0 else { return nil }
        let event = LeapAnalyticsEvent()
        let projectParameter = getProjectParameter(withId: (flowsArray.first?.id)!)
        event.deploymentId = projectParameter?.deploymentId
        event.projectId = projectParameter?.projectId
        event.projectName = projectParameter?.projectName
        event.eventName = EventName.triggerEvent.rawValue
        event.language = LeapPreferences.shared.currentLanguage
        return event
    }
    
    func sendOptInEvent() -> LeapAnalyticsEvent? {
        guard let fm = flowManager else { return nil }
        let flowsArray = fm.getArrayOfFlows()
        guard flowsArray.count > 0 else { return nil }
        let event = LeapAnalyticsEvent()
        let projectParameter = getProjectParameter(withId: (flowsArray.first?.id)!)
        event.deploymentId = projectParameter?.deploymentId
        event.projectId = projectParameter?.projectId
        event.projectName = projectParameter?.projectName
        event.eventName = EventName.optInEvent.rawValue
        event.language = LeapPreferences.shared.currentLanguage
        return event
    }
    
    func sendOptOutEvent() -> LeapAnalyticsEvent? {
        guard let fm = flowManager else { return nil }
        let flowsArray = fm.getArrayOfFlows()
        guard flowsArray.count > 0 else { return nil }
        let event = LeapAnalyticsEvent()
        let projectParameter = getProjectParameter(withId: (flowsArray.first?.id)!)
        event.deploymentId = projectParameter?.deploymentId
        event.projectId = projectParameter?.projectId
        event.projectName = projectParameter?.projectName
        event.eventName = EventName.optOutEvent.rawValue
        event.language = LeapPreferences.shared.currentLanguage
        return event
    }
    
    func sendInstructionEvent() -> LeapAnalyticsEvent? {
        guard let fm = flowManager, let sm = stageManager else { return nil }
        let flowsArray = fm.getArrayOfFlows()
        guard flowsArray.count > 0 else { return nil }
        let event = LeapAnalyticsEvent()
        let projectParameter = getProjectParameter(withId: (flowsArray.first?.id)!)
        event.deploymentId = projectParameter?.deploymentId
        event.projectId = projectParameter?.projectId
        event.projectName = projectParameter?.projectName
        event.eventName = EventName.instructionEvent.rawValue
        event.language = LeapPreferences.shared.currentLanguage
        event.instructionName = sm.getCurrentStage()?.name
        return event
    }
    
    func sendAssistInstructionEvent() -> LeapAnalyticsEvent? {
        guard let fm = flowManager else { return nil }
        let flowsArray = fm.getArrayOfFlows()
        guard flowsArray.count > 0 else { return nil }
        let event = LeapAnalyticsEvent()
        let projectParameter = getProjectParameter(withId: (flowsArray.first?.id)!)
        event.deploymentId = projectParameter?.deploymentId
        event.projectId = projectParameter?.projectId
        event.projectName = projectParameter?.projectName
        event.eventName = EventName.instructionEvent.rawValue
        event.language = LeapPreferences.shared.currentLanguage
        event.instructionName = assistManager?.getCurrentAssist()?.name
        return event
    }
    
    func sendFlowSuccessEvent() -> LeapAnalyticsEvent? {
        guard let fm = flowManager else { return nil }
        let flowsArray = fm.getArrayOfFlows()
        guard flowsArray.count > 0 else { return nil }
        let event = LeapAnalyticsEvent()
        let projectParameter = getProjectParameter(withId: (flowsArray.first?.id)!)
        event.deploymentId = projectParameter?.deploymentId
        event.projectId = projectParameter?.projectId
        event.projectName = projectParameter?.projectName
        event.eventName = EventName.flowSuccessEvent.rawValue
        event.language = LeapPreferences.shared.currentLanguage
        return event
    }
    
    func sendFlowStopEvent() -> LeapAnalyticsEvent? {
        guard let fm = flowManager, let pm = pageManager, let sm = stageManager else { return nil }
        let flowsArray = fm.getArrayOfFlows()
        guard flowsArray.count > 0 else { return nil }
        let event = LeapAnalyticsEvent()
        let projectParameter = getProjectParameter(withId: (flowsArray.first?.id)!)
        event.deploymentId = projectParameter?.deploymentId
        event.projectId = projectParameter?.projectId
        event.projectName = projectParameter?.projectName
        event.eventName = EventName.flowStopEvent.rawValue
        event.language = LeapPreferences.shared.currentLanguage
        event.instructionName = sm.getCurrentStage()?.name
        event.pageName = pm.getCurrentPage()?.name
        return event
    }
    
    func sendFlowDisableEvent() -> LeapAnalyticsEvent? {
        guard let fm = flowManager else { return nil }
        let flowsArray = fm.getArrayOfFlows()
        guard flowsArray.count > 0 else { return nil }
        let event = LeapAnalyticsEvent()
        let projectParameter = getProjectParameter(withId: (flowsArray.first?.id)!)
        event.deploymentId = projectParameter?.deploymentId
        event.projectId = projectParameter?.projectId
        event.projectName = projectParameter?.projectName
        event.eventName = EventName.flowDisableEvent.rawValue
        event.language = LeapPreferences.shared.currentLanguage
        return event
    }
    
    func sendLanguageChangeEvent() -> LeapAnalyticsEvent? {
        guard let fm = flowManager else { return nil }
        let flowsArray = fm.getArrayOfFlows()
        guard flowsArray.count > 0 else { return nil }
        let event = LeapAnalyticsEvent()
        let projectParameter = getProjectParameter(withId: (flowsArray.first?.id)!)
        event.deploymentId = projectParameter?.deploymentId
        event.projectId = projectParameter?.projectId
        event.projectName = projectParameter?.projectName
        event.eventName = EventName.languageChangeEvent.rawValue
        event.language = LeapPreferences.shared.currentLanguage
        event.previousLanguage = LeapPreferences.shared.previousLanguage
        return event
    }
    
    func sendAUIActionTrackingEvent(action: Dictionary<String,Any>?) -> LeapAnalyticsEvent? {
        guard let fm = flowManager else { return nil }
        let flowsArray = fm.getArrayOfFlows()
        guard flowsArray.count > 0 else { return nil }
        let event = LeapAnalyticsEvent()
        let projectParameter = getProjectParameter(withId: (flowsArray.first?.id)!)
        event.deploymentId = projectParameter?.deploymentId
        event.projectId = projectParameter?.projectId
        event.projectName = projectParameter?.projectName
        event.eventName = EventName.actionTrackingEvent.rawValue
        print(action)
        if let body = action?[constant_body] as? Dictionary<String, Any> {
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
        }
        return event
    }
    
    func sendLeapSDKDisableEvent() -> LeapAnalyticsEvent? {
        guard let fm = flowManager else { return nil }
        let flowsArray = fm.getArrayOfFlows()
        guard flowsArray.count > 0 else { return nil }
        let event = LeapAnalyticsEvent()
        let projectParameter = getProjectParameter(withId: (flowsArray.first?.id)!)
        event.deploymentId = projectParameter?.deploymentId
        event.projectId = projectParameter?.projectId
        event.projectName = projectParameter?.projectName
        event.eventName = EventName.triggerEvent.rawValue
        return event
    }
}

// MARK: - ANALYTICS MANAGER DELEGATE METHODS
extension LeapContextManager: LeapAnalyticsManagerDelegate {
    
    func getHeaders() -> Dictionary<String, String> {
        return [
            Constants.AnalyticsKeys.xLeapId:UIDevice.current.identifierForVendor?.uuidString ?? "",
            Constants.AnalyticsKeys.xJinyClientId:LeapSharedInformation.shared.getAPIKey(),
            Constants.AnalyticsKeys.contentTypeKey:Constants.AnalyticsKeys.contentTypeValue
        ]
    }
    
    func failedToSendEvents(payload: Array<Dictionary<String, Any>>) {
        
    }
    
    func sendEvents(payload: Array<Dictionary<String, Any>>) {
        
    }
    
    func sendPayload(_ payload: Dictionary<String, Any>) {
        auiHandler?.sendEvent(event: payload)
    }
    
}

// MARK: - AUICALLBACK METHODS
extension LeapContextManager:LeapAUICallback {
    
    func getDefaultMedia() -> Dictionary<String, Any> {
        guard let config = configuration else { return [:] }
        return [constant_discoverySounds:config.discoverySounds, constant_auiContent:config.auiContent, constant_iconSetting:config.iconSetting]
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
        let lang = configuration?.languages.first{ $0.localeId == langCode }
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
        if let firstLanguage = configuration?.languages.first { return firstLanguage.localeId }
        return "ang"
    }
    
    func getTTSCodeFor(code:String) -> String? {
        let lang = configuration?.languages.first{ $0.localeId == code }
        guard let language = lang,
              let ttsInfo = language.ttsInfo,
              let locale = ttsInfo.ttsLocale,
              let region = ttsInfo.ttsRegion else { return nil }
        return "\(locale)-\(region)"
    }
    
    func didPresentView() {
        guard let state = contextDetector?.getState() else { return }
        switch state {
        case .Discovery:
            if let am = assistManager, let _ = am.getCurrentAssist() {
                // assist Instriuction
                analyticsManager?.saveEvent(event: sendAssistInstructionEvent())
            }
            else if let dm = discoveryManager, let _ = dm.getCurrentDiscovery() {
                
               // trigger event
               analyticsManager?.saveEvent(event: sendTriggerEvent())
            }
        case .Stage:
             // stage instruction
            analyticsManager?.saveEvent(event: sendInstructionEvent())
            break
        }
    }
    
    func failedToPerform() {
        
    }
    
    func didDismissView(byUser:Bool, autoDismissed:Bool, panelOpen:Bool, action: Dictionary<String,Any>?) {
        // aui action tracking
        if let action = action {
            analyticsManager?.saveEvent(event: sendAUIActionTrackingEvent(action: action))
        }
        guard let state = contextDetector?.getState() else { return }
        switch state {
        case .Discovery:
            guard let liveContext = getLiveContext() else { return }
            if let _  = liveContext as? LeapAssist { assistManager?.assistDismissed(byUser: byUser, autoDismissed: autoDismissed) }
            else if let _ = liveContext as? LeapDiscovery { handleDiscoveryDismiss(byUser: byUser, action: action) }
        case .Stage:
            guard let sm = stageManager, let stage = sm.getCurrentStage() else { return }
             // Flow success Event
            if stage.isSuccess {
                analyticsManager?.saveEvent(event: sendFlowSuccessEvent())
            }
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
        contextDetector?.start()
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
    
    func didLanguageChangeForAudio() {
        if let previous = LeapPreferences.shared.previousLanguage, let current = LeapPreferences.shared.currentLanguage, previous != current {
           analyticsManager?.saveEvent(event: sendLanguageChangeEvent())
        }
    }
    
    func receiveAUIEvent(action: Dictionary<String, Any>) {
        analyticsManager?.saveEvent(event: sendAUIActionTrackingEvent(action: action))
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
            auiHandler?.performNativeDiscovery(instruction: liveDiscovery.instructionInfoDict!, view: nil, localeCodes: self.generateLangDicts(localeCodes: liveDiscovery.localeCodes), iconInfo: iconInfo, localeHtmlUrl: htmlUrl)
            return
        }
        let isWeb = liveDiscovery.instruction?.assistInfo?.isWeb ?? false
        contextDetector?.getViewOrRect(allView: cd.fetchViewHierarchy(), id: identifier, isWeb: isWeb, targetCheckCompleted: { (view, rect, webview) in
            if let anchorRect = rect {
                self.auiHandler?.performWebDiscovery(instruction: liveDiscovery.instructionInfoDict!, rect: anchorRect, webview: webview, localeCodes: self.generateLangDicts(localeCodes: liveDiscovery.localeCodes), iconInfo: iconInfo, localeHtmlUrl: htmlUrl)
            } else {
                self.auiHandler?.performNativeDiscovery(instruction: liveDiscovery.instructionInfoDict!, view: view, localeCodes: self.generateLangDicts(localeCodes: liveDiscovery.localeCodes), iconInfo: iconInfo, localeHtmlUrl: htmlUrl)
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
        let flowSelected = configuration?.flows.first { $0.id == flowId }
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
        guard let iconInfo = configuration?.iconSetting[String(discoveryId)],
              let iconInfoData = try? jsonEncoder.encode(iconInfo),
              let iconInfoDict = try? JSONSerialization.jsonObject(with: iconInfoData, options: .allowFragments) as? Dictionary<String,AnyHashable> else { return [:] }
        return iconInfoDict
    }
    
    func generateLangDicts(localeCodes:Array<String>?) -> Array<Dictionary<String,String>>{
        guard let codes = localeCodes else { return [] }
        let langDicts = codes.map { (langCode) -> Dictionary<String,String>? in
            let tempLanguage = configuration?.languages.first { $0.localeId == langCode }
            guard let language = tempLanguage else { return nil }
            return ["localeId":language.localeId, "localeName":language.name, "localeScript":language.script]
        }.compactMap { return $0 }
        return langDicts
    }
    
    func getLiveDiscovery() -> LeapDiscovery? {
        guard let state = contextDetector?.getState(),
              let disId = state == .Discovery ? discoveryManager?.getCurrentDiscovery()?.id : flowManager?.getDiscoveryId() else { return nil }
        let currentDiscovery = configuration?.discoveries.first{ $0.id == disId }
        return currentDiscovery
    }
    
}
