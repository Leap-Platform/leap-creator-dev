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

/// JinyContextManager class acts as the central hub of the Core SDK once the config and sounds are downloaded. It invokes the JinyContextDetector class which helps in identoifying the current flow, page and stage to be executed. JinyContextManager acts as the delegate to JinyContextDetector receiving information about flow, page and stage and passing it to JinyFlowManager & JinyStageManager.  JinyContextManager also acts as delegate to JinyStageManager, there by understanding if a new stage is identified or the same stage is identified and invoking the AUI SDK . JinyContextManger is also responsible for communicating with JinyAnalyticsManager
class JinyContextManager {
    
    private var contextDetector:JinyContextDetector?
    private var triggerManager:JinyTriggerManager?
    private var flowManager:JinyFlowManager?
    private var stageManager:JinyStageManager?
    private var uiManager:JinyUIManager?
    private var analyticsManager:JinyAnalyticsManager?
    private let config:JinyConfig
    
    
    var audioManagerDelegate:JinyContextManagerAudioDelegate?
    
    init(config jinyConfig:JinyConfig) {
        config = jinyConfig
    }
    
    /// Methods to setup all managers and setting up their delegates to be this class. After setting up all managers, it calls the start method and starts the context detection
    func initialize() {
        contextDetector = JinyContextDetector(withDelegate: self, andConfig: config)
        triggerManager = JinyTriggerManager(self)
        flowManager = JinyFlowManager(self)
        stageManager = JinyStageManager(self)
        uiManager = JinyUIManager(self)
        analyticsManager = JinyAnalyticsManager(self)
        self.start()
    }
    
    /// Sets all triggers in trigger manager and starts context detection. By default context detection is in Discovery mode, hence checks all the relevant triggers first to start discovery
    func start() {
        triggerManager?.setAllTriggers(config.triggers)
        contextDetector?.start()
    }
    
}

// MARK: - CONTEXT DETECTOR DELEGATE METHODS
extension JinyContextManager:JinyContextDetectorDelegate {
    
    // MARK: - Trigger Methods
    func getTriggersToCheck() -> Array<JinyTrigger> { return triggerManager?.getTriggersToCheck() ?? []}
    
    func triggerIdentified(_ trigger: JinyTrigger) { triggerManager?.triggerFound(trigger) }
    
    func noTriggerIdentified() { checkForContextualTrigger() }
    
    
    // MARK: - Flow Methods
    func findCurrentFlow() -> JinyFlow? { return flowManager?.getRelevantFlow(lookForParent: false) }
    
    func checkForParentFlow() -> JinyFlow? { return flowManager?.getRelevantFlow(lookForParent: true) }
    
    
    // MARK: - Page Methods
    func nativePageFound(_ nativePage: JinyNativePage) {
        updateDownloadPriorityForIdentified(nativePage.nativeStages, .normal)
        stageManager?.setCurrentPage(nativePage)
        stageManager?.setArrayOfStagesFromPage(nativePage.nativeStages)
    }
    
    func webPageFound(_ webPage: JinyWebPage) {
        stageManager?.setCurrentPage(webPage)
        stageManager?.setArrayOfStagesFromPage(webPage.webStages)
        
    }
    
    func pageNotFound() {
        stageManager?.setCurrentPage(nil)
        stageManager?.setCurrentStage(nil, view: nil, rect: nil)
        uiManager?.removeAllViews()
        uiManager?.dismissJinyButton()
    }
    
    
    // MARK: - Stage Methods
    func getRelevantStages() -> Array<JinyStage> { return stageManager?.getArrayOfStagesToCheck() ?? [] }
    
    func nativeStageFound(_ nativeStage: JinyNativeStage, pointerView view: UIView?) { stageManager?.setCurrentStage(nativeStage, view: view, rect: nil) }
    
    func webStageFound(_ webStage: JinyWebStage, pointerRect rect:CGRect?) { stageManager?.setCurrentStage(webStage, view: nil, rect: rect) }
    
