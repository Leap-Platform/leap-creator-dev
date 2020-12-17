//
//  JinyContextManager.swift
//  JinySDK
//
//  Created by Aravind GS on 06/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

/// JinyContextManager class acts as the central hub of the Core SDK once the config is downloaded. It invokes the JinyContextDetector class which helps in identifying the current flow, page and stage to be executed. JinyContextManager acts as the delegate to JinyContextDetector receiving information about flow, page and stage and passing it to JinyFlowManager & JinyStageManager.  JinyContextManager also acts as delegate to JinyStageManager, there by understanding if a new stage is identified or the same stage is identified and invoking the AUI SDK . JinyContextManger is also responsible for communicating with JinyAnalyticsManager
class JinyContextManager:NSObject {
    
    private var contextDetector:JinyContextDetector?
    private var discoveryManager:JinyDiscoveryManager?
    private var flowManager:JinyFlowManager?
    private var stageManager:JinyStageManager?
    private var analyticsManager:JinyAnalyticsManager?
    private var configuration:JinyConfig?
    private var assistManager:JinyAssistManager?
    private weak var auiHandler:JinyAUIHandler?
    private var taggedEvents:Dictionary<String,Any> = [:]
    
    init(withUIHandler uiHandler:JinyAUIHandler?) {
        auiHandler = uiHandler
    }
    
    /// Methods to setup all managers and setting up their delegates to be this class. After setting up all managers, it calls the start method and starts the context detection
    func initialize(withConfig:JinyConfig) {
        configuration = withConfig
        contextDetector = JinyContextDetector(withDelegate: self)
        assistManager = JinyAssistManager(self)
        discoveryManager = JinyDiscoveryManager(self)
        flowManager = JinyFlowManager(self)
        stageManager = JinyStageManager(self)
        analyticsManager = JinyAnalyticsManager(self)
        self.start()
    }
    
    /// Sets all triggers in trigger manager and starts context detection. By default context detection is in Discovery mode, hence checks all the relevant triggers first to start discovery
    func start() {
        guard let config = configuration else { return }
        let assistsCopy = config.assists.map { (assist) -> JinyAssist in
            return assist.copy()
        }
        assistManager?.setAssistsToCheck(assists: assistsCopy)
        discoveryManager?.setAllDiscoveries(config.discoveries)
        UIApplication.shared.keyWindow?.swizzle()
        startSoundDownload()
        contextDetector?.start()
    }
    
}

// MARK: - SOUND DOWNLOAD INITIATION

extension JinyContextManager {
    func startSoundDownload() {
        guard let aui = auiHandler else { return }
        DispatchQueue.global().async {
            aui.startMediaFetch()
        }
    }
}

// MARK: - CONTEXT DETECTOR DELEGATE METHODS
extension JinyContextManager:JinyContextDetectorDelegate {
    
    // MARK: - Identifier Methods
    
    
    func getAllNativeIds() -> Array<String> {
        return configuration?.nativeIdentifiers.map({ (key, value) -> String in
            return key
        }) ?? []
    }
    
    func getAllWebIds() -> Array<String> {
        return configuration?.webIdentifiers.map({ (key, value) -> String in
            return key
        }) ?? []
    }
    
    func getWebIdentifier(identifierId: String) -> JinyWebIdentifier? {
        return configuration!.webIdentifiers[identifierId]
    }
    
    func getNativeIdentifier(identifierId: String) -> JinyNativeIdentifier? {
        return configuration!.nativeIdentifiers[identifierId]
    }
    
    func getIconSetting() -> Dictionary<String, IconSetting> {
        return configuration!.iconSetting
    }
    
    // MARK: - Assist Methods
    
    func getAllAssistsToCheck() -> Array<JinyAssist> {
        return assistManager?.getAssistsToCheck() ?? []
    }
    
    func assistFound(assist: JinyAssist, view: UIView?, rect: CGRect?, webview: UIView?) {
        discoveryManager?.resetCurrentDiscovery()
        assistManager?.assistIdentified(assist: assist, view: view, rect: rect, webview: webview)
    }
    
