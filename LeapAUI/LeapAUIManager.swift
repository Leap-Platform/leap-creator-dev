//
//  LeapAUIManager.swift
//  LeapAUI
//
//  Created by Aravind GS on 07/07/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import LeapCoreSDK
import AVFoundation
import WebKit

protocol LeapAUIManagerDelegate: NSObjectProtocol {
    
    func isClientCallbackRequired() -> Bool
    func eventGenerated(event: Dictionary<String,Any>)
}

class LeapAUIManager: NSObject {
    
    weak var auiManagerCallBack: LeapAUICallback?
    weak var delegate: LeapAUIManagerDelegate?
    
    var currentAssist: LeapAssist? { didSet { if let _ = currentAssist { currentAssist?.delegate = self } } }
    
    var keyboardHeight: Float = 0
    var leapButtonBottomConstraint: NSLayoutConstraint?
    
    var audioPlayer: AVAudioPlayer?
    var utterance = AVSpeechUtterance()
    let synthesizer = AVSpeechSynthesizer()
    
    var leapButton: LeapMainButton?
    var leapIconOptions: LeapIconOptions?
    var mediaManager = LeapMediaManager()
    
    lazy var scrollArrowButton = LeapArrowButton(arrowDelegate: self)
    
    var currentInstruction: Dictionary<String,Any>?
    weak var currentTargetView: UIView?
    var currentTargetRect: CGRect?
    weak var currentWebView: UIView?
    
    var autoDismissTimer: Timer?
    private var baseUrl = String()
    
    private var isLanguageOptionsOpen = false
    
    let soundManager = LeapSoundManager()
    
    var languageOptions: LeapLanguageOptions?
    
    func addIdentifier(identifier: String, value: Any) {
        auiManagerCallBack?.triggerEvent(identifier: identifier, value: value)
    }
}

extension LeapAUIManager {
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc func keyboardDidShow(_ notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
           leapButton != nil
        {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyboardHeight = Float(keyboardRectangle.height)
            leapButtonBottomConstraint?.constant = CGFloat(keyboardHeight + 20)
            leapButton?.updateConstraints()
        }
    }
    
    @objc func keyboardDidHide(_ notification: NSNotification) {
        keyboardHeight = 0
        if leapButton != nil {
            leapButtonBottomConstraint?.constant = mainIconBottomConstant
            leapButton?.updateConstraints()
        }
    }
    
    @objc func appDidBecomeActive() {
        guard currentAssist != nil else { return }
        playAudio()
    }
}

// MARK: - AUIHANDLER METHODS
extension LeapAUIManager: LeapAUIHandler {
    
    func startMediaFetch() {
        
        DispatchQueue.global().async {[weak self] in
            
            guard let callback = self?.auiManagerCallBack else { return }
            let initialSounds = callback.getDefaultMedia()
            
            if let discoverySoundsDicts = initialSounds[constant_discoverySounds] as? Array<Dictionary<String,Any>> {
                self?.soundManager.discoverySoundsJson = self?.soundManager.processSoundConfigs(configs:discoverySoundsDicts) ?? [:]
                self?.startDiscoverySoundDownload()
            }
            if let previewSoundsDict = initialSounds[constant_previewSounds] as? Array<Dictionary<String,Any>> {
                self?.soundManager.previewSoundsJson = self?.soundManager.processSoundConfigs(configs: previewSoundsDict) ?? [:]
                self?.startPreviewSoundDownload()
            }
            
            var htmlBaseUrl:String?
            if let auiContentDicts = initialSounds[constant_auiContent]  as? Array<Dictionary<String,Any>> {
                for auiContentDict in auiContentDicts {
                    if let baseUrl = auiContentDict[constant_baseUrl] as? String,
                       let contents = auiContentDict[constant_content] as? Array<String> {
                        self?.baseUrl = baseUrl
                        htmlBaseUrl = baseUrl
                        for content in contents {
                            let auiContent = LeapAUIContent(baseUrl: baseUrl, location: content)
                            if let _ = auiContent.url { self?.downloadFromMediaManager(forMedia: auiContent, atPriority: .normal) }
                        }
                    }
                }
            }
            
            if let iconSettingDict = initialSounds[constant_iconSetting] as? Dictionary<String, LeapIconSetting> {
                if let baseUrl = htmlBaseUrl {
                    self?.baseUrl = baseUrl
                    for (_, value) in iconSettingDict {
                        let auiContent = LeapAUIContent(baseUrl: baseUrl, location: value.htmlUrl ?? "")
                        if let _ = auiContent.url { self?.downloadFromMediaManager(forMedia: auiContent, atPriority: .normal) }
                    }
                }
            }
            
            self?.soundManager.fetchSoundConfig({ [weak self] (success) in
                
                if success { self?.startStageSoundDownload() }
            })
        }
    }
    