    func stageNotFound() { stageManager?.setCurrentStage(nil, view: nil, rect: nil) }
    
}

// MARK: - TRIGGER MANAGER DELEGATE METHODS


extension JinyContextManager:JinyTriggerManagerDelegate {
    
    func getMutedTriggerIds() -> Array<Int> { return JinySharedInformation.shared.getMutedTriggerIds() }
    
    func addNewTriggerToMute(_ id: Int) { JinySharedInformation.shared.addToMutedTrigger(id) }
    
    func newTriggerIdentified(_ trigger: JinyTrigger) {
        guard let tm = triggerManager else { return }
        
        // Check if jiny sdk is muted or, trigger is muted or trigger was already completed.
        // If yes, then present jiny button and return
        if JinySharedInformation.shared.isMuted() || tm.getMutedTriggers().contains(trigger) || tm.getCompletedTriggers().contains(trigger) {
            triggerManager?.addTriggerToIdentifiedList(trigger)
            uiManager?.presentJinyButton()
            return
        }
        
        // If not, present corresponding discovery after checking for audio
        guard let audio = getCurrentAudio() else { return }
        
        guard checkAndUpdateSoundDownloadPriority(audio, .veryHigh) else {
            triggerManager?.resetCurrentTrigger()
            return
        }
        uiManager?.presentDiscovery(trigger: trigger, JinySharedInformation.shared.getLanguage() ?? "hin")
    }
    
    func sameTriggerIdentified(_ trigger: JinyTrigger) { }
    
    func noContextualTrigger() { uiManager?.dismissJinyButton() }
    
}

// MARK: - FLOW MANAGER DELEGATE METHODS
extension JinyContextManager:JinyFlowManagerDelegate {
    
    func noActiveFlows() { contextDetector?.switchState() }
    
    
}

// MARK: - STAGE MANAGER DELEGATE METHODS
extension JinyContextManager:JinyStageManagerDelegate {
    
    func newWebStageIdentified(_ stage: JinyWebStage, _ rect: CGRect?) {
        flowManager?.updateFlowArrayAndResetCounter()
        uiManager?.presentJinyButton()
        guard let audio = getCurrentAudio() else { return }
        guard checkAndUpdateSoundDownloadPriority(audio, .veryHigh) else {
            stageManager?.resetCurrentStage()
            return
        }
        if stage.stageType == .Branch {
            guard let branchInfo = stage.branchInfo else { return }
            uiManager?.presentFlowSelector(branchInfo.branchFlows, branchInfo.branchTitle)
        } else {
            
            guard let pointerType = stage.pointerIdentifer?.pointerType else {
                uiManager?.playSound()
                return
            }
            let stageType = stage.stageType
            guard let viewRect = rect else { return }
            guard let audio = getCurrentAudio() else { return }
            guard checkAndUpdateSoundDownloadPriority(audio, .veryHigh) else {
                stageManager?.resetCurrentStage()
                return
            }
            uiManager?.presentPointer(ofPointerType: pointerType, forStageType: stageType, toRect: viewRect)
        }
    }
    
    func newNativeStageIdentified(_ stage: JinyNativeStage, _ view: UIView?) {
        flowManager?.updateFlowArrayAndResetCounter()
        uiManager?.presentJinyButton()
        uiManager?.removeAllViews()
        guard let audio = getCurrentAudio() else { return }
        guard checkAndUpdateSoundDownloadPriority(audio, .veryHigh) else {
            stageManager?.resetCurrentStage()
            return
        }
        if stage.stageType == .Branch {
            guard let branchInfo = stage.branchInfo else { return }
            uiManager?.presentFlowSelector(branchInfo.branchFlows, branchInfo.branchTitle)
        } else {
            guard let pointerType = stage.pointerIdentfier?.pointerType else {
                uiManager?.playSound()
                return
            }
            let stageType = stage.stageType
            guard let ptrView = view else {
                uiManager?.playSound()
                return
            }
            guard let audio = getCurrentAudio() else { return }
            guard checkAndUpdateSoundDownloadPriority(audio, .veryHigh) else {
                stageManager?.resetCurrentStage()
                return
            }
            sendContextInfoEvent()
            uiManager?.presentPointer(ofPointerType: pointerType, forStageType: stageType, toView: ptrView)
        }
    }
    