    func assistNotFound() {
        assistManager?.noAssistFound()
    }
    
    // MARK: - Discovery Methods
    func getDiscoveriesToCheck() -> Array<JinyDiscovery> {
        return discoveryManager?.getDiscoveriesToCheck() ?? []
    }
    
    
    func discoveriesFound(discoveries: Array<(JinyDiscovery, UIView?, CGRect?, UIView?)>) {
        discoveryManager?.discoveriesFound(discoveries)
    }
    
    func noDiscoveryFound() {
        discoveryManager?.discoveryNotFound()
        
    }
    
    // MARK: - Flow Methods
    func getCurrentFlow() -> JinyFlow? {
        return flowManager?.getRelevantFlow(lookForParent: false)
    }
    
    func getParentFlow() -> JinyFlow? {
        return flowManager?.getRelevantFlow(lookForParent: true)
    }
    
    // MARK: - Page Methods
    func pageIdentified(_ page: JinyPage) {
        stageManager?.setArrayOfStagesFromPage(page.stages)
        stageManager?.setCurrentPage(page)
    }
    
    func pageNotIdentified() {
        stageManager?.setCurrentPage(nil)
        stageManager?.setCurrentStage(nil, view: nil, rect: nil, webviewForRect: nil)
    }
    
    
    // MARK: - Stage Methods
    func getStagesToCheck() -> Array<JinyStage> {
        return stageManager?.getArrayOfStagesToCheck() ?? []
    }
    
    func stageIdentified(_ stage: JinyStage, pointerView: UIView?, pointerRect: CGRect?, webviewForRect:UIView?) {
        stageManager?.setCurrentStage(stage, view: pointerView, rect: pointerRect, webviewForRect: webviewForRect)
    }
    
    func stageNotIdentified() {
        sendContextInfoEvent(eventTag: "jinyPageEvent")
    }
}

// MARK: - ASSIST MANAGER DELEGATE METHODS

extension JinyContextManager:JinyAssistManagerDelegate {
    
    func newAssistIdentified(_ assist: JinyAssist, view: UIView?, rect: CGRect?, inWebview: UIView?) {
        auiHandler?.removeAllViews()
        if let anchorView = view {
            auiHandler?.performInstruction(instruction: assist.instructionInfoDict!, inView: anchorView, iconInfo: [:])
        } else if let anchorRect = rect {
            auiHandler?.performInstrcution(instruction: assist.instructionInfoDict!, rect: anchorRect, inWebview: inWebview, iconInfo: [:])
        }
    }
    
    func sameAssistIdentified(view: UIView?, rect: CGRect?, inWebview: UIView?) {
        
    }
    
    func dismissAssist() {
        auiHandler?.removeAllViews()
    }
    
}


// MARK: - DISCOVERY MANAGER DELEGATE METHODS

extension JinyContextManager:JinyDiscoveryManagerDelegate {
    
    func getMutedDiscoveryIds() -> Array<Int> {
        return JinySharedInformation.shared.getMutedDiscoveryIds()
    }
    
    func addDiscoveryIdToMutedList(id: Int) {
        JinySharedInformation.shared.addToMutedDiscovery(id)
    }
    
    func getTriggeredEvents() -> Dictionary<String, Any> {
        return taggedEvents
    }
    
    func newDiscoveryIdentified(discovery: JinyDiscovery, view:UIView?, rect:CGRect?, webview:UIView?) {
        guard !JinySharedInformation.shared.isMuted() else {
            if discovery.enableIcon {
               auiHandler?.presentJinyButton(with: getIconSetting()[String(discovery.id)]?.htmlUrl, color: getIconSetting()[String(discovery.id)]?.bgColor ?? "#000000")
            }
            return
        }
        auiHandler?.removeAllViews()
        
        let iconInfo = ["isLeftAligned":true, "isEnabled": discovery.enableIcon, "backgroundColor": getIconSetting()[String(discovery.id)]?.bgColor ?? "", "htmlUrl": getIconSetting()[String(discovery.id)]?.htmlUrl] as [String : Any]
        if let anchorView = view {
            auiHandler?.performInstruction(instruction: discovery.instructionInfoDict!, inView: anchorView, iconInfo: iconInfo)
        } else if let anchorRect = rect {
            auiHandler?.performInstrcution(instruction: discovery.instructionInfoDict!, rect: anchorRect, inWebview: webview, iconInfo: [:])
        }
    }
    