    func hasClientCallBack() -> Bool {
        guard let managerDelegate = delegate else { return false }
        return managerDelegate.isClientCallbackRequired()
    }
    
    func sendEvent(event: Dictionary<String, Any>) {
        delegate?.eventGenerated(event: event)
    }
    
    func performNativeAssist(instruction: Dictionary<String, Any>, view: UIView?, localeCode: String) {
        setupDefaultValues(instruction:instruction, langCode: localeCode, view: view, rect: nil, webview: nil)
        guard instruction[constant_assistInfo] as? Dictionary<String,Any> != nil else {
            if let _ = instruction[constant_soundName] as? String {
                auiManagerCallBack?.didPresentAssist()
                playAudio()
            }
            return
        }
        guard let view = currentTargetView else {
            performKeyWindowInstruction(instruction: instruction, iconInfo: [:])
            return
        }
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String else { return }
        performInViewNativeInstruction(instruction: instruction, inView: view, type: type)
    }
    
    func performWebAssist(instruction: Dictionary<String,Any>, rect: CGRect, webview: UIView?, localeCode: String) {
        setupDefaultValues(instruction:instruction, langCode: localeCode, view: nil, rect: rect, webview: webview)
        guard instruction[constant_assistInfo] as? Dictionary<String,Any> != nil else {
            if let _ = instruction[constant_soundName] as? String {
                auiManagerCallBack?.didPresentAssist()
                playAudio()
            }
            return
        }
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String,
              let anchorWebview = webview else { return }
        performInViewWebInstruction(instruction: instruction, rect: rect, inWebview: anchorWebview, type: type,iconInfo:nil)
    }
    
    func performNativeDiscovery(instruction: Dictionary<String, Any>, view: UIView?,  localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, AnyHashable>, localeHtmlUrl: String?) {
        setupDefaultValues(instruction: instruction, langCode: nil, view: view, rect: nil, webview: nil)
        if !iconInfo.isEmpty {
            guard isReadyToPresent(type: "", assistInfo: iconInfo) else {
                auiManagerCallBack?.failedToPerform()
                return
            }
        }
        showLanguageOptions(withLocaleCodes: localeCodes, iconInfo: iconInfo, localeHtmlUrl: localeHtmlUrl) { (languageChose) in
            self.setupDefaultValues(instruction: instruction, langCode: nil, view: view, rect: nil, webview: nil)
            if languageChose {
                guard let anchorView = view else {
                    self.dismissLeapButton()
                    self.performKeyWindowInstruction(instruction: instruction, iconInfo: iconInfo)
                    return
                }
                guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
                      let type = assistInfo[constant_type] as? String else { return }
                self.performInViewNativeInstruction(instruction: instruction, inView: anchorView, type: type, iconInfo: iconInfo)
                self.dismissLeapButton()
            }
            else { self.presentLeapButton(for: iconInfo, iconEnabled: !iconInfo.isEmpty) }
        }
    }
    
    func performWebDiscovery(instruction: Dictionary<String, Any>, rect: CGRect, webview: UIView?,  localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, AnyHashable>, localeHtmlUrl: String?) {
        setupDefaultValues(instruction: instruction, langCode: nil, view: nil, rect: rect, webview: webview)
        if !iconInfo.isEmpty {
            guard isReadyToPresent(type: "", assistInfo: iconInfo) else {
                auiManagerCallBack?.failedToPerform()
                return
            }
        }
        showLanguageOptions(withLocaleCodes: localeCodes, iconInfo: iconInfo, localeHtmlUrl: localeHtmlUrl) { (languageChose) in
            if languageChose {
                self.setupDefaultValues(instruction: instruction, langCode: nil, view: nil, rect: rect, webview: webview)
                guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
                      let type = assistInfo[constant_type] as? String,
                      let anchorWebview = webview else { return }
                self.dismissLeapButton()
                self.performInViewWebInstruction(instruction: instruction, rect: rect, inWebview: anchorWebview, type: type, iconInfo: iconInfo)
            }
            else { self.presentLeapButton(for: iconInfo, iconEnabled: !iconInfo.isEmpty) }
        }
    }
    
    func performNativeStage(instruction: Dictionary<String, Any>, view: UIView?, iconInfo: Dictionary<String, AnyHashable>) {
        setupDefaultValues(instruction:instruction, langCode: nil, view: view, rect: nil, webview: nil)
        guard instruction[constant_assistInfo] as? Dictionary<String,Any> != nil else {
            if let _ = instruction[constant_soundName] as? String {
                auiManagerCallBack?.didPresentAssist()
                playAudio()
                presentLeapButton(for: iconInfo, iconEnabled: !iconInfo.isEmpty)
            }
            return
        }
        guard let view = currentTargetView else {
            performKeyWindowInstruction(instruction: instruction, iconInfo: nil)
            presentLeapButton(for: iconInfo, iconEnabled: !iconInfo.isEmpty)
            return
        }
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String else { return }
        performInViewNativeInstruction(instruction: instruction, inView: view, type: type)
        presentLeapButton(for: iconInfo, iconEnabled: !iconInfo.isEmpty)
    }
    
