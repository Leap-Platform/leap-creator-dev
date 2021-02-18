//
//  JinyAUIManager.swift
//  JinyAUI
//
//  Created by Aravind GS on 07/07/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import LeapCore
import AVFoundation
import AdSupport
import WebKit


protocol JinyAUIManagerDelegate: NSObjectProtocol {
    
    func isClientCallbackRequired() -> Bool
    func eventGenerated(event: Dictionary<String,Any>)
}

class JinyAUIManager: NSObject {
    
    weak var auiManagerCallBack: LeapAUICallback?
    weak var delegate: JinyAUIManagerDelegate?
    
    var currentAssist: JinyAssist? { didSet { if let _ = currentAssist { currentAssist?.delegate = self } } }
    
    var keyboardHeight: Float = 0
    var jinyButtonBottomConstraint: NSLayoutConstraint?
    var scrollArrowBottomConstraint: NSLayoutConstraint?
    
    var audioPlayer: AVAudioPlayer?
    var utterance = AVSpeechUtterance()
    let synthesizer = AVSpeechSynthesizer()
    
    var jinyButton: JinyMainButton?
    var mediaManager = JinyMediaManager()
    
    var discoverySoundsJson: Dictionary<String,Array<JinySound>> = [:]
    var stageSoundsJson: Dictionary<String,Array<JinySound>> = [:]
    var scrollArrow: UIButton?
    
    var currentInstruction: Dictionary<String,Any>?
    weak var currentTargetView: UIView?
    var currentTargetRect: CGRect?
    weak var currentWebView: UIView?
    
    var autoDismissTimer: Timer?
    private var baseUrl = String()
    
    func addIdentifier(identifier: String, value: Any) {
        auiManagerCallBack?.triggerEvent(identifier: identifier, value: value)
    }
}

extension JinyAUIManager {
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(authLiveNotification(_:)), name: .init("jiny_auth_live"), object: nil)
    }
    
    @objc func keyboardDidShow(_ notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
           let targetView = currentTargetView, isViewHiddenByKeyboard(targetView)
        {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyboardHeight = Float(keyboardRectangle.height)
            showArrow()
            scrollArrowBottomConstraint?.constant = CGFloat(keyboardHeight + 20)
            scrollArrow?.updateConstraints()
        }
        if jinyButton != nil {
            jinyButtonBottomConstraint?.constant = CGFloat(keyboardHeight + 20)
            jinyButton?.updateConstraints()
        }
    }
    
    @objc func keyboardDidHide(_ notification: NSNotification) {
        keyboardHeight = 0
        guard let assistInfo = currentInstruction?[constant_assistInfo] as? Dictionary<String,Any>, let autoScroll = assistInfo[constant_autoScroll] as? Bool else {
            return
        }
        if autoScroll {
            scrollArrow?.removeFromSuperview()
            scrollArrow = nil
        }
        else if let targetView = currentTargetView {
            if !isViewHiddenByKeyboard(targetView) {
                scrollArrow?.removeFromSuperview()
                scrollArrow = nil
            }
        }
        if jinyButton != nil {
            jinyButtonBottomConstraint?.constant = 20.0
            jinyButton?.updateConstraints()
        }
    }
    
    @objc func authLiveNotification(_ notification:Notification) { shouldDisableAssistance() }
}


// MARK: - AUIHANDLER METHODS
extension JinyAUIManager: LeapAUIHandler {
    