    func sameDiscoveryIdentified(discovery: JinyDiscovery, view:UIView?, rect:CGRect?, webview:UIView?) {
        
    }
    
    func noDiscoveryIdentified() {
        
    }
    
    func startFlow(id: Int, disId:Int) {
        let flow = configuration?.flows.first(where: { (flow) -> Bool in
            flow.id! == id
        })
        guard let selectedFlow = flow else { return }
        contextDetector?.switchState()
        JinyEventDetector.shared.delegate = nil
        flowManager?.addNewFlow(selectedFlow.copy(), false, disId)
        contextDetector?.start()
        sendContextInfoEvent(eventTag: "jinyFlowOptInEvent")
    }
    
    func canTriggerBasedOnTriggerFrequency(discovery: JinyDiscovery) -> Bool {
        
        switch discovery.triggerFrequency?.type {
        case .everySession:
            return true
        case .playOnce:
            if (JinySharedInformation.shared.getDiscoveryCount()["\(discovery.id)"] ?? 0) > 0 {
                auiHandler?.removeAllViews()
                return false
            } else {
                return true
            }
        case .manualTrigger:
            if discovery.enableIcon {
               auiHandler?.presentJinyButton(with: getIconSetting()[String(discovery.id)]?.htmlUrl, color: getIconSetting()[String(discovery.id)]?.bgColor ?? "#000000")
            }
                return false
        case .everySessionUntilDismissed:
            if (JinySharedInformation.shared.getDiscoveryDismissCount()["\(discovery.id)"] ?? 0) > 0 {
                auiHandler?.removeAllViews()
                return false
            } else {
                return true
            }
        case .everySessionUntilFlowComplete:
            if (JinySharedInformation.shared.getDiscoveryFlowCount()["\(discovery.id)"] ?? 0) > 0 {
                auiHandler?.removeAllViews()
                return false
            } else {
                return true
            }
        default:
            return true
        }
    }
    
    func showJinyIcon() {
        auiHandler?.removeAllViews()
        if discoveryManager?.getCurrentDiscovery()?.enableIcon ?? false {
        auiHandler?.presentJinyButton(with: getIconSetting()[String(discoveryManager?.getCurrentDiscovery()?.id ?? -1)]?.htmlUrl, color: getIconSetting()[String(discoveryManager?.getCurrentDiscovery()?.id ?? -1)]?.bgColor ?? "#000000")
        }
        discoveryManager?.currentDiscoveryOptOut = false
    }
    
    func removeAllViews() {
        auiHandler?.removeAllViews()
    }
}

// MARK: - FLOW MANAGER DELEGATE METHODS
extension JinyContextManager:JinyFlowManagerDelegate {
    
    func noActiveFlows() { contextDetector?.switchState() }
    
}

// MARK: - STAGE MANAGER DELEGATE METHODS
extension JinyContextManager:JinyStageManagerDelegate {
    
    func newPageIdentified(_ page: JinyPage) {
        sendContextInfoEvent(eventTag: "jinyPageEvent")
    }
    
    func samePageIdentified(_ page: JinyPage) {
        
    }
    