    func performWebStage(instruction: Dictionary<String, Any>, rect: CGRect, webview: UIView?, iconInfo: Dictionary<String, AnyHashable>) {
        setupDefaultValues(instruction:instruction, langCode:nil, view: nil, rect: rect, webview: webview)
        guard instruction[constant_assistInfo] as? Dictionary<String,Any> != nil else {
            if let _ = instruction[constant_soundName] as? String {
                auiManagerCallBack?.didPresentAssist()
                playAudio()
                presentLeapButton(for: iconInfo, iconEnabled: !iconInfo.isEmpty)
            }
            return
        }
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String else { return }
        guard let anchorWebview = webview else { return }
        performInViewWebInstruction(instruction: instruction, rect: rect, inWebview: anchorWebview, type: type,iconInfo:nil)
        presentLeapButton(for: iconInfo, iconEnabled: !iconInfo.isEmpty)
    }
    
    func updateRect(rect: CGRect, inWebView: UIView?) {
        
        if let swipePointer = currentAssist as? LeapSwipePointer { swipePointer.updateRect(newRect: rect, inView: inWebView) }
        else if let fingerPointer = currentAssist as? LeapFingerPointer { fingerPointer.updateRect(newRect: rect, inView: inWebView) }
        else if let label = currentAssist as? LeapLabel { label.updateRect(newRect: rect, inView: inWebView) }
        else if let tooltip = currentAssist as? LeapToolTip { tooltip.updatePointer(toRect: rect, inView: inWebView) }
        else if let highlight = currentAssist as? LeapHighlight { highlight.updateHighlight(toRect: rect, inView: inWebView) }
        else if let spot = currentAssist as? LeapSpot { spot.updateSpot(toRect: rect, inView: inWebView) }
        else if let beacon = currentAssist as? LeapBeacon { beacon.updateRect(newRect: rect, inView: inWebView) }
        scrollArrowButton.updateRect(newRect: rect)

    }
    
    func updateView(inView view: UIView) {
        
        if let swipePointer = currentAssist as? LeapSwipePointer { swipePointer.setPosition() }
        else if let fingerPointer = currentAssist as? LeapFingerPointer { fingerPointer.setPosition() }
        else if let label = currentAssist as? LeapLabel { label.setAlignment() }
        else if let tooltip = currentAssist as? LeapToolTip { tooltip.updatePointer() }
        else if let highlight = currentAssist as? LeapHighlight { highlight.updateHighlight() }
        else if let spot = currentAssist as? LeapSpot { spot.updateSpot() }
        else if let beacon = currentAssist as? LeapBeacon { beacon.show() }
        scrollArrowButton.checkForView()
    }
    
    func dismissLeapButton() {
        leapButton?.isHidden = true
    }
    
    func removeAllViews() {
        removeCurrentAssist()
        removeLanguageOptions()
        leapIconOptions?.dismiss(withAnimation: false)
        dismissLeapButton()
    }
    
    func removeCurrentAssist() {
        currentAssist?.performExitAnimation(animation: self.currentAssist?.assistInfo?.layoutInfo?.exitAnimation ?? "fade_out", byUser: false, autoDismissed: false, byContext: true, panelOpen: false, action: nil)
        currentAssist = nil
        currentInstruction = nil
        currentTargetView = nil
        currentTargetRect = nil
        currentWebView = nil
    }
    
    func removeLanguageOptions() {
        languageOptions?.removeFromSuperview()
        languageOptions = nil
    }
    
