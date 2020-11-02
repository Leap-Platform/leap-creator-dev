//
//  JinyContextManager.swift
//  JinySDK
//
//  Created by Aravind GS on 06/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

protocol JinyContextManagerAudioDelegate {
    func getAudioStatus(_ sound:JinySound) -> JinyDownloadStatus?
    func changePriorityForSound(_ sound:JinySound, priority:Operation.QueuePriority)
    func languageChanged()
}

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
    private var keyboardHeight:Float = 0
    private var taggedEvents:Dictionary<String,Any> = [:]
    var audioManagerDelegate:JinyContextManagerAudioDelegate?
    
    init(withUIHandler uiHandler:JinyAUIHandler?) {
        auiHandler = uiHandler
    }
    
    /// Methods to setup all managers and setting up their delegates to be this class. After setting up all managers, it calls the start method and starts the context detection
    func initialize(withConfig:JinyConfig) {
        contextDetector = JinyContextDetector(withDelegate: self)
        configuration = withConfig
        discoveryManager = JinyDiscoveryManager(self)
        flowManager = JinyFlowManager(self)
        stageManager = JinyStageManager(self)
        analyticsManager = JinyAnalyticsManager(self)
        assistManager = JinyAssistManager(self)
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
        return assistManager?.assistsToCheck ?? []
    }
    
    func assistFound(assist: JinyAssist, view: UIView?, rect: CGRect?, webview: UIView?) {
        contextDetector?.substate = .Assist
        assistManager?.assistIdentified(assist: assist, view: view, rect: rect, webview: webview)
    }
    
    func assistNotFound() {
        assistManager?.noAssistFound()
    }
    
    // MARK: - Discovery Methods
    func getDiscoveriesToCheck() -> Array<JinyDiscovery> {
        return discoveryManager?.getDiscoveriesToCheck() ?? []
    }
    
    
    func discoveriesIdentified(discoveries: Array<(JinyDiscovery, UIView?, CGRect?, UIView?)>) {
        contextDetector?.substate = .Discovery
        discoveryManager?.discoveriesFound(discoveries)
    }
    
    func noDiscoveryIdentified() {
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
        updateDownloadPriorityForIdentified(page.stages, .normal)
        
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
    
    func performAssist(_ assist: JinyAssist, view: UIView?, rect: CGRect?, inWebview: UIView?) {
        
        auiHandler?.removeAllViews()
        guard let instruction = assist.instructionInfoDict else { return }
        if let targetView = view {
            auiHandler?.performInstruction(instruction: instruction, inView: targetView)
        } else if let targetRect = rect {
            auiHandler?.performInstrcution(instruction: instruction, rect: targetRect, inWebview: inWebview)
        }
        assistManager?.setCurrentAssist()
        
        let assistEvent = JinyAnalyticsEvent()
        assistEvent.jiny_custom_events = JinyCustomEvent()
        assistEvent.jiny_custom_events?.assist_info = JinyAssistInfoType(with: assist)
        analyticsManager?.sendEvent(assistEvent)
    }
    
    func sameAssistIdentified(view: UIView?, rect: CGRect?, inWebview: UIView?) {
        if let newRect = rect {
            auiHandler?.updateRect(rect: newRect, inWebView: inWebview)
        } else if let sameView = view {
            auiHandler?.updateView(inView: sameView)
        }
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
        
        auiHandler?.removeAllViews()
        discoveryManager?.setDiscovery(discovery)
        guard let instruction = discovery.instructionInfoDict else { return }
        if let targetView = view {
            auiHandler?.performInstruction(instruction: instruction, inView: targetView)
        } else if let targetRect = rect {
            auiHandler?.performInstrcution(instruction: instruction, rect: targetRect, inWebview: webview)
        } else {
            auiHandler?.performInstruction(instruction: instruction)
        }
        let discoveryEvent = JinyAnalyticsEvent()
        discoveryEvent.jiny_custom_events = JinyCustomEvent()
        discoveryEvent.jiny_custom_events?.discovery_info = JinyDiscoveryInfoEvent(withDiscovery: discovery)
        analyticsManager?.sendEvent(discoveryEvent)
    }
    
    func sameDiscoveryIdentified(discovery: JinyDiscovery, view:UIView?, rect:CGRect?, webview:UIView?) {
        
    }
    
    func noContextualDiscoveryIdentified() {
        auiHandler?.removeAllViews()
        //        noContextIdentfied()
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
        
        guard let fm = flowManager else { return }
        var mainFlow:JinyFlow?
        var subFlow:JinyFlow?
        let flowsArray = fm.getFlowsToCheck()
        if flowsArray.count > 1 {
            subFlow = flowsArray.last
            mainFlow = flowsArray[flowsArray.count - 2]
        } else { mainFlow = fm.getFlowsToCheck().last }
        guard let primaryFlow = mainFlow else { return }
        let pageEvent = JinyAnalyticsEvent()
        pageEvent.jiny_custom_events = JinyCustomEvent()
        pageEvent.jiny_custom_events?.context_info = JinyContextTypeInfo(flow: primaryFlow, subFlow: subFlow, page: page, stage: nil)
        analyticsManager?.sendEvent(pageEvent)
    }
    
    func samePageIdentified(_ page: JinyPage) {
        
    }
    
    func newStageFound(_ stage: JinyStage, view: UIView?, rect: CGRect?, webviewForRect:UIView?) {
        auiHandler?.removeAllViews()
        guard let instruction = stage.instructionInfoDict else { return }
        if let targetView = view {
            auiHandler?.performInstruction(instruction: instruction, inView: targetView)
        } else if let targetRect = rect {
            auiHandler?.performInstrcution(instruction: instruction, rect: targetRect, inWebview: webviewForRect)
        } else {
            auiHandler?.performInstruction(instruction: instruction)
        }
        auiHandler?.presentJinyButton()
        
        guard let fm = flowManager, let sm = stageManager else { return }
        var mainFlow:JinyFlow?
        var subFlow:JinyFlow?
        let flowsArray = fm.getFlowsToCheck()
        if flowsArray.count > 1 {
            subFlow = flowsArray.last
            mainFlow = flowsArray[flowsArray.count - 2]
        } else { mainFlow = fm.getFlowsToCheck().last }
        guard let primaryFlow = mainFlow, let page = sm.getCurrentPage() else { return }
        let stageEvent = JinyAnalyticsEvent()
        stageEvent.jiny_custom_events = JinyCustomEvent()
        stageEvent.jiny_custom_events?.context_info = JinyContextTypeInfo(flow: primaryFlow, subFlow: subFlow, page: page, stage: stage)
        analyticsManager?.sendEvent(stageEvent)
    }
    
    func sameStageFound(_ stage: JinyStage, newRect: CGRect?, webviewForRect:UIView?) {
        guard let rect =  newRect else { return }
        
    }
    
    func noStageFound() {
        auiHandler?.removeAllViews()
    }
    
    func removeStage(_ stage: JinyStage) {
        flowManager?.removeStage(stage)
    }
    
    func isSuccessStagePerformed() {
        if let discoveryId = flowManager?.getDiscoveryId() {
            JinySharedInformation.shared.flowCompletedFor(discoveryId: discoveryId)
        }
        flowManager?.popLastFlow()
    }
    
}