    func newStageFound(_ stage: JinyStage, view: UIView?, rect: CGRect?, webviewForRect:UIView?) {
        auiHandler?.removeAllViews()
        if discoveryManager?.getCurrentDiscovery()?.enableIcon ?? false {
            auiHandler?.presentJinyButton(with: getIconSetting()[String(discoveryManager?.getCurrentDiscovery()?.id ?? -1)]?.htmlUrl, color: getIconSetting()[String(discoveryManager?.getCurrentDiscovery()?.id ?? -1)]?.bgColor ?? "#000000")
        }
        guard !JinySharedInformation.shared.isMuted() else { return }
        let iconInfo = ["isLeftAligned":true, "isEnabled": discoveryManager?.getCurrentDiscovery()?.enableIcon ?? false, "backgroundColor": getIconSetting()[String(discoveryManager?.getCurrentDiscovery()?.id ?? -1)]?.bgColor ?? "", "htmlUrl": getIconSetting()[String(discoveryManager?.getCurrentDiscovery()?.id ?? -1)]?.htmlUrl] as [String : Any]
        if let anchorView = view {
            auiHandler?.performInstruction(instruction: stage.instructionInfoDict!, inView: anchorView, iconInfo: iconInfo)
        } else if let anchorRect = rect {
            auiHandler?.performInstrcution(instruction: stage.instructionInfoDict!, rect: anchorRect, inWebview: webviewForRect, iconInfo: [:])
        } else {
            
            auiHandler?.performInstruction(instruction: stage.instructionInfoDict!)
        }
        sendContextInfoEvent(eventTag: "jinyInstructionEvent")
    }
    
    func sameStageFound(_ stage: JinyStage, newRect: CGRect?, webviewForRect:UIView?) {
        
    }
    
    func noStageFound() {
    }
    
    func removeStage(_ stage: JinyStage) { flowManager?.removeStage(stage) }
    
    func isSuccessStagePerformed() {
        if let discoveryId = flowManager?.getDiscoveryId() {
            JinySharedInformation.shared.flowCompletedFor(discoveryId: discoveryId)
        }
        auiHandler?.removeAllViews()
        flowManager?.popLastFlow()
    }
    
}


// MARK: - CREATE AND SEND ANALYTICS EVENT
extension JinyContextManager {
    
    func getContextInfoEventFor(eventTag:String) -> JinyAnalyticsEvent? {
        guard let fm = flowManager, let sm = stageManager else { return nil }
        let flowsArray = fm.getArrayOfFlows()
        guard flowsArray.count > 0 else { return nil }
        let mainFlow = flowsArray.count > 1 ? flowsArray[(flowsArray.count - 2)] : flowsArray[(flowsArray.count - 1)]
        let subFlow = flowsArray.count > 1 ? flowsArray[(flowsArray.count - 1)] : nil
        let event = JinyAnalyticsEvent()
        event.jiny_custom_events = JinyCustomEvent(with: eventTag)
        event.jiny_custom_events?.context_info = JinyContextInfo(flow: mainFlow, subFlow: subFlow, page: sm.getCurrentPage(), stage: sm.getCurrentStage())
        return event
        
    }
    
    func getDiscoveryInfoEvent(eventTag:String) -> JinyAnalyticsEvent? {
        guard let dm = discoveryManager, let discovery = dm.getCurrentDiscovery() else { return nil }
        let event = JinyAnalyticsEvent()
        event.jiny_custom_events = JinyCustomEvent(with: eventTag)
        event.jiny_custom_events?.discovery_info = JinyDiscoveryInfo(withDiscovery: discovery)
        return event
    }
    
    func getAssistInfoEvent(eventTag:String) -> JinyAnalyticsEvent? {
        guard let am = assistManager, let assist = am.getCurrentAssist() else { return nil }
        let event = JinyAnalyticsEvent()
        event.jiny_custom_events = JinyCustomEvent(with: eventTag)
        event.jiny_custom_events?.assist_info = JinyAssistInfoType(with: assist)
        return event
    }
    
    func sendContextInfoEvent(eventTag:String) {
        guard let contextEvent = getContextInfoEventFor(eventTag: eventTag) else { return }
        sendEvent(event: contextEvent)
    }
    