    func startMediaFetch() {
        
        DispatchQueue.main.async { self.jinyButton?.iconState = .loading }
        
        DispatchQueue.global().async {[weak self] in
            
            guard let callback = self?.auiManagerCallBack else { return }
            let initialSounds = callback.getDefaultMedia()
            
            if let discoverySoundsDicts = initialSounds[constant_discoverySounds] as? Array<Dictionary<String,Any>> {
                self?.discoverySoundsJson = self?.processSoundConfigs(configs:discoverySoundsDicts) ?? [:]
                self?.startDiscoverySoundDownload()
            }
            
            var htmlBaseUrl:String?
            if let auiContentDicts = initialSounds[constant_auiContent]  as? Array<Dictionary<String,Any>> {
                for auiContentDict in auiContentDicts {
                    if let baseUrl = auiContentDict[constant_baseUrl] as? String,
                       let contents = auiContentDict[constant_content] as? Array<String> {
                        self?.baseUrl = baseUrl
                        htmlBaseUrl = baseUrl
                        for content in contents {
                            let auiContent = JinyAUIContent(baseUrl: baseUrl, location: content)
                            if let _ = auiContent.url { self?.mediaManager.startDownload(forMedia: auiContent, atPriority: .normal) }
                        }
                    }
                }
            }
            
            if let iconSettingDict = initialSounds[constant_iconSetting] as? Dictionary<String, LeapIconSetting> {
                if let baseUrl = htmlBaseUrl {
                    self?.baseUrl = baseUrl
                    for (_, value) in iconSettingDict {
                        let auiContent = JinyAUIContent(baseUrl: baseUrl, location: value.htmlUrl ?? "")
                        if let _ = auiContent.url { self?.mediaManager.startDownload(forMedia: auiContent, atPriority: .normal) }
                    }
                }
            }
            
            self?.fetchSoundConfig()
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
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String,
              let anchorWebview = webview else { return }
        performInViewWebInstruction(instruction: instruction, rect: rect, inWebview: anchorWebview, type: type,iconInfo:nil)
    }
    
    func performNativeDiscovery(instruction: Dictionary<String, Any>, view: UIView?,  localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, Any>, localeHtmlUrl: String?) {
        setupDefaultValues(instruction: instruction, langCode: nil, view: view, rect: nil, webview: nil)
        showLanguageOptions(withLocaleCodes: localeCodes, iconInfo: iconInfo, localeHtmlUrl: localeHtmlUrl) { (languageChose) in
            self.setupDefaultValues(instruction: instruction, langCode: nil, view: view, rect: nil, webview: nil)
            if languageChose {
                guard let anchorView = view else {
                    self.performKeyWindowInstruction(instruction: instruction, iconInfo: iconInfo)
                    return
                }
                guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
                      let type = assistInfo[constant_type] as? String else { return }
                self.performInViewNativeInstruction(instruction: instruction, inView: anchorView, type: type)
                self.dismissJinyButton()
            }
            else { self.presentLeapButton(for: LeapIconSetting(with: iconInfo), iconEnabled: true) }
        }
    }
    
    func performWebDiscovery(instruction: Dictionary<String, Any>, rect: CGRect, webview: UIView?,  localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, Any>, localeHtmlUrl: String?) {
        setupDefaultValues(instruction: instruction, langCode: nil, view: nil, rect: rect, webview: webview)
        showLanguageOptions(withLocaleCodes: localeCodes, iconInfo: iconInfo, localeHtmlUrl: localeHtmlUrl) { (languageChose) in
            if languageChose {
                self.setupDefaultValues(instruction: instruction, langCode: nil, view: nil, rect: rect, webview: webview)
                guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
                      let type = assistInfo[constant_type] as? String,
                      let anchorWebview = webview else { return }
                self.dismissJinyButton()
                self.performInViewWebInstruction(instruction: instruction, rect: rect, inWebview: anchorWebview, type: type,iconInfo:nil)
            }
            else { self.presentLeapButton(for: LeapIconSetting(with: iconInfo), iconEnabled: true) }
        }
    }
    
    func performNativeStage(instruction: Dictionary<String, Any>, view: UIView?, iconInfo: Dictionary<String, Any>) {
        setupDefaultValues(instruction:instruction, langCode: nil, view: view, rect: nil, webview: nil)
        guard let view = currentTargetView else {
            performKeyWindowInstruction(instruction: instruction, iconInfo: nil)
            return
        }
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String else { return }
        performInViewNativeInstruction(instruction: instruction, inView: view, type: type)
        presentLeapButton(for: LeapIconSetting(with: iconInfo), iconEnabled: true)
    }
    
    func performWebStage(instruction: Dictionary<String, Any>, rect: CGRect, webview: UIView?, iconInfo: Dictionary<String, Any>) {
        setupDefaultValues(instruction:instruction, langCode:nil, view: nil, rect: rect, webview: webview)
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String else { return }
        guard let anchorWebview = webview else { return }
        performInViewWebInstruction(instruction: instruction, rect: rect, inWebview: anchorWebview, type: type,iconInfo:nil)
        presentLeapButton(for: LeapIconSetting(with: iconInfo), iconEnabled: true)
    }
    
    func updateRect(rect: CGRect, inWebView: UIView?) {
        
        if let swipePointer = currentAssist as? JinySwipePointer { swipePointer.updateRect(newRect: rect, inView: inWebView) }
        else if let fingerPointer = currentAssist as? JinyFingerRipplePointer { fingerPointer.updateRect(newRect: rect, inView: inWebView) }
        else if let label = currentAssist as? JinyLabel { label.updateRect(newRect: rect, inView: inWebView) }
        else if let tooltip = currentAssist as? JinyToolTip { tooltip.updatePointer(toRect: rect, inView: inWebView) }
        else if let highlight = currentAssist as? JinyHighlight { highlight.updateHighlight(toRect: rect, inView: inWebView) }
        else if let spot = currentAssist as? JinySpot { spot.updateSpot(toRect: rect, inView: inWebView) }
        else if let beacon = currentAssist as? JinyBeacon { beacon.updateRect(newRect: rect, inView: inWebView) }
        guard let webview = inWebView else { return }
        if isRectInVisbleArea(rect: rect, inView: webview) {
            if isRectHiddenByKeyboard(rect: rect, webview: webview){ if scrollArrow ==  nil { showArrow() } }
            else {
                scrollArrow?.removeFromSuperview()
                scrollArrow = nil
            }
        } else { if scrollArrow ==  nil { showArrow() } }
    }
    
    func updateView(inView view: UIView) {
        
        if let swipePointer = currentAssist as? JinySwipePointer { swipePointer.setPosition() }
        else if let fingerPointer = currentAssist as? JinyFingerRipplePointer { fingerPointer.setPosition() }
        else if let label = currentAssist as? JinyLabel { label.setAlignment() }
        else if let tooltip = currentAssist as? JinyToolTip { tooltip.updatePointer() }
        else if let highlight = currentAssist as? JinyHighlight { highlight.updateHighlight() }
        else if let spot = currentAssist as? JinySpot { spot.updateSpot() }
        else if let beacon = currentAssist as? JinyBeacon { beacon.setAlignment() }
        
        if isViewInVisibleArea(view: view) {
            if isViewHiddenByKeyboard(view){ if scrollArrow ==  nil { showArrow() } }
            else {
                scrollArrow?.removeFromSuperview()
                scrollArrow = nil
            }
        } else { if scrollArrow ==  nil { showArrow() } }
    }
    
    func dismissJinyButton() {
        jinyButton?.isHidden = true
    }
    
    func removeAllViews() {
        currentAssist?.remove(byContext: true, byUser: false, autoDismissed: false, panelOpen: false, action: nil)
        currentAssist = nil
        currentInstruction = nil
        currentTargetView = nil
        currentTargetRect = nil
        currentWebView = nil
        dismissJinyButton()
    }
    
    func presentLeapButton(for iconSetting: LeapIconSetting, iconEnabled: Bool) {
        guard jinyButton == nil, jinyButton?.window == nil, iconEnabled else {
            JinySharedAUI.shared.iconHtml = iconSetting.htmlUrl
            JinySharedAUI.shared.iconColor = iconSetting.bgColor ?? "#000000"
            jinyButton?.isHidden = false
            let kw = UIApplication.shared.windows.first{ $0.isKeyWindow}
            if let keyWindow = kw { keyWindow.bringSubviewToFront(jinyButton!) }
            return
        }
        JinySharedAUI.shared.iconHtml = iconSetting.htmlUrl
        JinySharedAUI.shared.iconColor = iconSetting.bgColor ?? "#000000"
        jinyButton = JinyMainButton(withThemeColor: UIColor.init(hex: iconSetting.bgColor ?? "#000000") ?? .black, dismissible: iconSetting.dismissible ?? false)
        guard let keyWindow = UIApplication.shared.keyWindow else { return }
        keyWindow.addSubview(jinyButton!)
        jinyButton!.tapGestureRecognizer.addTarget(self, action: #selector(jinyButtonTap))
        jinyButton!.tapGestureRecognizer.delegate = self
        jinyButton!.stateDelegate = self
        jinyButtonBottomConstraint = NSLayoutConstraint(item: keyWindow, attribute: .bottom, relatedBy: .equal, toItem: jinyButton, attribute: .bottom, multiplier: 1, constant: mainIconConstraintConstant)
        jinyButton?.bottomConstraint = jinyButtonBottomConstraint!
        jinyButton?.disableDialog.delegate = self
        var distance = mainIconConstraintConstant
        var cornerAttribute: NSLayoutConstraint.Attribute = .trailing
        if iconSetting.leftAlign ?? false {
            cornerAttribute = .leading
            distance = -mainIconConstraintConstant
        }
        let cornerConstraint = NSLayoutConstraint(item: keyWindow, attribute: cornerAttribute, relatedBy: .equal, toItem: jinyButton, attribute: cornerAttribute, multiplier: 1, constant: distance)
        NSLayoutConstraint.activate([jinyButtonBottomConstraint!, cornerConstraint])
        jinyButton!.htmlUrl = iconSetting.htmlUrl
        jinyButton!.iconSize = mainIconSize
        jinyButton?.configureIconButton()
    }
}


// MARK: - ICON TAP AND GESTURE HANDLING
extension JinyAUIManager: UIGestureRecognizerDelegate {
    
    @objc func jinyButtonTap() {
        
        guard let _ = currentAssist else {
            auiManagerCallBack?.leapTapped()
            return
        }
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        currentAssist?.remove(byContext: false, byUser: false, autoDismissed: false, panelOpen: true, action: nil)
        auiManagerCallBack?.optionPanelOpened()
        guard let button = jinyButton else { return }
        guard let optionsText = auiManagerCallBack?.getCurrentLanguageOptionsTexts() else { return }
        let stopText = optionsText[constant_stop] ?? "Stop"
        let languageText = optionsText[constant_language] ?? "Language"
        let jinyIconOptions = JinyIconOptions(withDelegate: self, stopText: stopText, languageText: languageText, jinyButton: button)
        jinyIconOptions.show()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


// MARK: - JINY MAIN BUTTON STATE HANDLING
extension JinyAUIManager: JinyIconStateDelegate {
    func iconDidChange(state: JinyIconState) {
        switch state {
        case .rest:
            DispatchQueue.main.async {
                self.jinyButton?.changeToRest()
            }
        case .loading:
            DispatchQueue.main.async {
                self.jinyButton?.changeToLoading()
            }
        case .audioPlay:
            DispatchQueue.main.async {
                self.jinyButton?.changeToAudioPlay()
            }
        }
    }
}

// MARK: - DISABLE ASSISTANCE DELEGATE METHODS
extension JinyAUIManager: JinyDisableAssistanceDelegate {
    func shouldDisableAssistance() {
        auiManagerCallBack?.disableAssistance()
        removeAllViews()
    }
}

// MARK: - MEDIA FETCH AND HANDLING
extension JinyAUIManager {
    
    func processSoundConfigs(configs: Array<Dictionary<String,Any>>) -> Dictionary<String, Array<JinySound>> {
        var processedSoundsDict: Dictionary<String,Array<JinySound>> = [:]
        for config in configs {
            let singleConfigProcessed = processSingleConfig(config: config)
            singleConfigProcessed.forEach { (code, jinySoundsArray) in
                let soundsForEachCode = (processedSoundsDict[code] ?? []) + jinySoundsArray
                processedSoundsDict[code] = soundsForEachCode
            }
        }
        return processedSoundsDict
    }
    
    private func processSingleConfig(config: Dictionary<String,Any>) -> Dictionary<String, Array<JinySound>> {
        var processedSounds: Dictionary<String,Array<JinySound>> = [:]
        guard let baseUrl = config[constant_baseUrl] as? String,
              let jinySounds = config[constant_leapSounds] as? Dictionary<String,Array<Dictionary<String,Any>>> else { return processedSounds }
        jinySounds.forEach { (code, soundDictsArray) in
            let processedSoundsArray = self.processJinySounds(soundDictsArray, code: code, baseUrl: baseUrl)
            let currentCodeSounds =  (processedSounds[code] ?? []) + processedSoundsArray
            processedSounds[code] = currentCodeSounds
        }
        return processedSounds
        
    }
    
    private func processJinySounds(_ sounds: Array<Dictionary<String,Any>>, code: String, baseUrl: String) -> Array<JinySound> {
        return sounds.map { (singleSoundDict) -> JinySound? in
            let url = singleSoundDict[constant_url] as? String
            return JinySound(baseUrl: baseUrl, location: url, code: code, info: singleSoundDict)
        }.compactMap { return $0 }
    }
    
    func startDiscoverySoundDownload() {
        let code = auiManagerCallBack!.getLanguageCode()
        let discoverySoundsForCode = discoverySoundsJson[code] ?? []
        for sound in discoverySoundsForCode { if sound.url != nil { mediaManager.startDownload(forMedia: sound, atPriority: .normal) } }
    }
    
    func fetchSoundConfig() {
        let url = URL(string: "https://odin-dev-gke.leap.is/odin/api/v1/sounds")
        var req = URLRequest(url: url!)
        guard let token = LeapPreferences.shared.apiKey else { fatalError("No API Key") }
        req.addValue(token, forHTTPHeaderField: "x-jiny-client-id")
        req.addValue(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String, forHTTPHeaderField: "x-app-version-name")
        req.addValue(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String, forHTTPHeaderField: "x-app-version-code")
        let session = URLSession.shared
        let configTask = session.dataTask(with: req) {[weak self] (data, response, error) in
            guard let resultData = data else { return }
            guard let audioDict = try? JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,Any>
            else { return }
            guard let soundConfigs = audioDict[constant_data] as? Array<Dictionary<String,Any>> else { return }
            self?.stageSoundsJson = self?.processSoundConfigs(configs: soundConfigs) ?? [:]
            self?.startStageSoundDownload()
        }
        configTask.resume()
    }
    
    func startStageSoundDownload() {
        let code = auiManagerCallBack!.getLanguageCode()
        let stageSoundsForCode = stageSoundsJson[code] ?? []
        for sound in stageSoundsForCode { if sound.url != nil { mediaManager.startDownload(forMedia: sound, atPriority: .low) } }
    }
    
    func playAudio() {
        DispatchQueue.global().async {
            guard let code = LeapPreferences.shared.currentLanguage,
                  let mediaName = self.currentInstruction?[constant_soundName]  as? String else {
                self.startAutoDismissTimer()
                return
            }
            let soundsArrayForLanguage = self.discoverySoundsJson[code]  ?? []
            var audio = soundsArrayForLanguage.first { $0.name == mediaName }
            if audio ==  nil {
                let stageSounds = self.stageSoundsJson[code] ?? []
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
            let soundPath = JinySharedAUI.shared.getSoundFilePath(name: mediaName, code: code, format: currentAudio.format)
            let dlStatus = self.mediaManager.getCurrentMediaStatus(currentAudio)
            switch dlStatus {
            case .notDownloaded:
                self.mediaManager.updatePriority(mediaName: mediaName, langCode: code, toPriority: .veryHigh)
                fallthrough
            case .isDownloading:
                self.mediaManager.overrideMediaDownloadCompletion(mediaName, code: code) { [weak self] (success) in
                    guard let instruction = self?.currentInstruction,
                          let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
                          let currentMediaName = assistInfo[constant_soundName] as? String, mediaName == currentMediaName,
                          let newCode = LeapPreferences.shared.currentLanguage, newCode == code, success else { return }
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
                  self.jinyButton?.iconState = .audioPlay
               }
            }
        } catch  { }
    }
    
    func tryTTS(text: String, code: String) {
        utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: code)
        utterance.rate = 0.5
        synthesizer.delegate = self
        synthesizer.speak(utterance)
        if synthesizer.isSpeaking {
           DispatchQueue.main.async {
              self.jinyButton?.iconState = .audioPlay
           }
        }
    }
}

// MARK: - DISCOVERY LANGUAGE OPTIONS
extension JinyAUIManager {
    
    func showLanguageOptions(withLocaleCodes localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, Any>, localeHtmlUrl: String?, handler: ((_ success: Bool) -> Void)? = nil) {
        
        func showLanguageOptions() {
            let auiContent = JinyAUIContent(baseUrl: self.baseUrl, location: localeHtmlUrl ?? "")
            if auiContent.url != nil { self.mediaManager.startDownload(forMedia: auiContent, atPriority: .veryHigh, completion: { (success) in
                DispatchQueue.main.async {
                    let jinyLanguageOptions = JinyLanguageOptions(withDict: [:], iconDict: iconInfo, withLanguages: localeCodes, withHtmlUrl: localeHtmlUrl) { success, languageCode in
                        if success, let code = languageCode { LeapPreferences.shared.setUserLanguage(code) }
                        LeapPreferences.shared.currentLanguage = languageCode
                        self.startDiscoverySoundDownload()
                        self.startStageSoundDownload()
                        handler?(success)
                    }
                    jinyLanguageOptions.showBottomSheet()
                }
            }) }
        }
        
        if localeCodes.count == 1 {
            LeapPreferences.shared.currentLanguage = localeCodes.first?[constant_localeId]
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
        LeapPreferences.shared.currentLanguage = langCode
        self.startDiscoverySoundDownload()
        self.startStageSoundDownload()
        handler?(true)
    }
}

// MARK: - PRESENT AUI COMPONENTS
extension JinyAUIManager {
    
    private func setupDefaultValues(instruction: Dictionary<String,Any>, langCode: String?, view: UIView?, rect: CGRect?, webview: UIView?) {
        if let code = langCode {
            LeapPreferences.shared.currentLanguage = code
            self.startDiscoverySoundDownload()
            self.startStageSoundDownload()
        }
        currentInstruction = instruction
        currentTargetView = view
        currentTargetRect = rect
        currentWebView = webview
    }
    
    private func performInViewNativeInstruction(instruction: Dictionary<String,Any>, inView: UIView, type: String, iconInfo: Dictionary<String,Any>? = nil) {
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any> else { return }
        
        // Autoscroll
        arrowClicked()
        
        //Set autofocus
        inView.becomeFirstResponder()
        
        // Present Assist
        switch type {
        case FINGER_RIPPLE:
            let fingerPointer = JinyFingerRipplePointer(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
            currentAssist = fingerPointer
            fingerPointer.presentPointer(view: inView)
            
        case TOOLTIP:
            let tooltip = JinyToolTip(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
            currentAssist = tooltip
            tooltip.presentPointer()
            
        case HIGHLIGHT_WITH_DESC:
            let highlight = JinyHighlight(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
            currentAssist = highlight
            highlight.presentHighlight()
            
        case SPOT:
            let spot = JinySpot(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
            currentAssist = spot
            spot.presentSpot()
            
        case LABEL:
            let label = JinyLabel(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
            currentAssist = label
            label.presentLabel()
            
        case BEACON:
            let beacon = JinyBeacon(withDict: assistInfo, toView: inView)
            currentAssist = beacon
            beacon.presentBeacon()
            
        case SWIPE_LEFT, SWIPE_RIGHT, SWIPE_UP, SWIPE_DOWN:
            let swipePointer = JinySwipePointer(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
            swipePointer.type = JinySwipePointerType(rawValue: type)!
            currentAssist = swipePointer
            swipePointer.presentPointer(view: inView)
        default:
            performKeyWindowInstruction(instruction: instruction, iconInfo: iconInfo)
        }
    }
    
    private func performInViewWebInstruction(instruction: Dictionary<String,Any>, rect: CGRect, inWebview: UIView, type: String, iconInfo: Dictionary<String,Any>? = nil) {
        
        guard  let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any> else { return }
        
        arrowClicked()
        
        if let webIdentfier = assistInfo[constant_identifier] as? String, let focusScript = auiManagerCallBack?.getWebScript(webIdentfier) {
            //Do auto focus for web element
            if let wkweb = inWebview as? WKWebView { wkweb.evaluateJavaScript(focusScript,completionHandler: nil) }
        }
        
        switch type {
        case FINGER_RIPPLE:
            let pointer = JinyFingerRipplePointer(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil)
            currentAssist = pointer
            pointer.presentPointer(toRect: rect, inView: inWebview)
            
        case SWIPE_LEFT, SWIPE_RIGHT, SWIPE_UP, SWIPE_DOWN:
            let swipePointer = JinySwipePointer(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil)
            swipePointer.type = JinySwipePointerType(rawValue: type)!
            currentAssist = swipePointer
            swipePointer.presentPointer(toRect: rect, inView: inWebview)
            
        case TOOLTIP:
            let tooltip = JinyToolTip(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil)
            currentAssist = tooltip
            tooltip.presentPointer(toRect: rect, inView: inWebview)
            
        case HIGHLIGHT_WITH_DESC:
            let highlight = JinyHighlight(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil)
            currentAssist = highlight
            highlight.presentHighlight(toRect: rect, inView: inWebview)
            
        case SPOT:
            let spot = JinySpot(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil)
            currentAssist = spot
            spot.presentSpot(toRect: rect, inView: inWebview)
            
        case LABEL:
            let label = JinyLabel(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil)
            currentAssist = label
            label.presentLabel(toRect: rect, inView: inWebview)
            
        case BEACON:
            let beacon = JinyBeacon(withDict: assistInfo, toView: inWebview)
            currentAssist = beacon
            beacon.presentBeacon(toRect: rect, inView: inWebview)
            
        default:
            performKeyWindowInstruction(instruction: instruction, iconInfo: iconInfo)
        }
    }
    
    private func performKeyWindowInstruction(instruction: Dictionary<String, Any>, iconInfo: Dictionary<String, Any>? = [:]) {
        
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any> else {
            auiManagerCallBack?.failedToPerform()
            return
        }
        
        if let type = assistInfo[constant_type] as? String {
            switch type {
            case POPUP:
                let jinyPopup = JinyPopup(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyPopup
                jinyPopup.showPopup()
            case DRAWER:
                let jinyDrawer = JinyDrawer(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyDrawer
                jinyDrawer.showDrawer()
            case FULLSCREEN:
                let jinyFullScreen = JinyFullScreen(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyFullScreen
                jinyFullScreen.showFullScreen()
            case BOTTOMUP:
                let jinyBottomSheet = JinyBottomSheet(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyBottomSheet
                jinyBottomSheet.showBottomSheet()
            case NOTIFICATION:
                let jinyNotification = JinyNotification(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyNotification
                jinyNotification.showNotification()
            case SLIDEIN:
                let jinySlideIn = JinySlideIn(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinySlideIn
                jinySlideIn.showSlideIn()
            case CAROUSEL:
                let jinyCarousel = JinyCarousel(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyCarousel
                jinyCarousel.showCarousel()
                
            case PING:
                self.jinyButton?.layoutIfNeeded()
                UIView.animate(withDuration: 0.2) {
                    self.jinyButtonBottomConstraint?.constant = mainIconConstraintConstant
                    self.jinyButton?.layoutIfNeeded()
                }
                dismissJinyButton()
                let jinyPing = JinyPing(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyPing
                jinyPing.showPing()
                
            default:
                break
            }
        }
    }
}

// MARK: - AUDIO PLAYER DELEGATES
extension JinyAUIManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        jinyButton?.iconState = .rest
        startAutoDismissTimer()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        jinyButton?.iconState = .rest
        startAutoDismissTimer()
    }
}

// MARK: - TTS HANDLING
extension JinyAUIManager: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        jinyButton?.iconState = .rest
        startAutoDismissTimer()
    }
}

// MARK: - ARROW AND KEYBOARD HANDLING
extension JinyAUIManager {
    
    func isViewInVisibleArea(view: UIView) -> Bool {
        let viewFrame = view.frame
        let windowFrame = UIApplication.shared.keyWindow?.frame
        let viewFrameWRTToWindowFrame = view.superview!.convert(viewFrame, to: nil)
        return windowFrame!.contains(viewFrameWRTToWindowFrame)
    }
    
    func isRectInVisbleArea(rect: CGRect, inView: UIView) -> Bool {
        return inView.frame.contains(rect)
    }
    
    func isViewHiddenByKeyboard(_ view: UIView) -> Bool {
        guard keyboardHeight > 0 else { return false }
        let viewWRTWindow = view.superview!.convert(view.frame, to: nil)
        return viewWRTWindow.origin.y > (UIApplication.shared.keyWindow!.frame.height - CGFloat(keyboardHeight))
    }
    
    func isRectHiddenByKeyboard(rect:CGRect, webview:UIView) -> Bool {
        guard keyboardHeight > 0 else { return false }
        let viewWRTWindow = webview.superview!.convert(rect, to: nil)
        return viewWRTWindow.origin.y > (UIApplication.shared.keyWindow!.frame.height - CGFloat(keyboardHeight))
    }
    
    func getScrollViews(_ forView: UIView) -> Array<UIView> {
        var scrollViews:Array<UIView> = [forView]
        guard var tempView = forView.superview else { return scrollViews }
        while !tempView.isKind(of: UIWindow.self) {
            if let scrollView = tempView as? UIScrollView { scrollViews.append(scrollView) }
            tempView = tempView.superview!
        }
        return scrollViews
    }
    
    func makeViewVisible(_ nestedScrolls: Array<UIView>,_ animated: Bool) {
        for i in 0..<nestedScrolls.count-1 {
            let parentView = nestedScrolls[nestedScrolls.count - 1 - i]
            let childView = nestedScrolls[nestedScrolls.count - 1 - i - 1]
            if let scroller = parentView as? UIScrollView {
                let childViewRectWRTParent = childView.superview!.convert(childView.frame, to: scroller)
                scroller.scrollRectToVisible(childViewRectWRTParent, animated: animated)
            }
        }
    }
    
    func showArrow() {
        if scrollArrow != nil {
            scrollArrow?.removeFromSuperview()
            scrollArrow = nil
        }
        scrollArrow = UIButton(frame: .zero)
        scrollArrow?.backgroundColor = UIColor.green
        scrollArrow?.layer.cornerRadius = 20
        scrollArrow?.layer.masksToBounds = true
        scrollArrow?.setTitle("↓", for: .normal)
        scrollArrow?.addTarget(self, action: #selector(arrowClicked), for: .touchUpInside)
        let currentVC = UIApplication.getCurrentVC()
        let superView = currentVC!.view
        superView!.addSubview(scrollArrow!)
        scrollArrow?.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConstraint = NSLayoutConstraint(item: scrollArrow!, attribute: .leading, relatedBy: .equal, toItem: superView!, attribute: .leading, multiplier: 1, constant: 20)
        scrollArrowBottomConstraint = NSLayoutConstraint(item: superView!, attribute: .bottom, relatedBy: .equal, toItem: scrollArrow!, attribute: .bottom, multiplier: 1, constant: 20)
        let heightConstraint = NSLayoutConstraint(item: scrollArrow!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 40)
        let widthConstraint = NSLayoutConstraint(item: scrollArrow!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 40)
        NSLayoutConstraint.activate([leadingConstraint, scrollArrowBottomConstraint!, heightConstraint, widthConstraint])
    }
    
    @objc func arrowClicked() {
        guard let assistInfo = currentInstruction?[constant_assistInfo] as? Dictionary<String,Any> else { return }
        let isWeb = assistInfo[constant_isWeb] as? Bool ?? false
        if isWeb {
            guard let webview = currentWebView, let rect = currentTargetRect else { return }
            if let wkweb = webview as? WKWebView {
                wkweb.scrollView.scrollRectToVisible(rect, animated: true)
            }
        } else {
            let nestedScrolls = getScrollViews(currentTargetView!)
            makeViewVisible(nestedScrolls, true)
            let currentVc = UIApplication.getCurrentVC()
            let view = currentVc!.view!
            view.endEditing(true)
        }
        scrollArrow?.removeFromSuperview()
        scrollArrow = nil
    }
    
    func startAutoDismissTimer() {
        guard let instruction = currentAssist, let dismissTimer = instruction.assistInfo?.autoDismissDelay, dismissTimer > 0 else { return }
        if autoDismissTimer != nil {
            autoDismissTimer?.invalidate()
            autoDismissTimer = nil
        }
        autoDismissTimer = Timer.init(timeInterval: dismissTimer/1000, repeats: false, block: { (timer) in
            self.currentAssist?.remove(byContext: false, byUser: false, autoDismissed: true, panelOpen: false, action: nil)
            self.currentAssist = nil
            self.dismissJinyButton()
            self.autoDismissTimer?.invalidate()
            self.autoDismissTimer = nil
        })
        RunLoop.main.add(autoDismissTimer!, forMode: .default)
    }
}

// MARK: - CURRENT ASSIST DELEGATE METHODS
extension JinyAUIManager: JinyAssistDelegate {
    
    func didPresentAssist() {
        playAudio()
        auiManagerCallBack?.didPresentView()
    }
    
    func failedToPresentAssist() { auiManagerCallBack?.failedToPerform() }
    
    func didDismissAssist(byContext: Bool, byUser: Bool, autoDismissed: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        currentAssist = nil
        dismissJinyButton()
        auiManagerCallBack?.didDismissView(byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
    }    
}

// MARK: - ICON OPTIONS DELEGATE METHODS
extension JinyAUIManager:JinyIconOptionsDelegate {
    
    func stopClicked() {
        removeAllViews()
        currentInstruction = nil
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
        let jinyLanguageOptions = JinyLanguageOptions(withDict: [:], iconDict: iconInfo, withLanguages: localeCodes, withHtmlUrl: htmlUrl) { success, languageCode in
            if success, let code = languageCode { LeapPreferences.shared.setUserLanguage(code) }
            LeapPreferences.shared.currentLanguage = languageCode
            self.startDiscoverySoundDownload()
            self.startStageSoundDownload()
            self.auiManagerCallBack?.optionPanelClosed()
            
        }
        jinyLanguageOptions.showBottomSheet()
        
    }
    
    func iconOptionsDismissed() {
        auiManagerCallBack?.optionPanelClosed()
    }
}