// MARK: - UI MANAGER DELEGATE METHODS
extension JinyContextManager {
    
    
    // MARK:-  Fetch Methods
    
    func getCurrentAudio() -> JinySound? {
        guard let currentState = contextDetector?.getState() else { return nil }
        switch currentState {
        case .Discovery:
            guard let currentDiscovery = discoveryManager?.getCurrentDiscovery(), let soundName = currentDiscovery.instruction?.soundName else { return nil }
            
            let soundsArrayToCheckFrom = configuration!.discoverySounds + configuration!.defaultSounds + configuration!.sounds
            let sounds = soundsArrayToCheckFrom.filter{ $0.name == soundName && $0.langCode == JinySharedInformation.shared.getLanguage() }
            return sounds.first
        case .Stage:
            guard let currentStage = stageManager?.getCurrentStage() else { return nil }
            let sounds = configuration!.sounds.filter{ $0.name == currentStage.instruction!.soundName! && $0.langCode == JinySharedInformation.shared.getLanguage() }
            return sounds.first
        }
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

// MARK: - ADDITIONAL METHODS
extension JinyContextManager {
    
    // MARK: Trigger Methods
    
    func getPagesForDiscovery(_ discovery:JinyDiscovery) -> Array<JinyPage> {
        let flowIds = discovery.flowIds
        let flows = flowIds.map { (id) -> JinyFlow? in
            return self.configuration!.flows.first { (tempFlow) -> Bool in
                id == tempFlow.id!
            }
        }.filter { $0 != nil} as! Array<JinyFlow>
        var pages:Array<JinyPage> = []
        for flow in flows { pages.append(contentsOf: flow.pages) }
        return pages
    }
    
    // MARK: Stage Methods
    func proceedIfStageIsBranch(_ stage:JinyStage) {
        if stage.type != .Branch { return }
        guard let _ = stage.branchInfo else { return }
    }
    
    // MARK: Audio Methods
    func checkAndUpdateSoundDownloadPriority(_ sound:JinySound, _ newPriority:Operation.QueuePriority) -> Bool {
        guard let downloadStatus = audioManagerDelegate?.getAudioStatus(sound) else { return false }
        guard downloadStatus == .downloaded else {
            if downloadStatus == .isDownloading { return false}
            audioManagerDelegate?.changePriorityForSound(sound, priority: newPriority)
            return false
        }
        return true
    }
    
    func updateDownloadPriorityForIdentified(_ stages:Array<JinyStage>, _ newPriority:Operation.QueuePriority) {
        for stage in stages {
            let soundArraysToCheck = configuration!.discoverySounds + configuration!.defaultSounds + configuration!.sounds
            let soundsFound = soundArraysToCheck.filter{ $0.name == stage.instruction!.soundName! && $0.langCode == JinySharedInformation.shared.getLanguage()}
            if let audio = soundsFound.first { let _ = checkAndUpdateSoundDownloadPriority(audio, newPriority) }
        }
    }
    
    func getAudioPathFor(soundName:String, langCode:String) -> String? {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let jinyFolder = dir.appendingPathComponent(Constants.Networking.downloadsFolder) as NSString
        let langFolder = jinyFolder.appendingPathComponent(langCode) as NSString
        
        guard let folderContents = try? FileManager.default.contentsOfDirectory(atPath: langFolder as String) else { return nil }
        let filteredFileNames = folderContents.filter { (filename) -> Bool in
            return filename.contains(soundName)
        }
        let sortedFiles = filteredFileNames.sorted { (str1, str2) -> Bool in
            str1.localizedCaseInsensitiveCompare(str2) == ComparisonResult.orderedAscending
        }
        guard let file = sortedFiles.last else {return nil}
        let finalPath = langFolder.appendingPathComponent(file)
        return finalPath
    }
    
}

// MARK: - EVENT GENERATION

extension JinyContextManager {
    
    func sendContextInfoEvent() {
        guard let fm = flowManager, let sm = stageManager else { return }
        var mainFlow:JinyFlow?
        var subFlow:JinyFlow?
        let flowsArray = fm.getFlowsToCheck()
        if flowsArray.count > 1 {
            subFlow = flowsArray.last
            mainFlow = flowsArray[flowsArray.count - 2]
        } else { mainFlow = fm.getFlowsToCheck().last }
        guard let primaryFlow = mainFlow, let currentPage = sm.getCurrentPage(), let currenStage = sm.getCurrentStage() else { return }
        
        let event = JinyAnalyticsEvent()
        event.context_type_info = JinyContextTypeInfo(flow: primaryFlow, subFlow: subFlow, page: currentPage, stage: currenStage)
        analyticsManager?.sendEvent(event)
    }
    
}

extension JinyContextManager:JinyAUICallback {
    
    func triggerEvent(identifier: String, value: Any) {
        taggedEvents[identifier] = value
        guard let contextDet = contextDetector else { return }
        switch contextDet.getState() {
        case .Discovery:
            if let am = assistManager, let _ = am.assistToBeTriggered {
                am.newTaggedEvent(taggedEvents: taggedEvents)
            } else if let dm = discoveryManager {
                if dm.toBeTriggered.count > 0 {
                    dm.newtriggerEvent(events: taggedEvents)
                }
            }
        default:
            return
        }
    }
    
    func getDefaultMedia() -> Dictionary<String,Dictionary<String,Any>> {
        guard let config = configuration else { return [:] }
        return ["default_sounds":config.defSounds, "discovery_sounds":config.discSounds, "aui_content":config.auiContent]
        
    }
    
    func stagePerformed() {
        guard let state = contextDetector?.getState(), state == .Stage else { return }
    }
    
    func getLanguages() -> Array<String> {
        var languages:Array<String> = []
        for lang in configuration!.languages { languages.append(lang.script) }
        return languages
    }
    
    func getLanguageCode() -> String {
        return JinySharedInformation.shared.getLanguage() ?? "hin"
    }
    
    func tryTTS() -> String? {
        if let languagesWithTTS = configuration?.feature?.tts?.languages, let langCode = JinySharedInformation.shared.getLanguage() {
            guard let _ = languagesWithTTS[langCode] else { return nil }
        }
        guard let state = contextDetector?.getState() else { return nil }
        var sound:JinySound?
        switch state {
        case .Discovery:
            if assistManager?.assistToBeTriggered != nil {
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
        guard let state = contextDetector?.getState() else { return nil }
        switch state {
        case .Discovery:
            guard let disc = discoveryManager?.getCurrentDiscovery(),
                let soundName = disc.instruction?.soundName else { return nil }
            let langCode = JinySharedInformation.shared.getLanguage() ?? "hin"
            return getAudioPathFor(soundName: soundName, langCode: langCode)
        case .Stage:
            guard let stage = stageManager?.getCurrentStage(),
                let soundName = stage.instruction?.soundName else { return nil }
            let langCode = JinySharedInformation.shared.getLanguage() ?? "hin"
            return getAudioPathFor(soundName: soundName, langCode: langCode)
        }
    }
    
    func getTTSText() -> String? {
        return nil
    }
    
    
    func willPresentView() {
        
    }
    
    func didPresentView() {
        let state = contextDetector?.getState()
        switch state {
        case .Discovery:
            if assistManager?.currentAssist != nil {
                
            } else if discoveryManager?.getCurrentDiscovery() != nil {
                
            }
        default:
            return
        }
    }
    
    func willPlayAudio() {
        
    }
    
    func didPlayAudio() {
        switch contextDetector!.getState() {
        case .Discovery:
            if assistManager!.currentAssist != nil {
                assistManager!.currentAssistPresented()
            } else {
                guard let _ = discoveryManager?.getCurrentDiscovery() else { return }
                discoveryManager?.currentDiscoveryPresented()
            }
        case .Stage:
            stageManager?.currentStageViewPresented()
        }
    }
    
    func failedToPerform() {
        
    }
    
    func didDismissView() {
        
    }
    
    func didReceiveInstruction(dict: Dictionary<String, Any>) {
        guard let body = dict["body"] as? Dictionary<String,Any> else { return }
        let contentActionInfo = JinyAnalyticsEvent()
        contentActionInfo.jiny_custom_events = JinyCustomEvent()
        if discoveryManager?.getCurrentDiscovery() != nil {
            contentActionInfo.jiny_custom_events?.discovery_info = JinyDiscoveryInfoEvent(withDiscovery: discoveryManager!.getCurrentDiscovery()!)
        }
        contentActionInfo.jiny_custom_events?.content_action_info = JinyContentInfoAction(with: body, type: (dict["type"] as? String) ?? "")
        contentActionInfo.jiny_custom_events?.event_tag = "discovery_opt_in_event"
        analyticsManager?.sendEvent(contentActionInfo)
    }
    
    func jinyTapped() {
        if JinySharedInformation.shared.isMuted() {
            if contextDetector?.getState() == .Stage {
                flowManager?.resetFlowsArray()
                contextDetector?.switchState()
            }
        }
        guard let state = contextDetector?.getState() else { return }
        switch state {
        case .Discovery:
            JinySharedInformation.shared.unmuteJiny()
            guard let discovery = discoveryManager?.getCurrentDiscovery() else { return }
            guard let audio = getCurrentAudio() else { return }
            guard checkAndUpdateSoundDownloadPriority(audio, .veryHigh) else {
                discoveryManager?.resetCurrentDiscovery()
                return
            }
            return
        case .Stage:
            auiHandler?.presentOptionPanel(mute: "Mute", repeatText: "Repeat", language: "Change Language")
            break
        }
    }
    
}

extension JinyContextManager {
    
    func discoveryPresented() {
        contextDetector?.stop()
    }
    
    func discoveryMuted() {
        if let discovery = discoveryManager?.getCurrentDiscovery() {
            JinySharedInformation.shared.discoveryDismissed(discoveryId: discovery.id!)
        }
        discoveryManager?.muteCurrentDiscovery()
        discoveryManager?.resetCurrentDiscovery()
        contextDetector?.start()
    }
    
    func discoveryOptedInFlow(atIndex: Int) {
        guard let dm = discoveryManager, let currentDiscovery = dm.getCurrentDiscovery(), currentDiscovery.flowIds.count > atIndex else {
            discoveryManager?.completedCurrentDiscovery()
            contextDetector?.start()
            return
        }
        
        let selectedFlow = configuration!.flows.first { (flow) -> Bool in
            return flow.id == currentDiscovery.flowIds[atIndex]
        }
        
        guard let flowToProceed = selectedFlow else {
            discoveryManager?.completedCurrentDiscovery()
            contextDetector?.start()
            return
        }
        let flowOptIn = JinyAnalyticsEvent()
        flowOptIn.jiny_custom_events = JinyCustomEvent()
        flowOptIn.jiny_custom_events?.context_info = JinyContextTypeInfo(flow: flowToProceed, subFlow: nil, page: nil, stage: nil)
        flowOptIn.jiny_custom_events?.event_tag = "jiny_flow_opt_in_event"
        analyticsManager?.sendEvent(flowOptIn)
        contextDetector?.switchState()
        auiHandler?.removeAllViews()
        JinyEventDetector.shared.delegate = nil
        flowManager?.addNewFlow(flowToProceed.copy(), false, currentDiscovery.id!)
        discoveryManager?.completedCurrentDiscovery()
        contextDetector?.start()
    }
    
    func discoveryReset() {
        discoveryManager?.resetCurrentDiscovery()
        contextDetector?.start()
    }
    
}


extension JinyContextManager {
    
    func languagePanelOpened() {
        contextDetector?.stop()
    }
    
    func languagePanelClosed() {
        discoveryManager?.resetCurrentDiscovery()
        stageManager?.resetCurrentStage()
        contextDetector?.start()
    }
    
    func languagePanelLanguageSelected(atIndex: Int) {
        
        guard atIndex < configuration!.languages.count else {
            discoveryManager?.resetCurrentDiscovery()
            stageManager?.resetCurrentStage()
            contextDetector?.start()
            return
        }
        let langSelected = configuration!.languages[atIndex]
        JinySharedInformation.shared.setLanguage(langSelected.localeId)
        discoveryManager?.resetCurrentDiscovery()
        stageManager?.resetCurrentStage()
        contextDetector?.start()
        audioManagerDelegate?.languageChanged()
    }
    
}


extension JinyContextManager {
    
    func optionPanelOpened() {
        contextDetector?.stop()
    }
    
    func optionPanelClosed() {
        stageManager?.resetCurrentStage()
        contextDetector?.start()
    }
    
    func optionPanelMuteClicked() {
        if contextDetector?.getState() == .Stage {
            stageManager?.resetCurrentStage()
            JinySharedInformation.shared.muteJiny()
            flowManager?.resetFlowsArray()
            contextDetector?.switchState()
        }
        contextDetector?.start()
    }
    
    func optionPanelRepeatClicked() {
        contextDetector?.start()
        guard let state = contextDetector?.getState(), state == .Stage else { return }
        stageManager?.resetCurrentStage()
        
    }
    
}


extension JinyContextManager {
    
    func flowSelectorPresented() {}
    
    func flowSelectorFlowSelected(atIndex: Int) {
        guard let currentStage = stageManager?.getCurrentStage(),
            let branchInfo = currentStage.branchInfo,
            atIndex < branchInfo.branchFlows.count else { return }
        let subFlowId = branchInfo.branchFlows[atIndex]
        let subFlow = configuration!.flows.first { (tempFlow) -> Bool in
            tempFlow.id! == subFlowId
        }
        guard let subFlowSelected = subFlow else { return }
        flowManager?.addNewFlow(subFlowSelected, true, nil)
    }
    
    func flowSelectorDismissed() {
        
    }
    
    func getSoundFor(name:String, langCode:String) -> JinySound? {
        for sound in configuration!.sounds{
            if sound.name == name && sound.langCode == langCode { return sound }
        }
        return nil
    }
    
    func isTTSAvailable(sound:JinySound) -> Bool {
        guard let _ = sound.text else { return false }
        guard let availableLangCodes = configuration?.feature?.tts?.languages else { return false }
        return availableLangCodes.keys.contains(sound.langCode)
    }
    
}