    func sendContentActionInfoEvent(eventTag:String, contentAction:Dictionary<String,Any>, type:String) {
        guard let contextEvent = getContextInfoEventFor(eventTag: eventTag) else { return }
        contextEvent.jiny_custom_events?.content_action_info = JinyContentActionInfo(with: contentAction, type: type)
        sendEvent(event: contextEvent)
    }
    
    func sendDiscoveryInfoEvent(eventTag:String) {
        guard let discoveryEvent = getDiscoveryInfoEvent(eventTag: eventTag) else { return }
        sendEvent(event: discoveryEvent)
    }
    
    func sendAssistInfoEvent(eventTag:String) {
        guard let assistEvent = getAssistInfoEvent(eventTag: eventTag) else { return }
        sendEvent(event: assistEvent)
    }
    
    func sendEvent(event:JinyAnalyticsEvent) {
        guard let am = analyticsManager else { return }
        am.sendEvent(event)
    }
    
}


// MARK: - ANALYTICS MANAGER DELEGATE METHODS
extension JinyContextManager:JinyAnalyticsManagerDelegate {
    
    func getHeaders() -> Dictionary<String, String> {
        return [
            Constants.AnalyticsTemp.xClientId:Constants.AnalyticsTemp.tempApiKey,
            Constants.AnalyticsTemp.contentTypeKey:Constants.AnalyticsTemp.contentTypeValue,
            "x-experiment-code" : "1"
        ]
    }
    
    
    func failedToSendPayload(_ payload: Dictionary<String, Any>) {
        guard let am = analyticsManager else { return }
        am.saveEvent(payload: payload, isSuccess: false)
    }
    
    func payloadSend(_ payload: Dictionary<String, Any>) {
        
    }
    
    func incorrectPayload(_ payload: Dictionary<String, Any>) {
        
    }
    
    func failedToSendBulkEvents(payload: Array<Dictionary<String, Any>>) {
        guard let am = analyticsManager else { return }
        am.saveEvents(payload: payload)
    }
    
    func sendBulkEvents(payload: Array<Dictionary<String, Any>>) {
        
    }
    
}


extension JinyContextManager:JinyAUICallback {
    
    func getDefaultMedia() -> Dictionary<String, Dictionary<String, Any>> {
        guard let config = configuration else { return [:] }
        return ["default_sounds":config.defaultSounds, "discovery_sounds":config.discoverySounds, "aui_content":config.auiContent, "iconSetting":config.iconSetting]
    }
    
    func triggerEvent(identifier: String, value: Any) {
        
    }
    
    func tryTTS() -> String? {
        return nil
    }
    
    func getAudioFilePath() -> String? {
        return nil
    }
    
    func getTTSText() -> String? {
        return nil
    }
    
    func getLanguages() -> Array<String> {
        return (configuration?.languages.map({ (language) -> String in
            return language.script
        }))!
    }
    
    func getLanguageCode() -> String {
        return JinySharedInformation.shared.getLanguage() ?? "hin"
    }
    
    func willPresentView() {
        
    }
    
    func didPresentView() {
        guard let state = contextDetector?.getState() else { return }
        switch state {
        case .Discovery:
            if let am = assistManager, let _ = am.getCurrentAssist() {
                sendAssistInfoEvent(eventTag: "assistVisibleEvent")
            }
            else if let dm = discoveryManager, let _ = dm.getCurrentDiscovery() {
                sendDiscoveryInfoEvent(eventTag: "discoveryVisibleEvent")
                discoveryPresented()
            }
        case .Stage:
            break
        }
    }
    
    func willPlayAudio() {
        
    }
    
    func didPlayAudio() {
        
    }
    
    func failedToPerform() {
        
    }
    
    func willDismissView() {
        
    }
    
    func didDismissView() {
        
        guard let state = contextDetector?.getState() else { return }
        switch state {
        case .Discovery:
            if let dm = discoveryManager, let _ = dm.getCurrentDiscovery() {
                dm.currentDiscoveryOptOut = true
                discoveryDismissed()
            }
        case .Stage:
            break
        }
    }
    