    func presentLeapButton(for iconInfo: Dictionary<String,AnyHashable>, iconEnabled: Bool) {
        guard iconEnabled, leapIconOptions == nil else {
            if leapIconOptions != nil, leapButton != nil {
            let kw = UIApplication.shared.windows.first{ $0.isKeyWindow }
            if let window = kw {
                window.bringSubviewToFront(leapIconOptions!)
                window.bringSubviewToFront(leapButton!) } }
            return
        }
        let jsonDecoder = JSONDecoder()
        guard let iconData = try? JSONSerialization.data(withJSONObject: iconInfo, options: .prettyPrinted) else { return }
        guard let iconSetting = try? jsonDecoder.decode(LeapIconSetting.self, from: iconData) else { return }
        guard leapButton == nil, leapButton?.window == nil else {
            if !iconSetting.isEqual(LeapSharedAUI.shared.iconSetting) {
                self.leapButton?.removeFromSuperview()
                self.leapButton = nil
                presentLeapButton(for: iconInfo, iconEnabled: iconEnabled)
                return
            }
            leapButton?.isHidden = false
            let kw = UIApplication.shared.windows.first{ $0.isKeyWindow}
            if let keyWindow = kw { keyWindow.bringSubviewToFront(leapButton!) }
            return
        }
        LeapSharedAUI.shared.iconSetting = iconSetting
        guard isReadyToPresent(type: "", assistInfo: iconInfo) else {
            auiManagerCallBack?.failedToPerform()
            return
        }
        leapButton = LeapMainButton(withThemeColor: UIColor.init(hex: iconSetting.bgColor ?? "#00000000") ?? .black, dismissible: iconSetting.dismissible ?? false)
        guard let keyWindow = UIApplication.shared.keyWindow else { return }
        keyWindow.addSubview(leapButton!)
        leapButton?.leapTappable.tappableDelegate = self
        leapButton?.stateDelegate = self
        leapButton?.disableDialog.delegate = self
        leapButtonBottomConstraint = NSLayoutConstraint(item: keyWindow, attribute: .bottom, relatedBy: .equal, toItem: leapButton, attribute: .bottom, multiplier: 1, constant: mainIconBottomConstant)
        leapButton?.bottomConstraint = leapButtonBottomConstraint!
        var distance = mainIconCornerConstant
        var cornerAttribute: NSLayoutConstraint.Attribute = .trailing
        if iconSetting.leftAlign ?? false {
            cornerAttribute = .leading
            distance = -mainIconCornerConstant
        }
        let cornerConstraint = NSLayoutConstraint(item: keyWindow, attribute: cornerAttribute, relatedBy: .equal, toItem: leapButton, attribute: cornerAttribute, multiplier: 1, constant: distance)
        NSLayoutConstraint.activate([leapButtonBottomConstraint!, cornerConstraint])
        leapButton?.htmlUrl = iconSetting.htmlUrl
        leapButton?.iconSize = mainIconSize
        leapButton?.configureIconButton()
    }
}

// MARK: - HANDLING ICON TAP
extension LeapAUIManager: LeapTappableDelegate {
    
    func iconDidTap() {
        guard let _ = currentInstruction, LeapPreferences.shared.getUserLanguage() != nil else {
            auiManagerCallBack?.leapTapped()
            return
        }
        auiManagerCallBack?.optionPanelOpened()
        guard let button = leapButton else { return }
        guard let optionsText = auiManagerCallBack?.getCurrentLanguageOptionsTexts() else { return }
        let stopText = optionsText[constant_stop] ?? "Stop"
        let languageText = optionsText[constant_language]
        leapIconOptions = LeapIconOptions(withDelegate: self, stopText: stopText, languageText: languageText, leapButton: button)
        leapIconOptions?.show()
    }
}

// MARK: - LEAP MAIN BUTTON STATE HANDLING
extension LeapAUIManager: LeapIconStateDelegate {
    func iconDidChange(state: LeapIconState) {
        switch state {
        case .rest:
            DispatchQueue.main.async {
                self.leapButton?.changeToRest()
            }
        case .loading:
            DispatchQueue.main.async {
                self.leapButton?.changeToLoading()
            }
        case .audioPlay:
            DispatchQueue.main.async {
                self.leapButton?.changeToAudioPlay()
            }
        }
    }
}

// MARK: - DISABLE ASSISTANCE DELEGATE METHODS
extension LeapAUIManager: LeapDisableAssistanceDelegate {
    
    func didPresentDisableAssistance() {
        guard let _ = autoDismissTimer else { return }
        self.stopAutoDismissTimer()
    }
    
    func shouldDisableAssistance() {
        auiManagerCallBack?.disableAssistance()
        removeAllViews()
    }
    
    func didDismissDisableAssistance() {
        startAutoDismissTimer()
    }
}

// MARK: - SOUND DOWNLOAD AND AUDIO HANDLING
extension LeapAUIManager {
    
    func downloadFromMediaManager(forMedia: LeapMedia, atPriority: Operation.QueuePriority, completion: SuccessCallBack? = nil) {
        DispatchQueue.main.async { self.leapButton?.iconState = .loading }
        mediaManager.startDownload(forMedia: forMedia, atPriority: atPriority) { [weak self] (success) in
            completion?(success)
            DispatchQueue.main.async { self?.leapButton?.iconState = .rest }
        }
    }
    
