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
    private var assistManager:JinyAssistManager?
    private var discoveryManager:JinyDiscoveryManager?
    private var flowManager:JinyFlowManager?
    private var pageManager:JinyPageManager?
    private var stageManager:JinyStageManager?
    private var analyticsManager:JinyAnalyticsManager?
    private var configuration:JinyConfig?
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
        pageManager = JinyPageManager(self)
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
    func getWebIdentifier(identifierId: String) -> JinyWebIdentifier? {
        return configuration!.webIdentifiers[identifierId]
    }
    
    func getNativeIdentifier(identifierId: String) -> JinyNativeIdentifier? {
        return configuration!.nativeIdentifiers[identifierId]
    }
    
    func getIconSetting() -> Dictionary<String, IconSetting> {
        return configuration!.iconSetting
    }
    
    
    // MARK: - Context Methods
    
    func getContextsToCheck() -> Array<JinyContext> {
        return (assistManager?.getAssistsToCheck() ?? []) + (discoveryManager?.getDiscoveriesToCheck() ?? [])
    }
    
    func getLiveContext() -> JinyContext? {
        if let currentAssist = assistManager?.getCurrentAssist() { return currentAssist }
        else if let currentDiscovery = discoveryManager?.getCurrentDiscovery() { return currentDiscovery }
        return nil
    }
    
    func contextDetected(context: JinyContext, view: UIView?, rect: CGRect?, webview: UIView?) {
        if let assist = context as? JinyAssist {
            discoveryManager?.resetDiscoveryManager()
            assistManager?.triggerAssist(assist, view, rect, webview)
        }
        else if let discovery = context as? JinyDiscovery {
            assistManager?.resetAssistManager()
            discoveryManager?.triggerDiscovery(discovery, view, rect, webview)
        }
    }
    
    func noContextDetected() {
        assistManager?.resetAssistManager()
        discoveryManager?.resetDiscoveryManager()
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
        pageManager?.setCurrentPage(page)
        flowManager?.updateFlowArrayAndResetCounter()
    }
    
    func pageNotIdentified() {
        pageManager?.setCurrentPage(nil)
        stageManager?.resetStageManager()
    }
    
    
    // MARK: - Stage Methods
    func getStagesToCheck() -> Array<JinyStage> {
        return pageManager?.getCurrentPage()?.stages ?? []
    }
    
    func getCurrentStage() -> JinyStage? {
        return stageManager?.getCurrentStage()
    }
    
    func stageIdentified(_ stage: JinyStage, pointerView: UIView?, pointerRect: CGRect?, webviewForRect:UIView?) {
        stageManager?.setCurrentStage(stage, view: pointerView, rect: pointerRect, webviewForRect: webviewForRect)
    }
    
    func stageNotIdentified() {
        stageManager?.resetStageManager()
    }
}

// MARK: - ASSIST MANAGER DELEGATE METHODS
extension JinyContextManager:JinyAssistManagerDelegate {
    
    func newAssistIdentified(_ assist: JinyAssist, view: UIView?, rect: CGRect?, inWebview: UIView?) {
        if let anchorRect = rect {
            auiHandler?.performInstruction(instruction: assist.instructionInfoDict!, rect: anchorRect, inWebview: inWebview, iconInfo: [:])
        } else {
            auiHandler?.performInstruction(instruction: assist.instructionInfoDict!, inView: view, iconInfo: [:])
        }
    }
    
    func sameAssistIdentified(view: UIView?, rect: CGRect?, inWebview: UIView?) {
        if let anchorRect = rect { auiHandler?.updateRect(rect: anchorRect, inWebView: inWebview) }
    }
    
    func dismissAssist() { auiHandler?.removeAllViews() }
    
}

// MARK: - DISCOVERY MANAGER DELEGATE METHODS
extension JinyContextManager:JinyDiscoveryManagerDelegate {
    