    func sameWebStageIdentified(_ stage: JinyWebStage, _ rect: CGRect?) {
        if stage.stageType == .Branch { return }
        guard let viewRect = rect else { return }
        uiManager?.updateRect(viewRect)
    }
    
    func sameNativeStageIdentified(_ stage: JinyNativeStage, _ view: UIView?) {}
    
    func noStageIdentified() {
        uiManager?.removeAllViews()
        
    }
    
    func removeStage(_ stage: JinyStage) {
        flowManager?.removeStage(stage)
    }
    
    func isSuccessStagePerformed() {
        flowManager?.popLastFlow()
    }
    
}


// MARK: - UI MANAGER DELEGATE METHODS
extension JinyContextManager:JinyUIManagerDelegate {
    
    //MARK: Language Panel Methods
    func languagePanelDetected() {
        contextDetector?.stop()
    }
    
    func langugagePanelClosed() {
        triggerManager?.resetCurrentTrigger()
        contextDetector?.start()
    }
    
    func langugePanelLanguageSelected(atIndex: Int) {
        guard atIndex < config.languages.count else {
            triggerManager?.resetCurrentTrigger()
            contextDetector?.start()
            return
        }
        let langSelected = config.languages[atIndex]
        JinySharedInformation.shared.setLanguage(langSelected.localeId)
        triggerManager?.resetCurrentTrigger()
        stageManager?.resetCurrentStage()
        contextDetector?.start()
        audioManagerDelegate?.languageChanged()
    }
    
    
    // MARK:-  Fetch Methods
    
    func getCurrentAudio() -> JinySound? {
        guard let currentState = contextDetector?.getState() else { return nil }
        switch currentState {
        case .Discovery:
            guard let currentTrigger = triggerManager?.getCurrentTrigger() else { return nil }
            let soundsArrayToCheckFrom = config.discoverySounds + config.defaultSounds + config.sounds
            let sounds = soundsArrayToCheckFrom.filter{ $0.name == currentTrigger.soundName && $0.langCode == JinySharedInformation.shared.getLanguage() }
            return sounds.first
        case .Stage:
            guard let currentStage = stageManager?.getCurrentStage() else { return nil }
            let sounds = config.sounds.filter{ $0.name == currentStage.soundName && $0.langCode == JinySharedInformation.shared.getLanguage() }
            return sounds.first
        }
    }
    
    func getLanguages() -> Array<String> {
        var languages:Array<String> = []
        for lang in config.languages { languages.append(lang.script) }
        return languages
    }
    
    
    // MARK: - Option Panel Methods
    func optionPanelPresented() { contextDetector?.stop() }
    
    func repeatButtonClicked() {
        contextDetector?.start()
        guard let state = contextDetector?.getState(), state == .Stage else { return }
        uiManager?.removeAllViews()
        stageManager?.resetCurrentStage()
    }
    
    func jinyMuteClicked() {
        uiManager?.removeAllViews()
        if contextDetector?.getState() == .Stage {
            stageManager?.resetCurrentStage()
            JinySharedInformation.shared.muteJiny()
            flowManager?.resetFlowsArray()
            contextDetector?.switchState()
        }
        contextDetector?.start()
    }
    
    func changeLanguageButtonClicked() {
        uiManager?.presentLanguagePanel()
    }
    
    func optionPanelDismissed() {
        stageManager?.resetCurrentStage()
        contextDetector?.start()
        uiManager?.presentJinyButton()
    }
    