    func startDiscoverySoundDownload() {
        guard auiManagerCallBack != nil else { return }
        let code = auiManagerCallBack!.getLanguageCode()
        let discoverySoundsForCode = soundManager.discoverySoundsJson[code] ?? []
        for sound in discoverySoundsForCode { if sound.url != nil { downloadFromMediaManager(forMedia: sound, atPriority: .normal) } }
    }
    
    func startPreviewSoundDownload() {
        guard auiManagerCallBack != nil else { return }
        let code = auiManagerCallBack!.getLanguageCode()
        let previewSoundsForCode = soundManager.previewSoundsJson[code] ?? []
        for sound in  previewSoundsForCode { if sound.url != nil { downloadFromMediaManager(forMedia: sound, atPriority: .normal) } }
    }
    
    func startStageSoundDownload() {
        guard auiManagerCallBack != nil else { return }
        let code = auiManagerCallBack!.getLanguageCode()
        let stageSoundsForCode = soundManager.stageSoundsJson[code] ?? []
        for sound in stageSoundsForCode { if sound.url != nil { downloadFromMediaManager(forMedia: sound, atPriority: .low) } }
    }
    
    func playAudio() {
        DispatchQueue.global().async {
            guard let code = LeapPreferences.shared.getUserLanguage(),
                  let mediaName = self.currentInstruction?[constant_soundName]  as? String else {
                self.startAutoDismissTimer()
                return
            }
            let soundsArrayForLanguage = self.soundManager.discoverySoundsJson[code]  ?? []
            var audio = soundsArrayForLanguage.first { $0.name == mediaName }
            if audio ==  nil {
                let stageSounds = self.soundManager.stageSoundsJson[code] ?? []
                audio = stageSounds.first { $0.name == mediaName }
            }
            guard let currentAudio = audio else {
                self.startAutoDismissTimer()
                return
            }
            if currentAudio.isTTS {
                if let text = currentAudio.text,
                   let ttsCode = self.auiManagerCallBack?.getTTSCodeFor(code: code) {
                    self.tryTTS(text: text, code: ttsCode)
                    return
                }
            }
            let soundPath = LeapSharedAUI.shared.getSoundFilePath(name: currentAudio.filename, code: code)
            let dlStatus = self.mediaManager.getCurrentMediaStatus(currentAudio)
            switch dlStatus {
            case .notDownloaded:
                self.downloadFromMediaManager(forMedia: currentAudio, atPriority: .veryHigh)
                fallthrough
            case .isDownloading:
                self.mediaManager.overrideMediaDownloadCompletion(currentAudio.filename, code: code) { [weak self] (success) in
                    DispatchQueue.main.async { self?.leapButton?.iconState = .rest }
                    guard let newCode = LeapPreferences.shared.getUserLanguage(), newCode == code, success else { return }
                    self?.playAudioFile(filePath: soundPath)
                }
            case .downloaded:
                self.playAudioFile(filePath: soundPath)
            }
        }
    }
    
    func playAudioFile(filePath: URL) {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            self.audioPlayer = try AVAudioPlayer(contentsOf: filePath)
            self.audioPlayer?.delegate = self
            guard let player = self.audioPlayer else { return }
            player.play()
            if player.isPlaying {
               DispatchQueue.main.async {
                  self.leapButton?.iconState = .audioPlay
               }
            }
        } catch let error {
            print(error.localizedDescription)
            startAutoDismissTimer()
        }
    }
    
    func tryTTS(text: String, code: String) {
        utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: code)
        utterance.rate = 0.5
        synthesizer.delegate = self
        synthesizer.speak(utterance)
        DispatchQueue.main.async {
           self.leapButton?.iconState = .audioPlay
        }
    }
    
    func stopAudio() {
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        
        self.synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        
        leapButton?.iconState = .rest
    }
}

// MARK: - DISCOVERY LANGUAGE OPTIONS
extension LeapAUIManager {
    
