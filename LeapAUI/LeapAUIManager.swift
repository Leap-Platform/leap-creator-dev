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
    var currentIconInfo: Dictionary<String, Any>?
    
    private var lastOrientation: UIInterfaceOrientation?
    
    var autoDismissTimer: Timer?
    private var baseUrl = String()
    
    var leapMediaPlayer = LeapMediaPlayer()
        
    let soundManager = LeapSoundManager()
    
    var languageOptions: LeapLanguageOptions?
    
    override init() {
        super.init()
        self.addObservers()
        leapMediaPlayer.delegate = self
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
}

extension LeapAUIManager {

    @objc func keyboardDidShow(_ notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
           leapButton != nil
        {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyboardHeight = Float(keyboardRectangle.height)
            leapButton?.bottomConstraint?.constant = CGFloat(keyboardHeight + 20)
            leapButton?.updateConstraints()
        }
    }
    
    @objc func keyboardDidHide(_ notification: NSNotification) {
        keyboardHeight = 0
        if leapButton != nil {
            leapButton?.bottomConstraint?.constant = mainIconBottomConstant
            leapButton?.updateConstraints()
        }
    }
    
    @objc func appDidBecomeActive() {
        guard currentAssist != nil else { return }
        if !(leapMediaPlayer.currentAudioCompletionStatus ?? true) { playAudio() }
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
            
            if let localeSoundsDict = initialSounds[constant_localeSounds] as? Array<Dictionary<String,Any>> {
                self?.soundManager.stageSoundsJson = self?.soundManager.processSoundConfigs(configs: localeSoundsDict) ?? [:]
                self?.startStageSoundDownload()
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
        setupDefaultValues(instruction:instruction, langCode: localeCode, view: view, rect: nil, webview: nil, iconInfo: nil)
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
        setupDefaultValues(instruction:instruction, langCode: localeCode, view: nil, rect: rect, webview: webview, iconInfo: nil)
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
    
    func performNativeDiscovery(instruction: Dictionary<String, Any>, view: UIView?, localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, AnyHashable>, localeHtmlUrl: String?) {
        setupDefaultValues(instruction: instruction, langCode: nil, view: view, rect: nil, webview: nil, iconInfo: iconInfo)
        if !iconInfo.isEmpty {
            guard isReadyToPresent(type: "", assistInfo: iconInfo) else {
                auiManagerCallBack?.failedToPerform()
                return
            }
        }
        showLanguageOptionsIfApplicable(withLocaleCodes: localeCodes, iconInfo: iconInfo, localeHtmlUrl: localeHtmlUrl) { (languageChose) in
            self.setupDefaultValues(instruction: instruction, langCode: nil, view: view, rect: nil, webview: nil, iconInfo: iconInfo)
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
    
    func performWebDiscovery(instruction: Dictionary<String, Any>, rect: CGRect, webview: UIView?, localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, AnyHashable>, localeHtmlUrl: String?) {
        setupDefaultValues(instruction: instruction, langCode: nil, view: nil, rect: rect, webview: webview, iconInfo: iconInfo)
        if !iconInfo.isEmpty {
            guard isReadyToPresent(type: "", assistInfo: iconInfo) else {
                auiManagerCallBack?.failedToPerform()
                return
            }
        }
        showLanguageOptionsIfApplicable(withLocaleCodes: localeCodes, iconInfo: iconInfo, localeHtmlUrl: localeHtmlUrl) { (languageChose) in
            if languageChose {
                self.setupDefaultValues(instruction: instruction, langCode: nil, view: nil, rect: rect, webview: webview, iconInfo: iconInfo)
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
        setupDefaultValues(instruction:instruction, langCode: nil, view: view, rect: nil, webview: nil, iconInfo: nil)
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
        setupDefaultValues(instruction:instruction, langCode:nil, view: nil, rect: rect, webview: webview, iconInfo: nil)
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
    
    func removeCurrentAssist(byContext: Bool = true, panelOpen: Bool = false) {
        currentAssist?.performExitAnimation(animation: self.currentAssist?.assistInfo?.layoutInfo?.exitAnimation ?? "fade_out", byUser: false, autoDismissed: false, byContext: byContext, panelOpen: panelOpen, action: nil)
        currentAssist = nil
        currentInstruction = nil
        currentTargetView = nil
        currentTargetRect = nil
        currentWebView = nil
        leapMediaPlayer.currentAudioCompletionStatus = nil
    }
    
    func removeLanguageOptions() {
        languageOptions?.removeFromSuperview()
        languageOptions = nil
    }
    
    func presentLeapButton(for iconInfo: Dictionary<String,AnyHashable>, iconEnabled: Bool) {
        guard iconEnabled, leapIconOptions == nil else {
            self.bringLeapIconOnTop()
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
            self.bringLeapIconOnTop()
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
        self.setLeapIconOrientationConstraints()
        leapButton?.htmlUrl = iconSetting.htmlUrl
        leapButton?.iconSize = mainIconSize
        leapButton?.configureIconButton()
    }
    
    @objc func setLeapIconOrientationConstraints() {
        
        guard leapButton != nil else { return }
        
        leapButton?.cornerConstraint?.isActive = false
        leapButton?.bottomConstraint?.isActive = false
        
        guard let keyWindow = UIApplication.shared.keyWindow else { return }
        
        var distance = mainIconCornerConstant
        var cornerAttribute: NSLayoutConstraint.Attribute = .trailing
        if LeapSharedAUI.shared.iconSetting?.leftAlign ?? false {
            cornerAttribute = .leading
            distance = -mainIconCornerConstant
        }
        leapButton?.cornerConstraint = NSLayoutConstraint(item: keyWindow, attribute: cornerAttribute, relatedBy: .equal, toItem: leapButton, attribute: cornerAttribute, multiplier: 1, constant: distance)
        leapButton?.bottomConstraint = NSLayoutConstraint(item: keyWindow, attribute: .bottom, relatedBy: .equal, toItem: leapButton, attribute: .bottom, multiplier: 1, constant: mainIconBottomConstant)
        NSLayoutConstraint.activate([(leapButton?.cornerConstraint)!, (leapButton?.bottomConstraint)!])
                
        if leapIconOptions != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.leapIconOptions?.frame = self.leapButton?.frame ?? CGRect.zero
                self.leapIconOptions?.show()
            }
        }
    }
    
    private func bringLeapIconOnTop() {
        if leapButton != nil {
            let kw = UIApplication.shared.windows.first{ $0.isKeyWindow }
            if let window = kw {
                if leapIconOptions != nil {
                    window.bringSubviewToFront(leapIconOptions!)
                }
                window.bringSubviewToFront(leapButton!)
            }
        }
    }
    
    func appGoesToBackground() {
        leapMediaPlayer.stopAudio()
        leapMediaPlayer.currentAudioCompletionStatus = true
        currentAssist?.remove(byContext: false, byUser: false, autoDismissed: false, panelOpen: true, action: nil, isReinitialize: false)
        languageOptions?.removeFromSuperview()
        leapButton?.removeDisableDialog()
        leapIconOptions?.dismiss(withAnimation: false)
    }
}

// MARK: - HANDLING ICON TAP
extension LeapAUIManager: LeapTappableDelegate {
    
    func iconDidTap() {
        
        if auiManagerCallBack?.isFlowMenu() ?? false {
            auiManagerCallBack?.leapTapped()
            return
        }
        
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
        self.removeCurrentAssistTemporarily()
        guard let _ = autoDismissTimer else { return }
        self.stopAutoDismissTimer()
    }
    
    func shouldDisableAssistance() {
        auiManagerCallBack?.disableAssistance()
        removeAllViews()
    }
    
    func didDismissDisableAssistance() {
        self.showCurrentAssist()
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
            self.leapMediaPlayer.currentAudioCompletionStatus = false
            if currentAudio.isTTS {
                if let text = currentAudio.text,
                   let ttsCode = self.auiManagerCallBack?.getTTSCodeFor(code: code) {
                    self.leapMediaPlayer.tryTTS(text: text, code: ttsCode)
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
                    self?.leapMediaPlayer.playAudio(filePath: soundPath)
                }
            case .downloaded:
                self.leapMediaPlayer.playAudio(filePath: soundPath)
            }
        }
    }
}

// MARK: - DISCOVERY LANGUAGE OPTIONS
extension LeapAUIManager {
    
    func showLanguageOptionsIfApplicable(withLocaleCodes localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, Any>, localeHtmlUrl: String?, handler: ((_ success: Bool) -> Void)?) {
        
        if localeCodes.count == 1 {
            LeapPreferences.shared.setUserLanguage(localeCodes.first?[constant_localeId] ?? "ang")
            self.startDiscoverySoundDownload()
            self.startStageSoundDownload()
            handler?(true)
            return
        }
        guard let userLanguage = LeapPreferences.shared.getUserLanguage() else {
            showLanguageOptions(withLocaleCodes: localeCodes, iconInfo: iconInfo, localeHtmlUrl: localeHtmlUrl) { success in
                handler?(success)
            }
            return
        }
        let localeDict = localeCodes.first { $0[constant_localeId] == userLanguage }
        guard let alreadySelectedLanguageDict = localeDict, let langCode = alreadySelectedLanguageDict[constant_localeId] else {
            showLanguageOptions(withLocaleCodes: localeCodes, iconInfo: iconInfo, localeHtmlUrl: localeHtmlUrl) { success in
                handler?(success)
            }
            return
        }
        LeapPreferences.shared.setUserLanguage(langCode)
        self.startDiscoverySoundDownload()
        self.startStageSoundDownload()
        handler?(true)
    }
    
    func showLanguageOptions(withLocaleCodes localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, Any>, localeHtmlUrl: String?, handler: ((_ success: Bool) -> Void)? = nil) {
        let auiContent = LeapAUIContent(baseUrl: self.baseUrl, location: localeHtmlUrl ?? "")
        if auiContent.url != nil { self.downloadFromMediaManager(forMedia: auiContent, atPriority: .veryHigh, completion: { (success) in
            DispatchQueue.main.async {
                self.dismissLeapButton()
                self.removeCurrentAssistTemporarily()
                self.languageOptions = LeapLanguageOptions(withDict: [:], iconDict: iconInfo, withLanguages: localeCodes, withHtmlUrl: localeHtmlUrl, baseUrl: nil) { [weak self] success, languageCode in
                    self?.removeLanguageOptions()
                    if LeapPreferences.shared.getUserLanguage() != nil {
                        self?.leapButton?.isHidden = false
                        self?.showCurrentAssist()
                    }
                    if success, let code = languageCode {
                        if let userLanguage = LeapPreferences.shared.getUserLanguage() {
                           self?.didLanguageChange(from: userLanguage, to: code)
                        }
                        LeapPreferences.shared.setUserLanguage(code)
                    }
                    if let webAssist = self?.currentAssist as? LeapWebAssist, let code = LeapPreferences.shared.getUserLanguage() {
                        webAssist.changeLanguage(locale: code)
                    }
                    self?.startDiscoverySoundDownload()
                    self?.startStageSoundDownload()
                    handler?(success)
                }
                self.languageOptions?.showBottomSheet()
            }
        }) }
    }
    
    func didLanguageChange(from previousLanguage: String, to currentLanguage: String) {
        if previousLanguage != currentLanguage {
            self.auiManagerCallBack?.didLanguageChange(from: previousLanguage, to: currentLanguage)
            removeCurrentAssist(byContext: false, panelOpen: true)
        }
    }
}

// MARK: - PRESENT AUI COMPONENTS
extension LeapAUIManager {
    
    private func setupDefaultValues(instruction: Dictionary<String,Any>, langCode: String?, view: UIView?, rect: CGRect?, webview: UIView?, iconInfo: Dictionary<String, Any>?) {
        if let code = langCode {
            LeapPreferences.shared.setUserLanguage(code)
            self.startDiscoverySoundDownload()
            self.startStageSoundDownload()
        }
        currentInstruction = instruction
        currentTargetView = view
        currentTargetRect = rect
        currentWebView = webview
        currentIconInfo = iconInfo
        self.stopAutoDismissTimer()
    }
    
    @objc private func orientationDidChange() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            
            guard self.lastOrientation != UIApplication.shared.statusBarOrientation else { return }
            
            self.lastOrientation = UIApplication.shared.statusBarOrientation
            
            self.setLeapIconOrientationConstraints()
            
            if self.languageOptions != nil {
                self.languageOptions?.resetLanguageOptions()
            }
            
            if self.leapButton?.disableDialog.superview != nil {
                self.leapButton?.disableDialog.orientationDidChange()
            }
            
            if self.currentAssist != nil {
                self.removeCurrentAssistTemporarily()
            }
            
            if self.languageOptions == nil && self.leapButton?.disableDialog.superview == nil {
                self.showCurrentAssist()
            }
        }
    }
    
    private func showCurrentAssist() {
        
        if self.currentAssist == nil {
            self.reinitializeCurrentAssist()
        }
        
        self.bringLeapIconOnTop()
    }
    
    private func removeCurrentAssistTemporarily() {
        
        currentAssist?.remove(byContext: true, byUser: false, autoDismissed: false, panelOpen: false, action: [:], isReinitialize: true)
        
        currentAssist = nil
    }
    
    private func reinitializeCurrentAssist() {
        
        guard let instruction = currentInstruction,
              let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String else { return }
        
        guard currentWebView == nil else {
            
            guard let anchorWebview = currentWebView,
                  let rect = currentTargetRect else { return }
            
            performInViewWebInstruction(instruction: instruction, rect: rect, inWebview: anchorWebview, type: type, iconInfo: currentIconInfo)
            return
        }
        
        guard let view = currentTargetView else {
            performKeyWindowInstruction(instruction: instruction, iconInfo: currentIconInfo)
            return
        }
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String else { return }
        performInViewNativeInstruction(instruction: instruction, inView: view, type: type, iconInfo: currentIconInfo)
    }
    
    private func performInViewNativeInstruction(instruction: Dictionary<String,Any>, inView: UIView, type: String, iconInfo: Dictionary<String,Any>? = nil) {
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any> else { return }
        scrollArrowButton.setView(view: inView)
        
        guard isReadyToPresent(type: type, assistInfo: assistInfo) else {
            auiManagerCallBack?.failedToPerform()
            return
        }
        
        // Present Assist
        switch type {
        case FINGER_RIPPLE:
            let fingerPointer = LeapFingerPointer(withDict: assistInfo, toView: inView)
            currentAssist = fingerPointer
            fingerPointer.presentPointer(view: inView)
            
        case TOOLTIP:
            let tooltip = LeapToolTip(withDict: assistInfo, iconDict: iconInfo, toView: inView, baseUrl: baseUrl, projectParametersInfo: auiManagerCallBack?.getProjectParameters())
            currentAssist = tooltip
            tooltip.presentPointer()
            
        case HIGHLIGHT_WITH_DESC:
            let highlight = LeapHighlight(withDict: assistInfo, iconDict: iconInfo, toView: inView, baseUrl: baseUrl)
            currentAssist = highlight
            highlight.presentHighlight()
            
        case SPOT:
            let spot = LeapSpot(withDict: assistInfo, iconDict: iconInfo, toView: inView, baseUrl: baseUrl)
            currentAssist = spot
            spot.presentSpot()
            
        case LABEL:
            let label = LeapLabel(withDict: assistInfo, iconDict: iconInfo, toView: inView, baseUrl: baseUrl)
            currentAssist = label
            label.presentLabel()
            
        case BEACON:
            let beacon = LeapBeacon(withDict: assistInfo, toView: inView)
            currentAssist = beacon
            beacon.presentBeacon()
            
        case SWIPE_LEFT, SWIPE_RIGHT, SWIPE_UP, SWIPE_DOWN:
            let swipePointer = LeapSwipePointer(withDict: assistInfo, toView: inView)
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
            let pointer = LeapFingerPointer(withDict: assistInfo, toView: inWebview)
            currentAssist = pointer
            pointer.presentPointer(toRect: rect, inView: inWebview)
            
        case SWIPE_LEFT, SWIPE_RIGHT, SWIPE_UP, SWIPE_DOWN:
            let swipePointer = LeapSwipePointer(withDict: assistInfo, toView: inWebview)
            guard let swipePointerType = LeapSwipePointerType(rawValue: type) else { return }
            swipePointer.type = swipePointerType
            currentAssist = swipePointer
            swipePointer.presentPointer(toRect: rect, inView: inWebview)
            
        case TOOLTIP:
            let tooltip = LeapToolTip(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, baseUrl: baseUrl, projectParametersInfo: auiManagerCallBack?.getProjectParameters())
            currentAssist = tooltip
            tooltip.presentPointer(toRect: rect, inView: inWebview)
            
        case HIGHLIGHT_WITH_DESC:
            let highlight = LeapHighlight(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, baseUrl: baseUrl)
            currentAssist = highlight
            highlight.presentHighlight(toRect: rect, inView: inWebview)
            
        case SPOT:
            let spot = LeapSpot(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, baseUrl: baseUrl)
            currentAssist = spot
            spot.presentSpot(toRect: rect, inView: inWebview)
            
        case LABEL:
            let label = LeapLabel(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, baseUrl: baseUrl)
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
            let bottomSheet = LeapBottomSheet(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl, flowMenuDict: LeapFlowMenuInfo(with: auiManagerCallBack?.getFlowMenuInfo() ?? [:]).dictionary, flowType: (auiManagerCallBack?.isFlowMenu() ?? false) ? .multiFlow : .singleFlow)
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
                self.leapButton?.bottomConstraint?.constant = mainIconBottomConstant
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
            let filePathToCheck:String = {
                guard filePath.pathExtension == "gz" else { return filePath.path }
                return filePath.deletingPathExtension().appendingPathExtension("html").path
            }()
            if FileManager.default.fileExists(atPath: filePathToCheck ) {
                return true
            } else {
                return false
            }
        }
    }
}

// MARK: - MEDIA PLAYER DELEGATES
extension LeapAUIManager: LeapMediaPlayerDelegate {
    
    func audioDidStartPlaying() {
        self.leapButton?.iconState = .audioPlay
    }
    
    func audioDidStopPlaying() {
        self.leapButton?.iconState = .rest
    }
    
    func audioDidFinishPlaying() {
        leapButton?.iconState = .rest
        startAutoDismissTimer()
    }
    
    func audioDecodeErrorDidOccur() {
        leapButton?.iconState = .rest
        startAutoDismissTimer()
    }
    
    func speechSynthesizerDidFinishUtterance() {
        leapButton?.iconState = .rest
        startAutoDismissTimer()
    }
    
    func speechSynthesizerDidCancelUtterance() {
        leapButton?.iconState = .rest
        startAutoDismissTimer()
    }
}

// MARK: - ARROW AND KEYBOARD HANDLING
extension LeapAUIManager {
    
    func startAutoDismissTimer() {
        guard languageOptions == nil else { return }
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
                self.currentIconInfo = nil
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
        guard  currentAssist == nil else { return }
        auiManagerCallBack?.didDismissView(byUser: false, autoDismissed: false, panelOpen: false, action: nil)
    }
    
    func failedToPresentAssist() { auiManagerCallBack?.failedToPerform() }
    
    func didDismissAssist(byContext: Bool, byUser: Bool, autoDismissed: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        if let type = action?[constant_type] as? String, type == constant_action_taken, let body = action?[constant_body] as? [String : Any], let clickType = body[constant_clickType] as? String, clickType == constant_languageButton {
            guard let localeCodes = auiManagerCallBack?.getLanguagesForCurrentInstruction(),
                  let iconInfo = auiManagerCallBack?.getIconInfoForCurrentInstruction(),
                  let htmlUrl = auiManagerCallBack?.getLanguageHtmlUrl() else {
                return
            }
            showLanguageOptions(withLocaleCodes: localeCodes, iconInfo: iconInfo, localeHtmlUrl: htmlUrl) { success in
                self.performKeyWindowInstruction(instruction: self.currentInstruction ?? [:], iconInfo: iconInfo)
            }
            return
        }
        self.stopAutoDismissTimer()
        currentAssist = nil
        currentInstruction = nil
        leapMediaPlayer.stopAudio()
        leapMediaPlayer.currentAudioCompletionStatus = nil
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
        self.leapMediaPlayer.stopAudio()
        
        self.showLanguageOptions(withLocaleCodes: localeCodes, iconInfo: iconInfo, localeHtmlUrl: htmlUrl) { [weak self] success in
            
            if !success {
                self?.startAutoDismissTimer()
            }
            if let _ = self?.currentAssist as? LeapWebAssist, let _ = LeapPreferences.shared.getUserLanguage() {
                self?.playAudio()
            }
            self?.auiManagerCallBack?.optionPanelClosed()
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
        if leapMediaPlayer.audioPlayer?.isPlaying ?? false {
            leapMediaPlayer.currentAudioCompletionStatus = false
            leapMediaPlayer.stopAudio()
        } else {
            leapMediaPlayer.currentAudioCompletionStatus = true
        }
    }
    
    func arrowHidden() {
       currentAssist?.unhide()
        if !(leapMediaPlayer.currentAudioCompletionStatus ?? true) {
            playAudio()
        }
    }
}