    // MARK: - Jiny Button Method
    func jinyButtonClicked() {
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
            guard let trigger = triggerManager?.getCurrentTrigger() else { return }
            guard let audio = getCurrentAudio() else { return }
            guard checkAndUpdateSoundDownloadPriority(audio, .veryHigh) else {
                triggerManager?.resetCurrentTrigger()
                return
            }
            guard let langCode = JinySharedInformation.shared.getLanguage() else { return }
            uiManager?.presentDiscovery(trigger: trigger, langCode)
            return
        case .Stage:
            uiManager?.dismissJinyButton()
            guard let langCode = JinySharedInformation.shared.getLanguage() else { return }
            guard let language = config.languages.filter({ $0.localeId == langCode }).first else { return }
            uiManager?.presentOptionPanel(repeatText: language.repeatText, muteText: language.muteText, languageText: language.changeLanguageText)
        }
    }
    
    
    // MARK: - Discovery Methods
    func discoveryPresented() {
        contextDetector?.stop()
    }
    
    func discoveryCompleted() {
        triggerManager?.currentTriggerCompleted()
    }
    
    func discoveryMuted() {
        triggerManager?.muteCurrentTrigger()
        contextDetector?.start()
    }
    
    func flowOptedIn(atIndex:Int) {
        guard let currentTrigger = triggerManager?.getCurrentTrigger() else {
            contextDetector?.start()
            return
        }
        guard atIndex < currentTrigger.flowIndexes.count else {
            contextDetector?.start()
            return
        }
        let flowId = currentTrigger.flowIndexes[atIndex]
        let flowsFiltered = config.flows.filter { $0.flowId == flowId }
        guard flowsFiltered.count > 0 else {
            contextDetector?.start()
            return
        }
        flowManager?.addNewFlow(flowsFiltered[0].copy(), false)
        contextDetector?.switchState()
        contextDetector?.start()
    }
    
    
    // MARK: - Flow Selector Methods
    func subFlowSelected(_ flow:JinyFlow) {
        flowManager?.addNewFlow(flow.copy(), true)
    }
    
    
    // MARK: Pointer Methods
    func nextClicked() {
        guard let stage = stageManager?.getCurrentStage() else { return }
        stageManager?.stagePerformed(stage)
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
    func checkForContextualTrigger() {
        var tempTrigger:JinyTrigger?
        guard let identifiedTriggers = triggerManager?.getTriggersToCheckForContextualTriggering() else { return }
        guard let viewHierarchy = contextDetector?.fetchViewHierarchy() else { return }
        for trigger in identifiedTriggers.reversed() {
            let flowIndexes = trigger.flowIndexes
            let flowsIdentified = config.flows.filter{ flowIndexes.contains($0.flowId) }
            if flowsIdentified.count == 0 { continue }
            for flow in flowsIdentified {
                if let _ = contextDetector?.findCurrentNativePage(flow.nativePages, viewHierarchy) {
                    tempTrigger = trigger
                    break
                }
                if let _ = contextDetector?.findCurrentWebPage(flow.webPages, viewHierarchy) {
                    tempTrigger = trigger
                    break
                }
            }
            if tempTrigger != nil { break }
        }
        guard let triggerIdentified = tempTrigger else {
            triggerManager?.noTriggerFound()
            return
        }
        triggerManager?.triggerFound(triggerIdentified)
    }
    
    
    // MARK: Stage Methods
    func proceedIfStageIsBranch(_ stage:JinyStage) {
        if stage.stageType != .Branch { return }
        guard let branchInfo = stage.branchInfo else { return }
        uiManager?.presentFlowSelector(branchInfo.branchFlows, branchInfo.branchTitle)
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
            let soundArraysToCheck = config.discoverySounds + config.defaultSounds + config.sounds
            let soundsFound = soundArraysToCheck.filter{ $0.name == stage.soundName && $0.langCode == JinySharedInformation.shared.getLanguage()}
            if let audio = soundsFound.first { let _ = checkAndUpdateSoundDownloadPriority(audio, newPriority) }
        }
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