    func showLanguageOptions(withLocaleCodes localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, Any>, localeHtmlUrl: String?, handler: ((_ success: Bool) -> Void)? = nil) {
        
        func showLanguageOptions() {
            let auiContent = LeapAUIContent(baseUrl: self.baseUrl, location: localeHtmlUrl ?? "")
            if auiContent.url != nil { self.downloadFromMediaManager(forMedia: auiContent, atPriority: .veryHigh, completion: { (success) in
                DispatchQueue.main.async {
                    self.isLanguageOptionsOpen = true
                    self.languageOptions = LeapLanguageOptions(withDict: [:], iconDict: iconInfo, withLanguages: localeCodes, withHtmlUrl: localeHtmlUrl, baseUrl: nil) { success, languageCode in
                        self.removeLanguageOptions()
                        self.isLanguageOptionsOpen = false
                        if success, let code = languageCode { LeapPreferences.shared.setUserLanguage(code) }
                        if let webAssist = self.currentAssist as? LeapWebAssist, let code = LeapPreferences.shared.getUserLanguage() {
                            webAssist.changeLanguage(locale: code)
                        }
                        self.startDiscoverySoundDownload()
                        self.startStageSoundDownload()
                        handler?(success)
                    }
                    self.languageOptions?.showBottomSheet()
                }
            }) }
        }
        
        if localeCodes.count == 1 {
            LeapPreferences.shared.setUserLanguage(localeCodes.first?[constant_localeId] ?? "ang")
            self.startDiscoverySoundDownload()
            self.startStageSoundDownload()
            handler?(true)
            return
        }
        guard let userLanguage = LeapPreferences.shared.getUserLanguage() else {
            showLanguageOptions()
            return
        }
        let localeDict = localeCodes.first { $0[constant_localeId] == userLanguage }
        guard let alreadySelectedLanguageDict = localeDict, let langCode = alreadySelectedLanguageDict[constant_localeId] else {
            showLanguageOptions()
            return
        }
        LeapPreferences.shared.setUserLanguage(langCode)
        self.startDiscoverySoundDownload()
        self.startStageSoundDownload()
        handler?(true)
    }
}

// MARK: - PRESENT AUI COMPONENTS
extension LeapAUIManager {
    
    private func setupDefaultValues(instruction: Dictionary<String,Any>, langCode: String?, view: UIView?, rect: CGRect?, webview: UIView?) {
        if let code = langCode {
            LeapPreferences.shared.setUserLanguage(code)
            self.startDiscoverySoundDownload()
            self.startStageSoundDownload()
        }
        currentInstruction = instruction
        currentTargetView = view
        currentTargetRect = rect
        currentWebView = webview
        self.stopAutoDismissTimer()
    }
    
    private func performInViewNativeInstruction(instruction: Dictionary<String,Any>, inView: UIView, type: String, iconInfo: Dictionary<String,Any>? = nil) {
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any> else { return }
        scrollArrowButton.setView(view: inView)
        //Set autofocus
        inView.becomeFirstResponder()
        
        guard isReadyToPresent(type: type, assistInfo: assistInfo) else {
            auiManagerCallBack?.failedToPerform()
            return
        }
        
        // Present Assist
        switch type {
        case FINGER_RIPPLE:
            let fingerPointer = LeapFingerPointer(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil,baseUrl: nil)
            currentAssist = fingerPointer
            fingerPointer.presentPointer(view: inView)
            
        case TOOLTIP:
            let tooltip = LeapToolTip(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil, baseUrl: baseUrl)
            currentAssist = tooltip
            tooltip.presentPointer()
            
        case HIGHLIGHT_WITH_DESC:
            let highlight = LeapHighlight(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil, baseUrl: baseUrl)
            currentAssist = highlight
            highlight.presentHighlight()
            
        case SPOT:
            let spot = LeapSpot(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil, baseUrl: baseUrl)
            currentAssist = spot
            spot.presentSpot()
            
        case LABEL:
            let label = LeapLabel(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil, baseUrl: baseUrl)
            currentAssist = label
            label.presentLabel()
            
        case BEACON:
            let beacon = LeapBeacon(withDict: assistInfo, toView: inView)
            currentAssist = beacon
            beacon.presentBeacon()
            
        case SWIPE_LEFT, SWIPE_RIGHT, SWIPE_UP, SWIPE_DOWN:
            let swipePointer = LeapSwipePointer(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil, baseUrl: nil)
            guard let swipePointerType = LeapSwipePointerType(rawValue: type) else { return }
            swipePointer.type = swipePointerType
            currentAssist = swipePointer
            swipePointer.presentPointer(view: inView)
        default:
            performKeyWindowInstruction(instruction: instruction, iconInfo: iconInfo)
        }
    }
    
