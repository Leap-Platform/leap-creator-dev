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
    
    
    // MARK: - Assist Methods
    
    func getAllAssistsToCheck() -> Array<JinyAssist> {
        return assistManager?.getAssistsToCheck() ?? []
    }
    
    func assistFound(assist: JinyAssist, view: UIView?, rect: CGRect?, webview: UIView?) {
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
        
    }
}

// MARK: - ASSIST MANAGER DELEGATE METHODS

extension JinyContextManager:JinyAssistManagerDelegate {
    
    func newAssistIdentified(_ assist: JinyAssist, view: UIView?, rect: CGRect?, inWebview: UIView?) {
        
    }
    
    func sameAssistIdentified(view: UIView?, rect: CGRect?, inWebview: UIView?) {
        
    }
    
    func dismissAssist() {
        
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
    }
    
    
}

// MARK: - FLOW MANAGER DELEGATE METHODS
extension JinyContextManager:JinyFlowManagerDelegate {
    
    func noActiveFlows() { contextDetector?.switchState() }
    
}

// MARK: - STAGE MANAGER DELEGATE METHODS
extension JinyContextManager:JinyStageManagerDelegate {
    
    func newPageIdentified(_ page: JinyPage) {
        
    }
    
    func samePageIdentified(_ page: JinyPage) {
        
    }
    
    func newStageFound(_ stage: JinyStage, view: UIView?, rect: CGRect?, webviewForRect:UIView?) {
        
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
    
    func failedToSendPayload(_ payload: Dictionary<String, Any>) {
        
    }
    
    func payloadSend(_ payload: Dictionary<String, Any>) {
        
    }
    
    func incorrectPayload(_ payload: Dictionary<String, Any>) {
        
    }
    
}


extension JinyContextManager:JinyAUICallback {
    
    func getDefaultMedia() -> Dictionary<String, Dictionary<String, Any>> {
        guard let config = configuration else { return [:] }
        return ["default_sounds":config.defaultSounds, "discovery_sounds":config.discoverySounds, "aui_content":config.auiContent]
    }
    
    func triggerEvent(identifier: String, value: Any) {
        
    }
    
    func tryTTS() -> String? {
        if let languagesWithTTS = configuration?.feature?.tts?.languages, let langCode = JinySharedInformation.shared.getLanguage() {
            guard let _ = languagesWithTTS[langCode] else { return nil }
        }
        guard let state = contextDetector?.getState() else { return nil }
        var sound:JinySound?
        switch state {
        case .Discovery:
            if assistManager?.getCurrentAssist() != nil {
                sound = getSoundFor(name: assistManager!.assistToBeTriggered!.instruction!.soundName, langCode: JinySharedInformation.shared.getLanguage() ?? "hin")
            } else if let dis = discoveryManager?.getCurrentDiscovery() {
                sound = getSoundFor(name: dis.instruction!.soundName!, langCode: JinySharedInformation.shared.getLanguage() ?? "hin")
            }
            
        case .Stage:
            sound = getSoundFor(name: (stageManager?.getCurrentStage()!.instruction!.soundName!)!, langCode: JinySharedInformation.shared.getLanguage() ?? "hin")
        }
        return sound?.text
    }
    
    func getAudioFilePath() -> String? {
        
    }
    
    func getTTSText() -> String? {
        
    }
    
    func getLanguages() -> Array<String> {
        
    }
    
    func getLanguageCode() -> String {
        
    }
    
    func willPresentView() {
        
    }
    
    func didPresentView() {
        
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
        
    }
    
    func didReceiveInstruction(dict: Dictionary<String, Any>) {
        
    }
    
    func stagePerformed() {
        
    }
    
    func jinyTapped() {
        
    }
    
    func discoveryPresented() {
        
    }
    
    func discoveryMuted() {
        
    }
    
    func discoveryOptedInFlow(atIndex: Int) {
        
    }
    
    func discoveryReset() {
        
    }
    
    func languagePanelOpened() {
        
    }
    
    func languagePanelClosed() {
        
    }
    
    func languagePanelLanguageSelected(atIndex: Int) {
        
    }
    
    func optionPanelOpened() {
        
    }
    
    func optionPanelClosed() {
        
    }
    
    func optionPanelRepeatClicked() {
        
    }
    
    func optionPanelMuteClicked() {
        
    }

}