    func newDiscoveryIdentified(discovery: JinyDiscovery, view:UIView?, rect:CGRect?, webview:UIView?) {
        guard let dm = discoveryManager else { return }
        guard !dm.isManualTrigger()  else {
            //present jiny button
            return
        }
        let iconInfo = [constant_isLeftAligned: getIconSetting()[String(discovery.id)]?.leftAlign ?? false, constant_isEnabled: discovery.enableIcon, constant_backgroundColor: getIconSetting()[String(discovery.id)]?.bgColor ?? "", constant_htmlUrl: getIconSetting()[String(discovery.id)]?.htmlUrl] as [String : Any?]
        if let anchorRect = rect {
            auiHandler?.performInstruction(instruction: discovery.instructionInfoDict!, rect: anchorRect, inWebview: webview, iconInfo: [:])
        } else {
            auiHandler?.performInstruction(instruction: discovery.instructionInfoDict!, inView: view, iconInfo: iconInfo as Dictionary<String, Any>)
        }
    }
    
    func sameDiscoveryIdentified(discovery: JinyDiscovery, view:UIView?, rect:CGRect?, webview:UIView?) {
        if let anchorRect = rect { auiHandler?.updateRect(rect: anchorRect, inWebView: webview) }
    }
    
    func dismissDiscovery() { auiHandler?.removeAllViews() }
    
}

// MARK: - FLOW MANAGER DELEGATE METHODS
extension JinyContextManager:JinyFlowManagerDelegate {
    
    func noActiveFlows() {
        contextDetector?.switchState()
    }
    
}

// MARK: - PAGE MANAGER DELEGATE METHODS
extension JinyContextManager:JinyPageManagerDelegate {
    func newPageIdentified() {
        sendContextInfoEvent(eventTag: "jinyPageEvent")
    }
}

// MARK: - STAGE MANAGER DELEGATE METHODS
extension JinyContextManager:JinyStageManagerDelegate {
    
    func newStageFound(_ stage: JinyStage, view: UIView?, rect: CGRect?, webviewForRect:UIView?) {
        auiHandler?.presentJinyButton(for: getIconSetting()[String(discoveryManager?.getCurrentDiscovery()?.id ?? -1)] ?? IconSetting(with: [:]), iconEnabled: discoveryManager?.getCurrentDiscovery()?.enableIcon ?? false)
        guard !JinySharedInformation.shared.isMuted() else { return }
        if let anchorRect = rect {
            auiHandler?.performInstruction(instruction: stage.instructionInfoDict!, rect: anchorRect, inWebview: webviewForRect, iconInfo: [:])
        } else {
            auiHandler?.performInstruction(instruction: stage.instructionInfoDict!, inView: view, iconInfo: [:])
        }
        sendContextInfoEvent(eventTag: "jinyInstructionEvent")
    }
    
    func sameStageFound(_ stage: JinyStage, newRect: CGRect?, webviewForRect:UIView?) {
        if let rect = newRect { auiHandler?.updateRect(rect: rect, inWebView: webviewForRect) }
    }
    
    func dismissStage() { auiHandler?.removeAllViews() }
    
    func removeStage(_ stage: JinyStage) { pageManager?.removeStage(stage) }
    
    func isSuccessStagePerformed() {
        if let discoveryId = flowManager?.getDiscoveryId() { JinySharedInformation.shared.discoveryFlowCompleted(discoveryId: discoveryId) }
        auiHandler?.removeAllViews()
        flowManager?.popLastFlow()
    }
    
}

// MARK: - CREATE AND SEND ANALYTICS EVENT
extension JinyContextManager {
    