    private func performInViewWebInstruction(instruction: Dictionary<String,Any>, rect: CGRect, inWebview: UIView, type: String, iconInfo: Dictionary<String,Any>? = nil) {
        
        guard  let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any> else { return }
        if let wkweb = inWebview as? WKWebView { scrollArrowButton.setRect(rect, in: wkweb) }
        
        if let webIdentfier = assistInfo[constant_identifier] as? String, let focusScript = auiManagerCallBack?.getWebScript(webIdentfier) {
            //Do auto focus for web element
            if let wkweb = inWebview as? WKWebView { wkweb.evaluateJavaScript(focusScript,completionHandler: nil) }
        }
        
        guard isReadyToPresent(type: type, assistInfo: assistInfo) else {
            auiManagerCallBack?.failedToPerform()
            return
        }
        
        switch type {
        case FINGER_RIPPLE:
            let pointer = LeapFingerPointer(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil, baseUrl: nil)
            currentAssist = pointer
            pointer.presentPointer(toRect: rect, inView: inWebview)
            
        case SWIPE_LEFT, SWIPE_RIGHT, SWIPE_UP, SWIPE_DOWN:
            let swipePointer = LeapSwipePointer(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil, baseUrl: nil)
            guard let swipePointerType = LeapSwipePointerType(rawValue: type) else { return }
            swipePointer.type = swipePointerType
            currentAssist = swipePointer
            swipePointer.presentPointer(toRect: rect, inView: inWebview)
            
        case TOOLTIP:
            let tooltip = LeapToolTip(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil, baseUrl: baseUrl)
            currentAssist = tooltip
            tooltip.presentPointer(toRect: rect, inView: inWebview)
            
        case HIGHLIGHT_WITH_DESC:
            let highlight = LeapHighlight(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil, baseUrl: baseUrl)
            currentAssist = highlight
            highlight.presentHighlight(toRect: rect, inView: inWebview)
            
        case SPOT:
            let spot = LeapSpot(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil, baseUrl: baseUrl)
            currentAssist = spot
            spot.presentSpot(toRect: rect, inView: inWebview)
            
        case LABEL:
            let label = LeapLabel(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil, baseUrl: baseUrl)
            currentAssist = label
            label.presentLabel(toRect: rect, inView: inWebview)
            
        case BEACON:
            let beacon = LeapBeacon(withDict: assistInfo, toView: inWebview)
            currentAssist = beacon
            beacon.presentBeacon(toRect: rect, inView: inWebview)
            
        default:
            performKeyWindowInstruction(instruction: instruction, iconInfo: iconInfo)
        }
    }
    
