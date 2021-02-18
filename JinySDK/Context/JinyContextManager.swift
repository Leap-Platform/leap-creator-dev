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
        stageManager?.noStageFound()
    }
    
    
    // MARK: - Stage Methods
    func getStagesToCheck() -> Array<JinyStage> {
        return stageManager?.getStagesToCheck() ?? []
    }
    
    func getCurrentStage() -> JinyStage? {
        return stageManager?.getCurrentStage()
    }
    
    func stageIdentified(_ stage: JinyStage, pointerView: UIView?, pointerRect: CGRect?, webviewForRect:UIView?) {
        stageManager?.setCurrentStage(stage, view: pointerView, rect: pointerRect, webviewForRect: webviewForRect)
    }
    
    func stageNotIdentified() {
        stageManager?.noStageFound()
    }
}

// MARK: - ASSIST MANAGER DELEGATE METHODS
extension JinyContextManager:JinyAssistManagerDelegate {
    
    func getAllAssists() -> Array<JinyAssist> {
        guard let config = configuration else { return [] }
        return config.assists
    }
    
    func newAssistIdentified(_ assist: JinyAssist, view: UIView?, rect: CGRect?, inWebview: UIView?) {
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
extension JinyContextManager:JinyDiscoveryManagerDelegate {
    
    func getAllDiscoveries() -> Array<JinyDiscovery> {
        guard let config = configuration else { return [] }
        return config.discoveries
    }
    
    func newDiscoveryIdentified(discovery: JinyDiscovery, view:UIView?, rect:CGRect?, webview:UIView?) {
        guard  let aui = auiHandler, let dm = discoveryManager else { return }
        guard !dm.isManualTrigger()  else {
            //present jiny button
            aui.presentJinyButton(for: configuration!.iconSetting[String(discovery.id)] ?? IconSetting(with: [:]), iconEnabled: discovery.enableIcon)
            return
        }
        let instruction = discovery.instructionInfoDict!
        let iconInfo:Dictionary<String,Any> = discovery.enableIcon ? getIconSettings(discovery.id) : [:]
        let localeCode = generateLangDicts(localeCodes: discovery.localeCodes)
        let htmlUrl = discovery.languageOption?["htmlUrl"]
        if let anchorRect = rect {
            aui.performWebDiscovery(instruction: instruction, rect: anchorRect, webview: webview, localeCodes: localeCode, iconInfo: iconInfo, localeHtmlUrl: htmlUrl)
        } else {
            aui.performNativeDiscovery(instruction: instruction, view: view, localeCodes: localeCode, iconInfo: iconInfo, localeHtmlUrl: htmlUrl)
        }
    }
    
    func sameDiscoveryIdentified(discovery: JinyDiscovery, view:UIView?, rect:CGRect?, webview:UIView?) {
        if let anchorRect = rect { auiHandler?.updateRect(rect: anchorRect, inWebView: webview) }
        else if let anchorView = view { auiHandler?.updateView(inView: anchorView) }
    }
    
    func dismissDiscovery() { auiHandler?.removeAllViews() }
    
}

// MARK: - FLOW MANAGER DELEGATE METHODS
extension JinyContextManager:JinyFlowManagerDelegate {
    
    func noActiveFlows() {
        pageManager?.resetPageManager()
        stageManager?.resetStageManager()
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
    
    func getCurrentPage() -> JinyPage? {
        return pageManager?.getCurrentPage()
    }
    
    func newStageFound(_ stage: JinyStage, view: UIView?, rect: CGRect?, webviewForRect:UIView?) {
        let iconInfo:Dictionary<String,Any> = {
            guard let fm = flowManager, let discId = fm.getDiscoveryId() else { return [:] }
            let currentDiscovery = configuration?.discoveries.first { $0.id == discId }
            guard let discovery = currentDiscovery, discovery.enableIcon else {return [:] }
            return getIconSettings(discId)
        }()
        
        guard !JinySharedInformation.shared.isMuted() else { return }
        if let anchorRect = rect {
            auiHandler?.performWebStage(instruction: stage.instructionInfoDict!, rect: anchorRect, webview: webviewForRect, iconInfo: iconInfo)
        } else {
            auiHandler?.performNativeStage(instruction: stage.instructionInfoDict!, view: view, iconInfo: iconInfo)
        }
        sendContextInfoEvent(eventTag: "jinyInstructionEvent")
    }
    
    func sameStageFound(_ stage: JinyStage, view:UIView?, newRect: CGRect?, webviewForRect:UIView?) {
        if let rect = newRect { auiHandler?.updateRect(rect: rect, inWebView: webviewForRect) }
        else if let anchorView = view { auiHandler?.updateView(inView: anchorView) }
    }
    
    func dismissStage() { auiHandler?.removeAllViews() }
    
    func removeStage(_ stage: JinyStage) { pageManager?.removeStage(stage) }
    
    func isSuccessStagePerformed() {
        if let discoveryId = flowManager?.getDiscoveryId() {
            JinySharedInformation.shared.discoveryFlowCompleted(discoveryId: discoveryId)
        }
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
        return [constant_discoverySounds:config.discoverySounds, constant_auiContent:config.auiContent, constant_iconSetting:config.iconSetting]
    }
    
    func triggerEvent(identifier: String, value: Any) {
        
    }
    
    func getWebScript(_ identifier:String) -> String? {
        guard let webId = getWebIdentifier(identifierId: identifier) else { return nil }
        let basicElementScript = JinyJSMaker.generateBasicElementScript(id: webId)
        let focusScript = "(\(basicElementScript)).focus()"
        return focusScript
    }
    
    func getCurrentLanguageOptionsTexts() -> Dictionary<String,String> {
        let langCode = getLanguageCode()
        let lang = configuration?.languages.first{ $0.localeId == langCode }
        guard let language = lang else { return [constant_stop:"Stop", constant_language:"Language"] }
        let stopText = language.muteText
        let languageText = language.changeLanguageText
        return [constant_stop:stopText, constant_language:languageText]
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
        if let code = JinyPreferences.shared.getUserLanguage() { return code }
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
            if let am = assistManager, let _ = am.getCurrentAssist() { sendAssistInfoEvent(eventTag: "assistVisibleEvent") }
            else if let dm = discoveryManager, let _ = dm.getCurrentDiscovery() {sendDiscoveryInfoEvent(eventTag: "discoveryVisibleEvent") }
        case .Stage:
            
            break
        }
    }
    
    func failedToPerform() {
        
    }
    
    func didDismissView(byUser:Bool, autoDismissed:Bool, panelOpen:Bool, action:Dictionary<String,Any>?) {
        guard let state = contextDetector?.getState() else { return }
        switch state {
        case .Discovery:
            guard let liveContext = getLiveContext() else { return }
            if let _  = liveContext as? JinyAssist { assistManager?.assistDismissed(byUser: byUser, autoDismissed: autoDismissed) }
            else if let _ = liveContext as? JinyDiscovery { handleDiscoveryDismiss(byUser: byUser, action: action) }
        case .Stage:
            guard let sm = stageManager, let _ = sm.getCurrentStage() else { return }
            var endFlow = false
            if let body = action?[constant_body] as? Dictionary<String, Any> { endFlow = body["endFlow"] as? Bool ?? false }
            if endFlow {
                if let disId = flowManager?.getDiscoveryId() { JinySharedInformation.shared.muteDisovery(disId) }
                flowManager?.resetFlowsArray()
                pageManager?.resetPageManager()
                stageManager?.resetStageManager()
                contextDetector?.switchState()
            }
            sm.stageDismissed(byUser: byUser, autoDismissed:autoDismissed)
        }
    }
    
    func jinyTapped() {
        sendContextInfoEvent(eventTag: "jinyIconClickedEvent")
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
        JinySharedInformation.shared.muteDisovery(dis.id)
        flowManager?.resetFlowsArray()
        pageManager?.resetPageManager()
        stageManager?.resetStageManager()
        discoveryManager?.resetDiscoveryManager()
        if let state = contextDetector?.getState(), state == .Stage { contextDetector?.switchState() }
        contextDetector?.start()
    }
    
    func optionPanelOpened() {
        stageManager?.resetCurrentStage()
        contextDetector?.stop()
    }
    
    func optionPanelClosed() {
        sendContextInfoEvent(eventTag: "crossClickedFromPanelEvent")
        contextDetector?.start()
    }
    
    func disableAssistance() {
        contextDetector?.stop()
    }
    
}

// MARK: - ADDITIONAL METHODS
extension JinyContextManager {
    
    func manuallyTriggerCurrentDiscovery() {
        guard let dm = discoveryManager,
              let liveDiscovery = dm.getCurrentDiscovery(),
              let cd = contextDetector else { return }
        JinySharedInformation.shared.unmuteDiscovery(liveDiscovery.id)
        let iconInfo:Dictionary<String,Any> = liveDiscovery.enableIcon ? getIconSettings(liveDiscovery.id) : [:]
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
            discoveryManager?.discoveryDismissed(byUser: byUser, optIn: false)
            return
        }
        let flowSelected = configuration?.flows.first { $0.id == flowId }
        guard let flow = flowSelected, let fm = flowManager else {
            discoveryManager?.discoveryDismissed(byUser: byUser, optIn: false)
            return
        }
        sendDiscoveryInfoEvent(eventTag: "discoveryOptInEvent")
        fm.addNewFlow(flow, false, discovery.id)
        contextDetector?.switchState()
        discoveryManager?.discoveryDismissed(byUser: true, optIn: true)
    }
    
    func getIconSettings(_ discoveryId:Int) -> Dictionary<String,Any> {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        guard let iconInfo = configuration?.iconSetting[String(discoveryId)],
              let iconInfoData = try? jsonEncoder.encode(iconInfo),
              let iconInfoDict = try? JSONSerialization.jsonObject(with: iconInfoData, options: .allowFragments) as? Dictionary<String,Any> else { return [:] }
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
    
    func getLiveDiscovery() -> JinyDiscovery? {
        guard let state = contextDetector?.getState(),
              let disId = state == .Discovery ? discoveryManager?.getCurrentDiscovery()?.id : flowManager?.getDiscoveryId() else { return nil }
        let currentDiscovery = configuration?.discoveries.first{ $0.id == disId }
        return currentDiscovery
    }
    
}