    func getContextInfoEventFor(eventTag:String) -> JinyAnalyticsEvent? {
        guard let fm = flowManager, let pm = pageManager, let sm = stageManager else { return nil }
        let flowsArray = fm.getArrayOfFlows()
        guard flowsArray.count > 0 else { return nil }
        let mainFlow = flowsArray.count > 1 ? flowsArray[(flowsArray.count - 2)] : flowsArray[(flowsArray.count - 1)]
        let subFlow = flowsArray.count > 1 ? flowsArray[(flowsArray.count - 1)] : nil
        let event = JinyAnalyticsEvent()
        event.jiny_custom_events = JinyCustomEvent(with: eventTag)
        event.jiny_custom_events?.context_info = JinyContextInfo(flow: mainFlow, subFlow: subFlow, page: pm.getCurrentPage(), stage: sm.getCurrentStage())
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
        if let aui = auiHandler,aui.hasClientCallBack() {
            let standardEvent = JinyStandardEvent(withEvent: event)
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            if let eventData = try? jsonEncoder.encode(standardEvent),
               let eventPayload = try? JSONSerialization.jsonObject(with: eventData, options: .mutableContainers) as? Dictionary<String,Dictionary<String,String>>, eventPayload != [:] {
                event.jiny_standard_event = JinyStandardEvent(withEvent: event)
                auiHandler?.sendEvent(event: eventPayload)
            }
        }
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

// MARK: - AUICALLBACK METHODS
extension JinyContextManager:JinyAUICallback {
    
    func getDefaultMedia() -> Dictionary<String, Any> {
        guard let config = configuration else { return [:] }
        return [constant_defaultSounds:config.defaultSounds, constant_discoverySounds:config.discoverySounds, constant_auiContent:config.auiContent, constant_iconSetting:config.iconSetting]
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
            if let am = assistManager, let _ = am.getCurrentAssist() { sendAssistInfoEvent(eventTag: "assistVisibleEvent") }
            else if let dm = discoveryManager, let _ = dm.getCurrentDiscovery() {sendDiscoveryInfoEvent(eventTag: "discoveryVisibleEvent") }
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
    
    func didDismissView(byUser:Bool, autoDismissed:Bool, action:Dictionary<String,Any>?) {
        guard let state = contextDetector?.getState() else { return }
        switch state {
        case .Discovery:
            guard let liveContext = getLiveContext() else { return }
            if let _  = liveContext as? JinyAssist { assistManager?.assistDismissed(byUser: byUser, autoDismissed: autoDismissed) }
            else if let _ = liveContext as? JinyDiscovery {
                if let body = action?["body"] as? Dictionary<String,Any>, let optIn = body["optIn"] as? Bool ?? false {
                    if optIn {
                        sendDiscoveryInfoEvent(eventTag: "discoveryOptInEvent")
                        guard let dm = discoveryManager,
                              let discovery = dm.getCurrentDiscovery(),
                              let flowId = discovery.flowId else { return }
                        let flowSelected = configuration?.flows.first { $0.id == flowId }
                        guard let flow = flowSelected, let fm = flowManager else { return }
                        fm.addNewFlow(flow, false, discovery.id)
                        contextDetector?.switchState()
                    }
                    discoveryManager?.discoveryDismissed(byUser: byUser, optIn: optIn)
                } else { discoveryManager?.discoveryDismissed(byUser: true, optIn: false)}
            }
        case .Stage:
            guard let sm = stageManager, let _ = sm.getCurrentStage() else { return }
            sm.stageDismissed(byUser: byUser, autoDismissed:autoDismissed)
        }
    }
    
    func didDismissView() {
        
    }
    
    func didReceiveInstruction(dict: Dictionary<String, Any>) {
        sendContentActionInfoEvent(eventTag: "auiContentInteractionEvent", contentAction: dict, type: dict[constant_type] as? String ?? "action_taken")
        guard let body = dict["body"] as? Dictionary<String,Any>, let optIn = body["optIn"] as? Bool ?? false else { return }
        if optIn {
            sendDiscoveryInfoEvent(eventTag: "discoveryOptInEvent")
            guard let dm = discoveryManager,
                  let discovery = dm.getCurrentDiscovery(),
                  let flowId = discovery.flowId else { return }
            let flowSelected = configuration?.flows.first { $0.id == flowId }
            guard let flow = flowSelected, let fm = flowManager else { return }
            fm.addNewFlow(flow, false, discovery.id)
            contextDetector?.switchState()
        }
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
            break
        case .Stage:
            auiHandler?.presentOptionPanel(mute: "Mute", repeatText: "Repeat", language: "Change Language")
            break
        }
    }
    
    func discoveryPresented() {
        
    }
    
    func discoveryMuted() {
        
    }
    
    func discoveryOptedInFlow(atIndex: Int) {
        
    }
    
    func discoveryReset() {
        
    }
    
    func discoveryDismissed() {
        
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
            assistManager?.resetAssistManager()
        }
        contextDetector?.start()
    }
    
}