    private func performKeyWindowInstruction(instruction: Dictionary<String, Any>, iconInfo: Dictionary<String, Any>? = [:]) {
        
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String, Any>, let type = assistInfo[constant_type] as? String, isReadyToPresent(type: type, assistInfo: assistInfo) else {

            auiManagerCallBack?.failedToPerform()
            return
        }
        
            switch type {
            case POPUP:
                let popup = LeapPopup(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = popup
                popup.showPopup()
            case DRAWER:
                let drawer = LeapDrawer(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = drawer
                drawer.showDrawer()
            case FULLSCREEN:
                let fullScreen = LeapFullScreen(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = fullScreen
                fullScreen.showFullScreen()
            case DELIGHT:
                let delight = LeapDelight(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = delight
                delight.showFullScreen()
            case BOTTOMUP:
                let bottomSheet = LeapBottomSheet(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = bottomSheet
                bottomSheet.showBottomSheet()
            case NOTIFICATION:
                let notification = LeapNotification(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = notification
                notification.showNotification()
            case SLIDEIN:
                let slideIn = LeapSlideIn(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = slideIn
                slideIn.showSlideIn()
            case CAROUSEL:
                let carousel = LeapCarousel(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = carousel
                carousel.showCarousel()
                
            case PING:
                self.leapButton?.layoutIfNeeded()
                UIView.animate(withDuration: 0.2) {
                    self.leapButtonBottomConstraint?.constant = mainIconBottomConstant
                    self.leapButton?.layoutIfNeeded()
                }
                dismissLeapButton()
                let ping = LeapPing(withDict: assistInfo, iconDict: iconInfo, baseUrl: nil)
                currentAssist = ping
                ping.showPing()
                
            default:
                break
            }
    }
    
    func isReadyToPresent(type: String, assistInfo: Dictionary<String, Any>) -> Bool {
        switch type {
        case FINGER_RIPPLE, SWIPE_LEFT, SWIPE_RIGHT, SWIPE_UP, SWIPE_DOWN, BEACON:  return true
        default:
            guard let htmlUrl = assistInfo[constant_htmlUrl] as? String else { return false }
            let fileName = htmlUrl.replacingOccurrences(of: "/", with: "$")
            let filePath = LeapSharedAUI.shared.getAUIContentFolderPath().appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: filePath.path) {
                return true
            } else {
                return false
            }
        }
    }
}

// MARK: - AUDIO PLAYER DELEGATES
extension LeapAUIManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.audioPlayer = nil
        leapButton?.iconState = .rest
        startAutoDismissTimer()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.audioPlayer = nil
        leapButton?.iconState = .rest
        startAutoDismissTimer()
    }
}

// MARK: - TTS HANDLING
extension LeapAUIManager: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        leapButton?.iconState = .rest
        startAutoDismissTimer()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        leapButton?.iconState = .rest
        startAutoDismissTimer()
    }
}

// MARK: - ARROW AND KEYBOARD HANDLING
extension LeapAUIManager {
    
    func startAutoDismissTimer() {
        guard !isLanguageOptionsOpen else { return }
        DispatchQueue.main.async {
            guard let instruction = self.currentInstruction else { return }
            let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>
            let timer: Double? = (assistInfo == nil) ? 2000.0 : assistInfo![constant_autoDismissDelay] as? Double
            guard let dismissTimer = timer else { return }
            if self.autoDismissTimer != nil {
                self.stopAutoDismissTimer()
            }
            self.autoDismissTimer = Timer.init(timeInterval: dismissTimer/1000, repeats: false, block: { (timer) in
                self.currentInstruction = nil
                self.dismissLeapButton()
                self.stopAutoDismissTimer()
                guard let assist = self.currentAssist else {
                    self.auiManagerCallBack?.didDismissView(byUser: false, autoDismissed: true, panelOpen: false, action: nil)
                    return
                }
                
                assist.performExitAnimation(animation: self.currentAssist?.assistInfo?.layoutInfo?.exitAnimation ?? "fade_out", byUser: false, autoDismissed: true, byContext: false, panelOpen: false, action: nil)
            })
            guard let autoDismissTimer = self.autoDismissTimer else { return }
            RunLoop.main.add(autoDismissTimer, forMode: .default)
        }
    }
    
    func stopAutoDismissTimer() {
        self.autoDismissTimer?.invalidate()
        self.autoDismissTimer = nil
    }
}

// MARK: - CURRENT ASSIST DELEGATE METHODS
extension LeapAUIManager: LeapAssistDelegate {
    
    func didPresentAssist() {
        playAudio()
        auiManagerCallBack?.didPresentAssist()
    }
    
    func failedToPresentAssist() { auiManagerCallBack?.failedToPerform() }
    
    func didDismissAssist(byContext: Bool, byUser: Bool, autoDismissed: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        self.stopAutoDismissTimer()
        currentAssist = nil
        currentInstruction = nil
        stopAudio()
        scrollArrowButton.noAssist()
        if !byContext { dismissLeapButton() }
        auiManagerCallBack?.didDismissView(byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
    }
    
    func sendAUIEvent(action: Dictionary<String,Any>) {
        auiManagerCallBack?.receiveAUIEvent(action: action)
    }
}

// MARK: - ICON OPTIONS DELEGATE METHODS
extension LeapAUIManager:LeapIconOptionsDelegate {
    
    func stopClicked() {
        removeAllViews()
        currentTargetView = nil
        currentTargetRect = nil
        currentWebView = nil
        auiManagerCallBack?.optionPanelStopClicked()
    }
    
    func languageClicked() {
        guard let localeCodes = auiManagerCallBack?.getLanguagesForCurrentInstruction(),
              let iconInfo = auiManagerCallBack?.getIconInfoForCurrentInstruction(),
              let htmlUrl = auiManagerCallBack?.getLanguageHtmlUrl() else {
            auiManagerCallBack?.optionPanelOpened()
            return
        }
        self.stopAutoDismissTimer()
        self.stopAudio()
        let auiContent = LeapAUIContent(baseUrl: self.baseUrl, location: htmlUrl)
        guard let _ = auiContent.url else { return }
        self.downloadFromMediaManager(forMedia: auiContent, atPriority: .veryHigh) { (success) in
            guard success else { return }
            DispatchQueue.main.async {
                self.isLanguageOptionsOpen = true
                self.languageOptions = LeapLanguageOptions(withDict: [:], iconDict: iconInfo, withLanguages: localeCodes, withHtmlUrl: htmlUrl, baseUrl: nil) { success, languageCode in
                    self.removeLanguageOptions()
                    self.isLanguageOptionsOpen = false
                    if success, let code = languageCode {
                        if let userLanguage = LeapPreferences.shared.getUserLanguage() {
                           self.auiManagerCallBack?.didLanguageChange(from: userLanguage, to: code)
                        }
                        LeapPreferences.shared.setUserLanguage(code)
                    } else { self.startAutoDismissTimer() }
                    if let webAssist = self.currentAssist as? LeapWebAssist, let code = LeapPreferences.shared.getUserLanguage() {
                        webAssist.changeLanguage(locale: code)
                        self.playAudio()
                    }
                    self.startDiscoverySoundDownload()
                    self.startStageSoundDownload()
                    self.auiManagerCallBack?.optionPanelClosed()
                    
                }
                self.languageOptions?.showBottomSheet()
            }
        }
    }
    
    func iconOptionsClosed() {
        auiManagerCallBack?.optionPanelClosed()
    }
    
    func iconOptionsDismissed() {
        leapIconOptions = nil
    }
}


// MARK: - ARROW BUTTON DELEGATES
extension LeapAUIManager:LeapArrowButtonDelegate {
    
    func arrowShown() {
       currentAssist?.hide()
    }
    
    func arrowHidden() {
       currentAssist?.unhide()
    }
}