    func didReceiveInstruction(dict: Dictionary<String, Any>) {
        sendContentActionInfoEvent(eventTag: "auiContentInteractionEvent", contentAction: dict, type: dict["type"] as? String ?? "action_taken")
    }
    
    func stagePerformed() {
        
    }
    
    func jinyTapped() {
        sendContextInfoEvent(eventTag: "jinyIconClickedEvent")
        if JinySharedInformation.shared.isMuted() {
            if contextDetector?.getState() == .Stage {
                flowManager?.resetFlowsArray()
                contextDetector?.switchState()
            }
            JinySharedInformation.shared.unmuteJiny()
        }
        guard let state = contextDetector?.getState() else { return }
        switch state {
        case .Discovery:
            guard let currentDiscoveryObject = discoveryManager?.currentDiscoveryObject, let discovery = discoveryManager?.getCurrentDiscovery() else {
                return
            }
            if canTriggerBasedOnTriggerFrequency(discovery: discovery) || discovery.triggerFrequency?.type == .manualTrigger {
                newDiscoveryIdentified(discovery: currentDiscoveryObject.0, view: currentDiscoveryObject.1, rect: currentDiscoveryObject.2, webview: currentDiscoveryObject.3)
            } else {
               discoveryManager?.resetCurrentDiscovery()
            }
            return
        case .Stage:
            auiHandler?.presentOptionPanel(mute: "Mute", repeatText: "Repeat", language: "Change Language")
            break
        }
    }
    
    func discoveryPresented() {
        if let discoveryManager = discoveryManager {
            discoveryManager.currentDiscoveryPresented()
        }
    }
    
    func discoveryMuted() {
        
    }
    
    func discoveryOptedInFlow(atIndex: Int) {
        sendDiscoveryInfoEvent(eventTag: "discoveryOptInEvent")
        guard let dm = discoveryManager, let disc = dm.getCurrentDiscovery() else { return }
        guard let flowId = disc.flowId else { return }
        startFlow(id: flowId, disId: disc.id)
    }
    
    func discoveryReset() {
        
    }
    
    func discoveryDismissed() {
        if let discoveryManager = discoveryManager {
            discoveryManager.currentDiscoveryDismissed()
        }
    }
    
    func languagePanelOpened() {
        sendContextInfoEvent(eventTag: "changeLangClickedEvent")
    }
    
    func languagePanelClosed() {
        sendContextInfoEvent(eventTag: "crossClickedFromPanelEvent")
    }
    
    func languagePanelLanguageSelected(atIndex: Int) {
        sendContextInfoEvent(eventTag: "langSelectedFromPanelEvent")
        guard let config = configuration else { return }
        let languageSelected = config.languages[atIndex].localeId
        JinySharedInformation.shared.setLanguage(languageSelected)
        auiHandler?.startMediaFetch()
        contextDetector?.start()
        guard let state = contextDetector?.getState(), state == .Stage else { return }
        stageManager?.resetCurrentStage()
    }
    
    func optionPanelOpened() {
        
    }
    
    func optionPanelClosed() {
        sendContextInfoEvent(eventTag: "crossClickedFromPanelEvent")
    }
    
    func optionPanelRepeatClicked() {
        sendContextInfoEvent(eventTag: "repeatClickedEvent")
        contextDetector?.start()
        guard let state = contextDetector?.getState(), state == .Stage else { return }
        stageManager?.resetCurrentStage()
    }
    
    func optionPanelMuteClicked() {
        sendContextInfoEvent(eventTag: "muteClickedEvent")
        if contextDetector?.getState() == .Stage {
            stageManager?.resetCurrentStage()
            JinySharedInformation.shared.muteJiny()
            flowManager?.resetFlowsArray()
            contextDetector?.switchState()
            discoveryManager?.resetCurrentDiscovery()
            assistManager?.noAssistFound()
        }
        contextDetector?.start()
    }
    
}
